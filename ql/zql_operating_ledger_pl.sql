/* DEPRECATED QUERY - SEE UPDATED ql_operating_ledger.sql *****************************/

/***************************************************************************************
Name      : Medicine Financial System - QueryLink Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Mimics QueryLink - Operating Ledger Detail for MEDICINE
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
IF OBJECT_ID('ql.operating_ledger_pl','P') IS NOT NULL DROP PROCEDURE ql.operating_ledger_pl;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ql.operating_ledger_pl
                    (
                        @selectFullAccountingPeriod INT = 0,
                        @pullDataPeriods VARCHAR(5) = 'FYTD',
                        @orghierLevel4 CHAR(6) = '',
                        @acctAdjBOY BIT = 1,
                        @acctAdjEOY BIT = 1,
                        @acctAdjAnl BIT = 1,
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
                            ELSE IF @pullDataPeriods = 'FYTD' SET @startingFiscalPeriod = CAST(SUBSTRING(CAST(@selectFullAccountingPeriod AS CHAR(6)),1,4) + '00' AS INT);
                            ELSE IF @pullDataPeriods = '12MTD' SET @startingFiscalPeriod = CAST(FORMAT(DATEADD(month,-12+1,CAST(CAST(@selectFullAccountingPeriod AS VARCHAR(8)) + '01' AS DATETIME2)),'yyyyMM') AS INT);
                            ELSE SELECT @startingFiscalPeriod = MIN(d.full_accounting_period) FROM ga.f_ledger_activity AS d;

                            SET @startingFiscalPeriodTXT = CAST(@startingFiscalPeriod AS VARCHAR(6));
                            SET @endingFiscalPeriodTXT = CAST(@endingFiscalPeriod AS VARCHAR(6));
                            
                            SET @SQL = 'SELECT      d.full_accounting_period, 
                                                    d.orghier_level4, 
                                                    d.fundhier_level1, 
                                                    d.fundhier_level2,
                                                    d.fundhier_level3,
                                                    d.pi_account_index, 
                                                    d.pf_fund, 
                                                    d.po_organization, 
                                                    d.pa_account,
                                                    d.Sub_Account, 
                                                    d.pp_program, 
                                                    d.Mission,
                                                    d.pa_title, 
                                                    d.pp_title, 
                                                    d.Mission_Title,
                                                    d.accthier_level1,
                                                    d.accthier_level2,
                                                    d.accthier_level3,
                                                    d.accthier_level4,
                                                    d.account_type, 
                                                    d.team_id,
                                                    d.team_name,
                                                    SUM(d.Budget) AS ''Budget'',
                                                    SUM(d.Financial) AS ''Financial'',
                                                    SUM(d.BalanceWoEncumbrance) AS ''BalanceWoEncumbrance'',
                                                    SUM(d.Encumbrance) AS ''Encumbrance'',
                                                    SUM(d.BalanceWEncumbrance) AS ''BalanceWEncumbrance'',
                                                    d.Transaction_Date, 
                                                    d.lt_document_number, 
                                                    d.lt_description, 
                                                    d.lt_rule_class_code, 
                                                    d.lt_encumbrance_number, 
                                                    d.Active_Index, 
                                                    d.Acct_Adj_BOY, 
                                                    d.Acct_Adj_EOY, 
                                                    d.Acct_Adj_Anl,
                                                    d.COA_Account_Type,
                                                    d.COA_Account_L1,
                                                    d.COA_Account_L2,
                                                    d.COA_Account_L3,
                                                    d.COA_Account_L4,
                                                    d.coa_account
                                        FROM        ql.operating_ledger AS d
                                        WHERE       1 = 1 '
                            
                            SET @SQL = @SQL + 'AND d.full_accounting_period BETWEEN ' + @startingFiscalPeriodTXT + ' AND ' + @endingFiscalPeriodTXT + ' ';

                            IF @orghierLevel4 <> '' SET @SQL = @SQL + 'AND d.orghier_level4 IN(''' + @orghierLevel4 + ''') ';

                            IF @acctAdjBOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_BOY = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_EOY = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND d.Acct_Adj_Anl = 0 ';

                            IF @teamID <> 0 SET @SQL = @SQL + 'AND d.team_id = ' + CAST(@teamID AS VARCHAR(MAX)) + ' ';

                            SET @SQL = @SQL + 'GROUP BY 
                                                    d.full_accounting_period, 
                                                    d.orghier_level4, 
                                                    d.fundhier_level1, 
                                                    d.fundhier_level2,
                                                    d.fundhier_level3,
                                                    d.pi_account_index, 
                                                    d.pf_fund, 
                                                    d.po_organization, 
                                                    d.pa_account,
                                                    d.Sub_Account, 
                                                    d.pp_program, 
                                                    d.Mission,
                                                    d.pa_title, 
                                                    d.pp_title, 
                                                    d.Mission_Title,
                                                    d.accthier_level1,
                                                    d.accthier_level2,
                                                    d.accthier_level3,
                                                    d.accthier_level4,
                                                    d.account_type, 
                                                    d.team_id,
                                                    d.team_name,
                                                    d.Transaction_Date, 
                                                    d.lt_document_number, 
                                                    d.lt_description, 
                                                    d.lt_rule_class_code, 
                                                    d.lt_encumbrance_number, 
                                                    d.Active_Index, 
                                                    d.Acct_Adj_BOY, 
                                                    d.Acct_Adj_EOY, 
                                                    d.Acct_Adj_Anl,
                                                    d.COA_Account_Type,
                                                    d.COA_Account_L1,
                                                    d.COA_Account_L2,
                                                    d.COA_Account_L3,
                                                    d.COA_Account_L4,
                                                    d.coa_account'
PRINT @SQL;
                            EXEC(@SQL);

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO