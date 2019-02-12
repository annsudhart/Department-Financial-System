/***************************************************************************************
Name      : Medicine Financial System - XREF Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates Schema/System Cross-Reference Tables
****************************************************************************************
PREREQUISITES:
- ERROR HANDLING
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
IF SCHEMA_ID('xref') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA xref');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'xref', 
            @level0type=N'SCHEMA',
            @level0name=N'xref';
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH
GO

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('xref.TABLES','P') IS NOT NULL DROP PROCEDURE xref.TABLES;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    xref.TABLES
                    (
                        @tableName VARCHAR(64) = '',
                        @initData BIT = 0
                    )
                    AS
                    BEGIN
                        DECLARE @schemaName VARCHAR(6) = 'xref';
                        DECLARE @SQL VARCHAR(MAX) = '';

                        BEGIN TRY
                            /* DROP EXISTING TABLE, IF NECESSARY */
                            IF OBJECT_ID(@schemaName + '.' + @tableName,'U') IS NOT NULL
                            BEGIN
                                BEGIN TRY
                                    SET @SQL = 'DROP TABLE ' + @schemaName + '.' + @tableName
                                    PRINT @SQL
                                    EXEC(@SQL)
                                END TRY
                                BEGIN CATCH
                                    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                                    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                                END CATCH 
                            END

                            /* CREATE SPECIFIED TABLE */
                            IF (@schemaName + '.' + @tableName) = 'xref.index_project_type'
                            BEGIN
                                BEGIN TRY
                                    CREATE TABLE xref.index_project_type
                                        (
                                            indx                            CHAR(10)                        NOT NULL,
                                            project_type_id				    INTEGER							NOT	NULL,
                                            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
                                            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
                                            lastupdatedby                   NVARCHAR(255)                       NULL,
                                            lastupdated                     DATETIME2(2)                        NULL,
                                            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
                                            versionnumber                   ROWVERSION						NOT	NULL,
                                            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
                                            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
                                        )
                                        CREATE UNIQUE INDEX PK_XREF_INDEX_PROJECT_TYPE ON xref.index_project_type(indx);
                                        CREATE INDEX FK_XREF_INDEX_PROJECT_TYPE_PROJECT_TYPE_ID ON xref.index_project_type(project_type_id);
                                END TRY
                                BEGIN CATCH
                                    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                                    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                                END CATCH 
                            END

                            /* LOAD DEFAULT DATAE */

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO