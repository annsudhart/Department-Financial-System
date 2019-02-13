/***************************************************************************************
Name      : BSO Financial Management Interface - IFOAPAL
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates IFOAPAL index tables
****************************************************************************************
PREREQUISITES:
- ERROR HANDLING
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE [dw_db];
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
IF SCHEMA_ID('usys') IS NULL
	BEGIN
        EXEC('CREATE SCHEMA [usys]');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'Contains application system objects.', 
            @level0type=N'SCHEMA',
            @level0name=N'usys';
    END
GO

/*  DELETE EXISTING OBJECTS ***********************************************************/
PRINT '** Delete Existing Objects';
GO

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @schemaName NVARCHAR(128) = '';
DECLARE @objectName NVARCHAR(128) = '';
DECLARE @objectType NVARCHAR(1) = '';
DECLARE @localCounter INTEGER = 0;
DECLARE @loopMe BIT = 1;

WHILE @loopMe = 1
BEGIN

    SET @schemaName = 'usys'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName ='global_variables'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName ='objects_table_fields'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 3
    BEGIN
        SET @objectName ='access_data_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 4
    BEGIN
        SET @objectName ='objects'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 5
    BEGIN
        SET @objectName ='access_object_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 6
    BEGIN
        SET @objectName ='application'
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

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '--usys.application'
BEGIN TRY
    CREATE TABLE usys.application
    (
        application_id                  INT                                 NOT NULL    IDENTITY(1,1),
        application_name                VARCHAR(50)                             NULL,
        application_description         VARCHAR(MAX)                            NULL,
        application_path                VARCHAR(255)                            NULL,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_application                 PRIMARY KEY CLUSTERED(application_id)
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.access_object_type'
BEGIN TRY
    CREATE TABLE usys.access_object_type
    (
        access_object_type_id           INT                                 NOT NULL,
        access_object_type_name         VARCHAR(64)                         NOT NULL,
        show_user                       BIT                                 NOT NULL    DEFAULT 0,
        show_admin                      BIT                                 NOT NULL    DEFAULT 0,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_access_object_type          PRIMARY KEY CLUSTERED(access_object_type_id)
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.access_object_type - add default data'
BEGIN TRY
    INSERT INTO usys.access_object_type
                (access_object_type_id,
                 access_object_type_name,
                 show_user,
                 show_admin)
                VALUES
                (-32775,'Module',0,1),
                (-32772,'Report',1,1),
                (-32768,'Form',1,1),
                (-32766,'Macro',1,1),
                (-32764,'Report',1,1),
                (-32761,'Module',0,1),
                (-32758,'User',0,0),
                (-32757,'Database Document',0,0),
                (1,'Table (local)',1,1),
                (2,'Access Object - Database',0,1),
                (3,'Access Object - Container',0,1),
                (4,'Table, linked ODB SQL',1,1),
                (5,'Query',1,1),
                (6,'Table, linked Access Excel',1,1),
                (7,'Type 7',1,1),
                (8,'SubDataSheet',1,1)
    ;
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.objects'
BEGIN TRY
    CREATE TABLE usys.objects
    (
        application_id                  INT                                 NOT NULL,
        objects_id                      INT                                 NOT NULL    IDENTITY(1,1),
        msysobjects_name                VARCHAR(64)                         NOT NULL,
        msysobjects_type                INT                                     NULL,
        object_purpose                  VARCHAR(MAX)                            NULL,
        object_source                   VARCHAR(MAX)                            NULL,
        primary_form                    VARCHAR(64)                             NULL,
        primary_update_form             VARCHAR(64)                             NULL,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_objects                     PRIMARY KEY CLUSTERED(objects_id),
        CONSTRAINT                      FK_usys_objects_application_id      FOREIGN KEY(application_id)                 REFERENCES usys.application(application_id),
        CONSTRAINT                      FK_usys_objects_msysobjects_type    FOREIGN KEY(msysobjects_type)               REFERENCES usys.access_object_type(access_object_type_id)
    )
    CREATE UNIQUE INDEX I_usys_objects_PK                   ON usys.objects(application_id,msysobjects_name)
    CREATE INDEX I_usys_objects_msysobjects_type            ON usys.objects(msysobjects_type)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.access_data_type'
BEGIN TRY
    CREATE TABLE usys.access_data_type
    (
        access_data_type_id             INT                                 NOT NULL,
        access_data_type_name           VARCHAR(64)                         NOT NULL,
        access_data_type_description    VARCHAR(255)                            NULL,
        access_data_type_ado_only       BIT                                 NOT NULL    DEFAULT 0,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_access_data_type          PRIMARY KEY CLUSTERED(access_data_type_id)
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.access_data_type - add default data'
BEGIN TRY
    INSERT INTO usys.access_data_type
                (access_data_type_id,
                 access_data_type_name,
                 access_data_type_description,
                 access_data_type_ado_only)
                VALUES
                (1,'dbBoolean','Boolean (True/False) data',0),
                (2,'dbByte','Byte (8-bit) data',0),
                (3,'dbInteger','Integer data',0),
                (4,'dbLong','Long Integer data',0),
                (5,'dbCurrency','Currency data',0),
                (6,'dbSingle','Single-precision floating-point data',0),
                (7,'dbDouble','Double-precision floating-point data',0),
                (8,'dbDate','Date value data',0),
                (9,'dbBinary','Binary data',0),
                (10,'dbText','Text data (variable width)',0),
                (11,'dbLongBinary','Binary data (bitmap)',0),
                (12,'dbMemo','Memo data (extended text)',0),
                (15,'dbGUID','GUID data',0),
                (16,'dbBigInt','Big Integer data',0),
                (17,'dbVarBinary','Variable Binary data (ODBCDirect only)',1),
                (18,'dbChar','Text data (fixed width)',0),
                (19,'dbNumeric','Numeric data (ODBCDirect only)',0),
                (20,'dbDecimal','Decimal data (ODBCDirect only)',1),
                (21,'dbFloat','Floating-point data (ODBCDirect only)',1),
                (22,'dbTime','Data in time format (ODBCDirect only)',1),
                (23,'dbTimeStamp','Data in time and date format (ODBCDirect only)',1),
                (101,'dbAttachment','Attachment data',0),
                (102,'dbComplexByte','Multi-valued byte data',0),
                (103,'dbComplexInteger','Multi-value integer data',0),
                (104,'dbComplexLong','Multi-value long integer data',0),
                (105,'dbComplexSingle','Multi-value single-precision floating-point data',0),
                (106,'dbComplexDouble','Multi-value double-precision floating-point data',0),
                (107,'dbComplexGUID','Multi-value GUID data',0),
                (108,'dbComplexDecimal','Multi-value decimal data',0),
                (109,'dbComplexText','Multi-value Text data (variable width)',0)
    ;
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.objects_table_fields'
BEGIN TRY
    CREATE TABLE usys.objects_table_fields
    (
        id                              INT                                 NOT NULL    IDENTITY(1,1),
        objects_id                      INT                                 NOT NULL,
        msysobjects_name                VARCHAR(64)                         NOT NULL,
        sourcetable_property            VARCHAR(64)                             NULL,
        sourcefield_property            VARCHAR(64)                             NULL,
        ordinal_position                INT                                     NULL,
        name_property                   VARCHAR(64)                             NULL,
        type_property                   INT                                 NOT NULL    DEFAULT 10,
        fieldsize_property              INT                                 NOT NULL    DEFAULT 0,
        size_property                   INT                                 NOT NULL    DEFAULT 0,
        required_property               BIT                                 NOT NULL    DEFAULT 0,
        dbAutoIncrField                 BIT                                 NOT NULL    DEFAULT 0,
        dbFixedField                    BIT                                 NOT NULL    DEFAULT 0,
        dbHyperlinkField                BIT                                 NOT NULL    DEFAULT 0,
        dbVariableField                 BIT                                 NOT NULL    DEFAULT 0,
        pk                              BIT                                 NOT NULL    DEFAULT 0,
        fk                              BIT                                 NOT NULL    DEFAULT 0,
        index_table                     VARCHAR(64)                         NOT NULL,
        index_table_field               VARCHAR(64)                         NOT NULL,
        original_source_name            VARCHAR(64)                         NOT NULL,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_objects_table_fields        PRIMARY KEY CLUSTERED(id),
        CONSTRAINT                      FK_usys_fields_objects_id           FOREIGN KEY(objects_id)                     REFERENCES usys.objects(objects_id),
        CONSTRAINT                      FK_usys_fields_type_property        FOREIGN KEY(type_property)                  REFERENCES usys.access_data_type(access_data_type_id)
    )
    CREATE UNIQUE INDEX I_usys_objects_table_fields_PK          ON usys.objects_table_fields(objects_id,msysobjects_name)
    CREATE INDEX I_usys_objects_table_fields_type_property1     ON usys.objects_table_fields(type_property)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '--usys.global_variables'
BEGIN TRY
    CREATE TABLE usys.global_variables
    (
        application_id                  INT                                 NOT NULL,
        global_variable_id              INT                                 NOT NULL    IDENTITY(1,1),
        variable_name                   VARCHAR(25)                         NOT NULL,
        variable_value                  VARCHAR(255)                        NOT NULL,
        access_data_type_id             INT                                 NOT NULL    DEFAULT 10,
        createdby                       NVARCHAR(255)                       NOT NULL                                    DEFAULT USER_NAME(),
        createddate                     DATETIME2	                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        lastupdatedby                   NVARCHAR(255)                           NULL,
        lastupdated                     DATETIME2(2)                            NULL,
        rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL      NOT NULL                                    DEFAULT NEWSEQUENTIALID(),
        versionnumber                   ROWVERSION						    NOT	NULL,
        validfrom                       DATETIME2(2)                        NOT NULL                                    DEFAULT SYSUTCDATETIME(),
        validto                         DATETIME2(2)                        NOT NULL                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                      PK_usys_global_variables            PRIMARY KEY CLUSTERED(global_variable_id),
        CONSTRAINT                      FK_usys_variables_application_id    FOREIGN KEY(application_id)                 REFERENCES usys.application(application_id),
        CONSTRAINT                      FK_usys_variables_data_type         FOREIGN KEY(access_data_type_id)                  REFERENCES usys.access_data_type(access_data_type_id)
    )
    CREATE UNIQUE INDEX I_usys_global_variables_PK              ON usys.global_variables(application_id,variable_name)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH