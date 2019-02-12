/***************************************************************************************
Name      : Medicine Financial System - COA_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates coa_db.*
****************************************************************************************
PREREQUISITES:
- coa_db_TABLES Execution
- coa_db_*_UPD
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
IF OBJECT_ID('coa_db.UPD','P') IS NOT NULL DROP PROCEDURE coa_db.UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    coa_db.UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            PRINT 'coa_db.fundhier_table_UPD'
                            EXEC coa_db.fundhier_table_UPD

                            PRINT 'coa_db.orgnhier_table_UPD'
                            EXEC coa_db.orgnhier_table_UPD

                            PRINT 'coa_db.accdthier_table_UPD'
                            EXEC coa_db.accthier_table_UPD

                            PRINT 'coa_db.account_UPD'
                            EXEC coa_db.account_UPD

                            PRINT 'coa_db.indx_UPD'
                            EXEC coa_db.indx_UPD

                            PRINT 'coa_db.month_UPD'
                            EXEC coa_db.month_UPD

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO