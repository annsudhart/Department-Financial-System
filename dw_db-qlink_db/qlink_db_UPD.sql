/***************************************************************************************
Name      : Medicine Financial System - QLINK_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates qlink_db.*
****************************************************************************************
PREREQUISITES:
- qlink_db_TABLES Execution
- qlink_db_*_UPD
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
IF OBJECT_ID('qlink_db.UPD','P') IS NOT NULL DROP PROCEDURE qlink_db.UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    qlink_db.UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            PRINT 'qlink_db.gyro_dates_UPD'
                            EXEC qlink_db.gyro_dates_UPD

                            PRINT 'qlink_db.orghier_level3_UPD'
                            EXEC qlink_db.orghier_level3_UPD

                            PRINT 'qlink_db.orghier_level4_UPD'
                            EXEC qlink_db.orghier_level4_UPD

                            PRINT 'qlink_db.orghier_level5_UPD'
                            EXEC qlink_db.orghier_level5_UPD

                            PRINT 'qlink_db.fundhier_level1_UPD'
                            EXEC qlink_db.fundhier_level1_UPD

                            PRINT 'qlink_db.fundhier_level2_UPD'
                            EXEC qlink_db.fundhier_level2_UPD

                            PRINT 'qlink_db.fundhier_level3_UPD'
                            EXEC qlink_db.fundhier_level3_UPD

                            PRINT 'qlink_db.rule_class_desc_UPD'
                            EXEC qlink_db.rule_class_desc_UPD

                            PRINT 'qlink_db.subaccount_title_UPD'
                            EXEC qlink_db.subaccount_title_UPD

                            PRINT 'qlink_db.accthier_level1_UPD'
                            EXEC qlink_db.accthier_level1_UPD

                            PRINT 'qlink_db.accthier_level2_UPD'
                            EXEC qlink_db.accthier_level2_UPD

                            PRINT 'qlink_db.accthier_level3_UPD'
                            EXEC qlink_db.accthier_level3_UPD

                            PRINT 'qlink_db.accthier_level4_UPD'
                            EXEC qlink_db.accthier_level4_UPD

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO