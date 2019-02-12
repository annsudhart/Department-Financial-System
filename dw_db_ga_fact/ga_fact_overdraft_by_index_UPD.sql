/***************************************************************************************
Name      : Medicine Financial System - GA Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates ga_fact.overdraft_by_index
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
IF OBJECT_ID('ga_fact.overdraft_by_index') IS NULL RETURN;
GO

IF OBJECT_ID('ga_fact.overdraft_by_index_UPD','P') IS NOT NULL DROP PROCEDURE ga_fact.overdraft_by_index_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ga_fact.overdraft_by_index_UPD
                    (
                        @selectFullAccountingPeriod INT=0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @lastFullAccountingPeriod AS INT;

                            SELECT  @lastFullAccountingPeriod = MAX(mt.fiscal_year_month) 
                            FROM    DW_DB..GA_FACT.OVERDRAFT_BY_INDEX AS dw 
                                    INNER JOIN DW_DB..COA_DB.[MONTH]  AS mt ON dw.month_key = mt.month_key
                            WHERE   mt.fiscal_year_month < CAST(FORMAT(DATEADD(month,6,GETDATE()),'yyyyMM') AS INT)

                            IF @selectFullAccountingPeriod = 0 SET @selectFullAccountingPeriod = @lastFullAccountingPeriod

                            DELETE FROM ga_fact.overdraft_by_index WHERE ga_fact.overdraft_by_index.full_accounting_period = @selectFullAccountingPeriod

                            INSERT INTO ga_fact.overdraft_by_index
                                        (
                                            month_key,
                                            indx_key,
                                            overall_overdraft,
                                            mo_in_overall_overdraft,
                                            exp_trans_overdraft,
                                            mo_in_exp_trans_overdraft,
                                            tot_exp_overdraft,
                                            mo_in_tot_exp_overdraft,
                                            fiscal_ytd_revenue,
                                            fiscal_ytd_expenditures,
                                            fiscal_ytd_transfers,
                                            fiscal_ytd_indirect_cost,
                                            fiscal_ytd_encumbrance,
                                            refresh_date,
                                            full_accounting_period
                                        )
                            SELECT      dw.month_key,
                                        dw.indx_key,
                                        dw.overall_overdraft,
                                        dw.mo_in_overall_overdraft,
                                        dw.exp_trans_overdraft,
                                        dw.mo_in_exp_trans_overdraft,
                                        dw.tot_exp_overdraft,
                                        dw.mo_in_tot_exp_overdraft,
                                        dw.fiscal_ytd_revenue,
                                        dw.fiscal_ytd_expenditures,
                                        dw.fiscal_ytd_transfers,
                                        dw.fiscal_ytd_indirect_cost,
                                        dw.fiscal_ytd_encumbrance,
                                        dw.refresh_date,
                                        mt.fiscal_year_month
                            FROM        DW_DB..GA_FACT.OVERDRAFT_BY_INDEX       AS dw
                                        INNER JOIN DW_DB..COA_DB.[MONTH]        AS mt   ON dw.month_key = mt.month_key 
                                        INNER JOIN DW_DB..COA_DB.INDX           AS indx ON indx.indx_key = dw.indx_key 
                                        INNER JOIN DW_DB..COA_DB.ORGNHIER_TABLE AS oh   ON oh.orgn_code = indx.organization
                            WHERE       mt.fiscal_year_month = @selectFullAccountingPeriod
                                        AND oh.code_3 = 'JBAA03'

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO