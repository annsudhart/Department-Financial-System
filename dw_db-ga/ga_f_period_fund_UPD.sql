/***************************************************************************************
Name      : Medicine Financial System - GA Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates ga.f_period_fund
****************************************************************************************
PREREQUISITES:
- ga_TABLES Execution
- Error Handling
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

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('ga.f_period_fund') IS NULL RETURN;
GO

IF OBJECT_ID('ga.f_period_fund_UPD','P') IS NOT NULL DROP PROCEDURE ga.f_period_fund_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ga.f_period_fund_UPD
                    (
                        @selectFullAccountingPeriod INT=0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @lastFullAccountingPeriod AS INT;

                            SELECT @lastFullAccountingPeriod = MAX(d.full_accounting_period) FROM DW_DB..GA.F_PERIOD_FUND AS d WHERE d.full_accounting_period < CAST(FORMAT(DATEADD(month,6,GETDATE()),'yyyyMM') AS INT)
                            IF @selectFullAccountingPeriod = 0 SET @selectFullAccountingPeriod = @lastFullAccountingPeriod

                            DELETE FROM ga.f_period_fund WHERE ga.f_period_fund.full_accounting_period = @selectFullAccountingPeriod

                            INSERT INTO ga.f_period_fund
                                        (
                                            pf_fund,
                                            accounting_period,
                                            pft_fund_type,
                                            pf_effective_date,
                                            pf_predecessor,
                                            pf_title,
                                            pf_grant_contract,
                                            pf_indirect_cost_code,
                                            pf_standard_percent,
                                            refresh_date,
                                            full_accounting_period
                                        )
                            SELECT      dw.pf_fund,
                                        dw.accounting_period,
                                        dw.pft_fund_type,
                                        dw.pf_effective_date,
                                        dw.pf_predecessor,
                                        dw.pf_title,
                                        dw.pf_grant_contract,
                                        dw.pf_indirect_cost_code,
                                        dw.pf_standard_percent,
                                        dw.refresh_date,
                                        dw.full_accounting_period
                            FROM        DW_DB..GA.F_PERIOD_FUND AS dw
                                        INNER JOIN DW_DB..GA.F_IFOAPAL AS fi ON             dw.pf_fund = fi.pf_fund
                                                                                            AND dw.full_accounting_period = fi.full_accounting_period
                                        INNER JOIN DW_DB..COA_DB.ORGNHIER_TABLE AS oh ON    fi.po_organization = oh.orgn_code
                            WHERE       dw.full_accounting_period = @selectFullAccountingPeriod
                                        AND oh.code_3 = 'JBAA03'
                            GROUP BY    dw.pf_fund,
                                        dw.accounting_period,
                                        dw.pft_fund_type,
                                        dw.pf_effective_date,
                                        dw.pf_predecessor,
                                        dw.pf_title,
                                        dw.pf_grant_contract,
                                        dw.pf_indirect_cost_code,
                                        dw.pf_standard_percent,
                                        dw.refresh_date,
                                        dw.full_accounting_period

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO