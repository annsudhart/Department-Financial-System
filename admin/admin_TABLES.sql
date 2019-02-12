/***************************************************************************************
Name      : Medicine Financial System - Admin Schema
License   : Copyright (C) 2019 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates financial-statement indexing tables
****************************************************************************************
PREREQUISITES:
- ERROR HANDLING
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE dw_db;

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

/*  Causes SQL Server to follow  ISO rules regarding quotation mark identifiers &
    literal strings.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql
    -   When SET QUOTED_IDENTIFIER is ON, identifiers can be delimited by double 
        quotation marks, and literals must be delimited by single quotation marks. When 
        SET QUOTED_IDENTIFIER is OFF, identifiers cannot be quoted and must follow all 
        Transact-SQL rules for identifiers. */
SET QUOTED_IDENTIFIER ON;

/*  CREATE SCHEMA IF REQUIRED *********************************************************/
PRINT '** Create Schema if Non-Existent';
DECLARE @schemaName AS NVARCHAR(128) = 'admin';

IF SCHEMA_ID(@schemaName) IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA ' + @schemaName);
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=@schemaName, 
            @level0type=N'SCHEMA',
            @level0name=@schemaName;
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH

/*  DELETE EXISTING OBJECTS ***********************************************************/
PRINT '** Delete Existing Objects';

BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @objectName NVARCHAR(128) = '';
    DECLARE @objectType NVARCHAR(1) = '';
    DECLARE @localCounter INTEGER = 0;
    DECLARE @loopMe BIT = 1;

    WHILE @loopMe = 1
    BEGIN

        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='logSQL'
            SET @objectType = 'U'
        END
        ELSE SET @loopMe = 0

        IF @objectType = 'U' SET @SQL = 'TABLE'
        ELSE IF @objectType = 'P' SET @SQL = 'PROCEDURE'
        ELSE IF @objectType = 'V' SET @SQL = 'VIEW'
        ELSE SET @loopMe = 0

        SET @SQL = 'DROP ' + @SQL + ' ' + @schemaName + '.' + @objectName

        IF @loopMe = 1 AND OBJECT_ID(@schemaName + '.' + @objectName,@objectType) IS NOT NULL
        BEGIN
            BEGIN TRY
                PRINT @SQL
                EXEC(@SQL)
            END TRY
            BEGIN CATCH
                EXEC dbo.PrintError
                EXEC dbo.LogError
            END CATCH
        END

    END
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';

PRINT '--admin.logSQL'
BEGIN TRY
    CREATE TABLE admin.logSQL
        (
            log_id                          INT                             NOT NULL                                                    IDENTITY(1,1),
            exec_sql                        NVARCHAR(MAX)                       NULL,            
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_fin_coa_type            PRIMARY KEY CLUSTERED(log_id)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO