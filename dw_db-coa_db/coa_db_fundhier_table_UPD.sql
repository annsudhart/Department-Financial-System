/***************************************************************************************
Name      : Medicine Financial System - COA_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates coa_db.fundhier_table
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
IF OBJECT_ID('coa_db.fundhier_table') IS NULL RETURN;
GO

IF OBJECT_ID('coa_db.fundhier_table_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.fundhier_table_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    coa_db.fundhier_table_UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            DELETE FROM coa_db.fundhier_table

                            INSERT INTO coa_db.fundhier_table
                                        (
                                            fund_code,
                                            top_level,
                                            bottom_level,
                                            fundhier_level,
                                            fundhier_level1,
                                            fundhier_level2,
                                            fundhier_level3,
                                            fundhier_level4,
                                            fundhier_level5,
                                            fundhier_level6,
                                            fundhier_level7,
                                            fundhier_level8,
                                            refresh_date,
                                            fundhier_table_id
                                        )
                            SELECT      dw.fund_code,
                                        dw.[top],
                                        dw.[bottom],
                                        dw.code_level,
                                        dw.code_1,
                                        dw.code_2,
                                        dw.code_3,
                                        dw.code_4,
                                        dw.code_5,
                                        dw.code_6,
                                        dw.code_7,
                                        dw.code_8,
                                        dw.refresh_date,
                                        dw.fundhier_table_id
                            FROM        DW_DB..COA_DB.FUNDHIER_TABLE AS dw

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO