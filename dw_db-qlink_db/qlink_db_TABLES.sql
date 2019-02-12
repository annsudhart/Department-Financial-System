/***************************************************************************************
Name      : Medicine Financial System - QLINK_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Replicates QLINK_DB Schema
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
IF SCHEMA_ID('qlink_db') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA qlink_db');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'qlink_db', 
            @level0type=N'SCHEMA',
            @level0name=N'qlink_db';
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH
GO

/*  DELETE EXISTING OBJECTS ***********************************************************/
PRINT '** Delete Existing Objects';
GO

BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @schemaName NVARCHAR(128) = '';
    DECLARE @objectName NVARCHAR(128) = '';
    DECLARE @objectType NVARCHAR(1) = '';
    DECLARE @localCounter INTEGER = 0;
    DECLARE @loopMe BIT = 1;

    WHILE @loopMe = 1
    BEGIN

        SET @schemaName = 'qlink_db'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='gyro_dates'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='orghier_level3'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 3
        BEGIN
            SET @objectName ='orghier_level4'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 4
        BEGIN
            SET @objectName ='orghier_level5'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 5
        BEGIN
            SET @objectName ='fundhier_level1'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 6
        BEGIN
            SET @objectName ='fundhier_level2'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 7
        BEGIN
            SET @objectName ='fundhier_level3'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 8
        BEGIN
            SET @objectName ='rule_class_desc'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 9
        BEGIN
            SET @objectName ='subaccount_title'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 10
        BEGIN
            SET @objectName ='accthier_level1'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 11
        BEGIN
            SET @objectName ='accthier_level2'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 12
        BEGIN
            SET @objectName ='accthier_level3'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 13
        BEGIN
            SET @objectName ='accthier_level4'
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

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '--qlink_db.gyro_dates'
BEGIN TRY
    CREATE TABLE qlink_db.gyro_dates
        (
            context_code                    SMALLINT                        NOT NULL,
            context_description             VARCHAR(55)                     NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            dl_location                     VARCHAR(30)                         NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX I_GYRO_DATES_IX1 ON qlink_db.gyro_dates(context_description,full_accounting_period);
    CREATE UNIQUE INDEX SQL120323221922590 ON qlink_db.gyro_dates(context_code,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.orghier_level3'
BEGIN TRY
    CREATE TABLE qlink_db.orghier_level3
        (
            orghier_level3                  CHAR(6)                         NOT NULL,
            orghier_level3_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_orghier_level3 ON qlink_db.orghier_level3(orghier_level3);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.orghier_level4'
BEGIN TRY
    CREATE TABLE qlink_db.orghier_level4
        (
            orghier_level4                  CHAR(6)                         NOT NULL,
            orghier_level4_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_orghier_level4 ON qlink_db.orghier_level4(orghier_level4);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.orghier_level5'
BEGIN TRY
    CREATE TABLE qlink_db.orghier_level5
        (
            orghier_level5                  CHAR(6)                         NOT NULL,
            orghier_level5_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_orghier_level5 ON qlink_db.orghier_level5(orghier_level5);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.fundhier_level1'
BEGIN TRY
    CREATE TABLE qlink_db.fundhier_level1
        (
            fundhier_level1                  CHAR(6)                         NOT NULL,
            fundhier_level1_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_fundhier_level1 ON qlink_db.fundhier_level1(fundhier_level1);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.fundhier_level2'
BEGIN TRY
    CREATE TABLE qlink_db.fundhier_level2
        (
            fundhier_level2                  CHAR(6)                         NOT NULL,
            fundhier_level2_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_fundhier_level2 ON qlink_db.fundhier_level2(fundhier_level2);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.fundhier_level3'
BEGIN TRY
    CREATE TABLE qlink_db.fundhier_level3
        (
            fundhier_level3                  CHAR(6)                         NOT NULL,
            fundhier_level3_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_fundhier_level3 ON qlink_db.fundhier_level3(fundhier_level3);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.rule_class_desc'
BEGIN TRY
    CREATE TABLE qlink_db.rule_class_desc
        (
            rule_class_code                 CHAR(4)                         NOT NULL,
            rule_class_desc                 VARCHAR(35)                         NULL,
            [start_date]                    DATETIME2(7)                        NULL,
            end_date                        DATETIME2(7)                        NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX IRCCD ON qlink_db.rule_class_desc(rule_class_code);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.subaccount_title'
BEGIN TRY
    CREATE TABLE qlink_db.subaccount_title
        (
            subaccount                      CHAR(2)                         NOT NULL,
            subaccount_title                VARCHAR(35)                         NULL,
            std_ledger_category             VARCHAR(35)                         NULL,
            stud_affairs_ledger_category    VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX I_SUBACCT_IX1 ON qlink_db.subaccount_title(subaccount,subaccount_title);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.accthier_level1'
BEGIN TRY
    CREATE TABLE qlink_db.accthier_level1
        (
            accthier_level1                  CHAR(6)                         NOT NULL,
            accthier_level1_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_accthier_level1 ON qlink_db.accthier_level1(accthier_level1);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.accthier_level2'
BEGIN TRY
    CREATE TABLE qlink_db.accthier_level2
        (
            accthier_level2                  CHAR(6)                         NOT NULL,
            accthier_level2_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_accthier_level2 ON qlink_db.accthier_level2(accthier_level2);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.accthier_level3'
BEGIN TRY
    CREATE TABLE qlink_db.accthier_level3
        (
            accthier_level3                  CHAR(6)                         NOT NULL,
            accthier_level3_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_accthier_level3 ON qlink_db.accthier_level3(accthier_level3);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--qlink_db.accthier_level4'
BEGIN TRY
    CREATE TABLE qlink_db.accthier_level4
        (
            accthier_level4                  CHAR(6)                         NOT NULL,
            accthier_level4_title            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE UNIQUE INDEX PK_qlink_db_accthier_level4 ON qlink_db.accthier_level4(accthier_level4);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO