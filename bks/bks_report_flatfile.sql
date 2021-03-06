/***************************************************************************************
Name      : Medicine Financial System - bks_report_flatfile
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Provides a flat file report of Bookstore transactions
****************************************************************************************
PREREQUISITES:
- bks Schema Creation & Update
- ga Schema Creation & Update
- qlink_db Schema Creation & Update
- coa_db Schema Creation & Update
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE dw_db;
GO

/*  Specify ISO compliant behavior of the Equals (=) and Not Equal To (<>) comparison
    operators when they are used with null values.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-nulls-transact-sql
    -   When SET ANSI_NULLS is ON, a SELECT statement that uses WHERE column_name = NULL 
        returns zero rows even if there are null values in column_name. A SELECT 
        statement that uses WHERE column_name <> NULL returns zero rows even if there 
        are nonnull values in column_name. 
    -   When SET ANSI_NULLS is OFF, the Equals (=) and Not Equal To (<>) comparison 
        operators do not follow the ISO standard. A SELECT statement that uses WHERE 
        column_name = NULL returns the rows that have null values in column_name. A 
        SELECT statement that uses WHERE column_name <> NULL returns the rows that 
        have nonnull values in the column. Also, a SELECT statement that uses WHERE 
        column_name <> XYZ_value returns all rows that are not XYZ_value and that are 
        not NULL. */
SET ANSI_NULLS ON;
GO

/*  Causes SQL Server to follow  ISO rules regarding quotation mark identifiers &
    literal strings.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql
    -   When SET QUOTED_IDENTIFIER is ON, identifiers can be delimited by double 
        quotation marks, and literals must be delimited by single quotation marks. When 
        SET QUOTED_IDENTIFIER is OFF, identifiers cannot be quoted and must follow all 
        Transact-SQL rules for identifiers. */
SET QUOTED_IDENTIFIER ON;
GO

/*  CREATE SCHEMA IF REQUIRED *********************************************************/
PRINT '** Create Schema if Non-Existent';
GO
IF SCHEMA_ID('bks') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA bks');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'QueryLink Queries', 
            @level0type=N'SCHEMA',
            @level0name=N'bks';
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH
GO

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('bks.report_flatfile','P') IS NOT NULL DROP PROCEDURE bks.report_flatfile;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    bks.report_flatfile
                    (
                        @selectFullAccountingPeriod INT = 0,
                        @pullDataPeriods VARCHAR(5) = 'FYTD',
                        @orghierLevel4 CHAR(6) = '',
                        @teamID INT = 0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE     @SQL AS VARCHAR(MAX);
                            DECLARE     @startingFiscalPeriod AS INT;
                            DECLARE     @endingFiscalPeriod AS INT;
                            DECLARE     @startingFiscalPeriodTXT AS CHAR(6);
                            DECLARE     @endingFiscalPeriodTXT AS CHAR(6);

                            IF @selectFullAccountingPeriod = 0 SET @selectFullAccountingPeriod = CAST(FORMAT(DATEADD(month,6-1,GETDATE()),'yyyyMM') AS INT);
                            SET @endingFiscalPeriod = @selectFullAccountingPeriod;
                            
                            IF @pullDataPeriods = 'MTD' SET @startingFiscalPeriod = @selectFullAccountingPeriod;
                            ELSE IF @pullDataPeriods = 'FYTD' SET @startingFiscalPeriod = CAST(SUBSTRING(CAST(CAST(SUBSTRING(CAST(@selectFullAccountingPeriod-1 AS CHAR(6)),1,4) AS INT)-1 AS CHAR(6)),1,4) + '14' AS INT);
                            ELSE IF @pullDataPeriods = '12MTD' SET @startingFiscalPeriod = CAST(FORMAT(DATEADD(month,-12+1,CAST(CAST(@selectFullAccountingPeriod AS VARCHAR(8)) + '01' AS DATETIME2)),'yyyyMM') AS INT);
                            ELSE SELECT @startingFiscalPeriod = MIN(d.full_accounting_period) FROM ga.f_ledger_activity AS d;

                            SET @startingFiscalPeriodTXT = CAST(@startingFiscalPeriod AS VARCHAR(6));
                            SET @endingFiscalPeriodTXT = CAST(@endingFiscalPeriod AS VARCHAR(6));
                            
                            SET @SQL = 'SELECT  LEFT(CONVERT(varchar,DATEADD(month,6,pur.transaction_date),112),6) AS full_accounting_period,
                                                item.index_code, 
                                                oh3.orghier_level3, 
                                                oh4.orghier_level4, 
                                                oh4.orghier_level4_title,
                                                i.organization, 
                                                fh.fundhier_level1, 
                                                fh.fundhier_level2, 
                                                fh.fundhier_level3, 
                                                i.fund, 
                                                (CASE   WHEN msn.mission_id IS NULL THEN 3 
                                                        ELSE msn.mission_id 
                                                END) AS ''Mission'',
                                                (CASE   WHEN cdo.project_type_short IS NULL THEN ''CDO'' 
                                                        ELSE cdo.project_type_short 
                                                END) AS ''Project_Type'', 
                                                i.program, 
                                                item.account_code,
                                                acct.pa_title,
                                                tm.team_id, 
                                                pur.transaction_date,
                                                pur.purchase_invoice_number,
                                                item.transaction_amount AS ''line_item_amount'',
                                                pur.transaction_amount,
                                                pur.use_tax_amount,
                                                pur.employee_id,
                                                pur.employee_name,
                                                pur.document_number,
                                                pur.comment,
                                                item.product_code,
                                                item.line_item_description,
                                                item.serial_number,
                                                item.quantity_val,
                                                item.unit_of_measure,
                                                item.unit_cost_val '
                            
                            SET @SQL = @SQL + 'FROM    pur.bks_line_item                           AS item 
                                                        INNER JOIN      pur.bks_purchase            AS pur  ON pur.bks_transaction_id = item.bks_transaction_id
                                                        INNER JOIN      coa_db.indx                 AS i    ON i.indx = item.index_code 
                                                                                                            AND i.most_recent_flag = ''Y''
                                                        INNER JOIN      coa_db.orgnhier_table       AS oh   ON oh.orgn_code = i.organization 
                                                        INNER JOIN      coa_db.fundhier_table       AS fh   ON i.fund = fh.fund_code 
                                                        LEFT OUTER JOIN qlink_db.orghier_level3     AS oh3  ON oh.orgnhier_level3 = oh3.orghier_level3 
                                                        LEFT OUTER JOIN qlink_db.orghier_level4     AS oh4  ON oh.orgnhier_level4 = oh4.orghier_level4 
                                                        LEFT OUTER JOIN qlink_db.fundhier_level1    AS fh1  ON fh.fundhier_level1 = fh1.fundhier_level1 
                                                        LEFT OUTER JOIN qlink_db.fundhier_level2    AS fh2  ON fh.fundhier_level2 = fh2.fundhier_level2 
                                                        LEFT OUTER JOIN qlink_db.fundhier_level3    AS fh3  ON fh.fundhier_level3 = fh3.fundhier_level3 
                                                        LEFT OUTER JOIN fin.xref_mission            AS xref ON i.fund = xref.pf_fund AND i.program = xref.pp_program 
                                                        LEFT OUTER JOIN cognos.mission              AS msn  ON xref.mission_id = msn.mission_id 
                                                        LEFT OUTER JOIN dbo.team_index              AS tmi  ON i.indx = tmi.index_code 
                                                        LEFT OUTER JOIN xref.index_project_type     AS xcdo ON i.indx = xcdo.indx 
                                                        INNER JOIN      cognos.project_type         AS cdo  ON cdo.project_type_id = xcdo.project_type_id 
                                                        LEFT OUTER JOIN dbo.team                    AS tm   ON tmi.team_id = tm.team_id 
                                                        LEFT OUTER JOIN ga.f_period_account         AS acct ON item.account_code = acct.pa_account
                                                                                                               AND CONVERT(INT,LEFT(CONVERT(varchar,DATEADD(month,6,pur.transaction_date),112),6)) = acct.full_accounting_period 
                                                        INNER JOIN      ga.f_period_account_type    AS actp ON acct.pat_account_type = actp.pat_account_type
                                                                                                               AND acct.full_accounting_period = actp.full_accounting_period '

                            SET @SQL = @SQL + 'WHERE   1 = 1 
                                                        AND oh.orgnhier_level3 IN (''JBAA03'') 
                                                        AND i.indx NOT IN (''MEDBD65'') '
                            
                            SET @SQL = @SQL + 'AND LEFT(CONVERT(varchar,DATEADD(month,6,pur.transaction_date),112),6) BETWEEN ' + @startingFiscalPeriodTXT + ' AND ' + @endingFiscalPeriodTXT + ' ';

                            IF @orghierLevel4 <> '' SET @SQL = @SQL + 'AND oh4.orghier_level4 IN(''' + @orghierLevel4 + ''') ';

                            IF @teamID <> 0 SET @SQL = @SQL + 'AND tm.team_id = ' + CAST(@teamID AS VARCHAR(MAX)) + ' ';

                            SET @SQL = @SQL + 'ORDER BY    CONVERT(INT,LEFT(CONVERT(varchar,DATEADD(month,6,pur.transaction_date),112),6)), 
                                                            oh3.orghier_level3, 
                                                            oh4.orghier_level4, 
                                                            pur.employee_name,
                                                            pur.transaction_date,
                                                            pur.purchase_invoice_number,
                                                            item.line_item_description '

                            EXEC(@SQL);

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO