/***************************************************************************************
Name      : Medicine Financial System - QueryLink Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Mimics QueryLink - Index Balance for MEDICINE
****************************************************************************************
PREREQUISITES:
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
IF SCHEMA_ID('ql') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA ql');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'QueryLink Queries', 
            @level0type=N'SCHEMA',
            @level0name=N'ql';
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH
GO

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('ql.index_balance_pldetail','P') IS NOT NULL DROP PROCEDURE ql.index_balance_pldetail;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ql.index_balance_pldetail
                    (
                        @selectFullAccountingPeriod INT = 0,
                        @pullDataPeriods VARCHAR(5) = 'FYTD',
                        @orghierLevel4 CHAR(6) = '',
                        @acctAdjBOY BIT = 1,
                        @acctAdjEOY BIT = 1,
                        @acctAdjAnl BIT = 1,
                        @teamID INT = 0,
                        @pi_account_index CHAR(10) = ''
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
                            
                            SET @SQL = 'SELECT      d.full_accounting_period, 
                                                    d.orghier_level4, 
                                                    d.fundhier_level1,
                                                    d.fundhier_level2,
                                                    d.fundhier_level2_title, 
                                                    d.fundhier_level3,
                                                    d.fundhier_level3_title,
                                                    d.[status],
                                                    d.indx,
                                                    d.fund,
                                                    d.organization,
                                                    d.program,
                                                    d.Mission,
                                                    d.indx_title,
                                                    d.fund_title,
                                                    d.organization_title,
                                                    d.program_title,
                                                    d.location_title,
                                                    d.Mission_Title,
                                                    d.team_id,
                                                    d.team_name,
                                                    d.core_operations,
                                                    d.Overall_Balance,
                                                    d.ExpTransIDC_Balance,
                                                    d.fYTD_Revenue_Balance,
                                                    d.fYTD_Expenditure_Balance,
                                                    d.fYTD_Transfer_Balance,
                                                    d.fYTD_IDC_Balance,
                                                    d.fYTD_Encumbrance_Balance,
                                                    d.Deficit_OrgFund
                                        FROM        ql.index_balance AS d
                                        WHERE       1 = 1 '
                            
                            SET @SQL = @SQL + 'AND d.full_accounting_period >= ' + @startingFiscalPeriodTXT + ' ';
                            SET @SQL = @SQL + 'AND d.full_accounting_period <= ' + @endingFiscalPeriodTXT + ' ';

                            IF @orghierLevel4 <> '' SET @SQL = @SQL + 'AND d.orghier_level4 IN(''' + @orghierLevel4 + ''') ';

                            IF @acctAdjBOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_BOY = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_EOY = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_Anl = 0 ';

                            IF @teamID <> 0 SET @SQL = @SQL + 'AND d.team_id = ' + CAST(@teamID AS VARCHAR(MAX)) + ' ';

                            IF @pi_account_index <>'' SET @SQL = @SQL + 'AND i.indx IN(''' + @pi_account_index + ''') ';

                            /*  
                                MODIFIED:
                                    - SELECT
                                    Streamlined formula for 'Budget'
                                    Streamlined formula for 'Financial'
                                    Streamlined formula for 'BalanceWoEncumbrance'
                                    Streamlined formula for 'Encumbrance'
                                    Streamlined formula for 'BalanceWEncubmrance'
                                    Streamlined formula for 'Transaction_Date'
                                ADDED:
                                    - FROM
                                    LEFT OUTER JOIN ga.f_period_fund_type   AS pft  ON  pf.full_accounting_period = pft.full_accounting_period
                                                                                        AND pf.pft_fund_type = pft.pft_fund_type 
                                    LEFT OUTER JOIN ga.f_period_account_type AS pat ON  pa.full_accounting_period = pat.full_accounting_period
                                                                                        AND pa.pat_account_type = pat.pat_account_type
                                REMOVED:
                                    - FROM
                                    INNER JOIN  qlink_db.gyro_dates     AS gd ON    ifoapal.full_accounting_period = gd.full_accounting_period  
                                    - WHERE
                                    gd.context_description IN ('Current Fiscal Year','Last Fiscal Year')
                            */
PRINT @SQL;
                            EXEC(@SQL);

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO