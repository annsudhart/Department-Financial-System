/***************************************************************************************
Name      : Medicine Financial System - GA Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates ga.f_period_index
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
IF OBJECT_ID('ga.f_period_index') IS NULL RETURN;
GO

IF OBJECT_ID('ga.f_period_index_UPD','P') IS NOT NULL DROP PROCEDURE ga.f_period_index_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ga.f_period_index_UPD
                    (
                        @selectFullAccountingPeriod INT=0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @lastFullAccountingPeriod AS INT;

                            SELECT @lastFullAccountingPeriod = MAX(d.full_accounting_period) FROM DW_DB..GA.F_PERIOD_INDEX AS d WHERE d.full_accounting_period < CAST(FORMAT(DATEADD(month,6,GETDATE()),'yyyyMM') AS INT)
                            IF @selectFullAccountingPeriod = 0 SET @selectFullAccountingPeriod = @lastFullAccountingPeriod

                            DELETE FROM ga.f_period_index WHERE ga.f_period_index.full_accounting_period = @selectFullAccountingPeriod

                            INSERT INTO ga.f_period_index
                                        (
                                            pi_account_index,
                                            accounting_period,
                                            pi_effective_date,
                                            pi_title,
                                            pf_fund,
                                            po_organization,
                                            pa_account,
                                            pp_program,
                                            pl_location,
                                            refresh_date,
                                            full_accounting_period
                                        )
                            SELECT      dw.pi_account_index,
                                        dw.accounting_period,
                                        dw.pi_effective_date,
                                        dw.pi_title,
                                        dw.pf_fund,
                                        dw.po_organization,
                                        dw.pa_account,
                                        dw.pp_program,
                                        dw.pl_location,
                                        dw.refresh_date,
                                        dw.full_accounting_period
                            FROM        DW_DB..GA.F_PERIOD_INDEX AS dw
                                        INNER JOIN DW_DB..COA_DB.ORGNHIER_TABLE AS oh ON    dw.po_organization = oh.orgn_code
                            WHERE       dw.full_accounting_period = @selectFullAccountingPeriod
                                        AND oh.code_3 = 'JBAA03'

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO