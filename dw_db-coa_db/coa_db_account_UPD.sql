/***************************************************************************************
Name      : Medicine Financial System - COA_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates coa_db.account
****************************************************************************************
PREREQUISITES:
- coa_db_TABLES Execution
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
IF OBJECT_ID('coa_db.account') IS NULL RETURN;
GO

IF OBJECT_ID('coa_db.account_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.account_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    coa_db.account_UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            DELETE FROM coa_db.account

                            INSERT INTO coa_db.account
                                        (
                                            account_key,
                                            account,
                                            most_recent_flag,
                                            start_effective_date,
                                            end_effective_date,
                                            last_activity_date,
                                            [status],
                                            account_title,
                                            sub_account_code,
                                            sub_account,
                                            pool_account,
                                            account_type_code,
                                            account_type,
                                            normal_balance_ind,
                                            normal_balance,
                                            refresh_date,
                                            extrcode,
                                            ucop_acct_group_code,
                                            extrcode_desc
                                        )
                            SELECT      dw.account_key,
                                        dw.account,
                                        dw.most_recent_flag,
                                        dw.start_effective_date,
                                        dw.end_effective_date,
                                        dw.last_activity_date,
                                        dw.[status],
                                        dw.account_title,
                                        dw.sub_account_code,
                                        dw.sub_account,
                                        dw.pool_account,
                                        dw.account_type_code,
                                        dw.account_type,
                                        dw.normal_balance_ind,
                                        dw.normal_balance,
                                        dw.refresh_date,
                                        dw.extrcode,
                                        dw.ucop_acct_group_code,
                                        dw.extrcode_desc
                            FROM        DW_DB..COA_DB.ACCOUNT AS dw

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO