/***************************************************************************************
Name      : Medicine Financial System - COA_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Replicates COA_DB Schema
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
IF SCHEMA_ID('coa_db') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA coa_db');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'COA_DB', 
            @level0type=N'SCHEMA',
            @level0name=N'coa_db';
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

        SET @schemaName = 'coa_db'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='orgnhier_table'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='fundhier_table'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 3
        BEGIN
            SET @objectName ='accthier_table'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 4
        BEGIN
            SET @objectName ='account'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 5
        BEGIN
            SET @objectName ='indx'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 6
        BEGIN
            SET @objectName ='month'
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

PRINT '--coa_db.orgnhier_table'
BEGIN TRY
    CREATE TABLE coa_db.orgnhier_table
        (
            orgn_code                       CHAR(6)                         NOT NULL,
            top_level                       CHAR(1)                         NOT NULL,
            bottom_level                    CHAR(1)                         NOT NULL,
            orgnhier_level                   SMALLINT                        NOT NULL,
            orgnhier_level1                  CHAR(6)                         NOT NULL,
            orgnhier_level2                  CHAR(6)                         NOT NULL,
            orgnhier_level3                  CHAR(6)                         NOT NULL,
            orgnhier_level4                  CHAR(6)                         NOT NULL,
            orgnhier_level5                  CHAR(6)                         NOT NULL,
            orgnhier_level6                  CHAR(6)                         NOT NULL,
            orgnhier_level7                  CHAR(6)                         NOT NULL,
            orgnhier_level8                  CHAR(6)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            orgnhier_table_id               DECIMAL(10,0)                   NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX IDX008130417480000 ON coa_db.orgnhier_table(orgn_code,orgnhier_level3,orgnhier_level2,orgnhier_level1);
    CREATE INDEX I_OGRHIER_ORGN_CODE1 ON coa_db.orgnhier_table(orgn_code,orgnhier_level1);
    CREATE INDEX NC_INDEX_114 ON coa_db.orgnhier_table(orgnhier_level1);
    CREATE INDEX NC_INDEX_212 ON coa_db.orgnhier_table(orgnhier_level2);
    CREATE INDEX NC_INDEX_35 ON coa_db.orgnhier_table(orgnhier_level3);
    CREATE INDEX NC_INDEX_45 ON coa_db.orgnhier_table(orgnhier_level4);
    CREATE INDEX NC_INDEX_53 ON coa_db.orgnhier_table(orgnhier_level,orgn_code);
    CREATE UNIQUE INDEX SQL120323221912100 ON coa_db.orgnhier_table(orgnhier_table_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--coa_db.fundhier_table'
BEGIN TRY
    CREATE TABLE coa_db.fundhier_table
        (
            fund_code                       CHAR(6)                         NOT NULL,
            top_level                       CHAR(1)                         NOT NULL,
            bottom_level                    CHAR(1)                         NOT NULL,
            fundhier_level                   SMALLINT                        NOT NULL,
            fundhier_level1                  CHAR(6)                         NOT NULL,
            fundhier_level2                  CHAR(6)                         NOT NULL,
            fundhier_level3                  CHAR(6)                         NOT NULL,
            fundhier_level4                  CHAR(6)                         NOT NULL,
            fundhier_level5                  CHAR(6)                         NOT NULL,
            fundhier_level6                  CHAR(6)                         NOT NULL,
            fundhier_level7                  CHAR(6)                         NOT NULL,
            fundhier_level8                  CHAR(6)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            fundhier_table_id               DECIMAL(10,0)                   NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE CLUSTERED INDEX C_INDEX9 ON coa_db.fundhier_table(fund_code);
    CREATE INDEX IDX008130419320000 ON coa_db.fundhier_table(fund_code,fundhier_level3,fundhier_level2,fundhier_level1);
    CREATE INDEX NC_INDEX_17 ON coa_db.fundhier_table(fundhier_level1);
    CREATE INDEX NC_INDEX_26 ON coa_db.fundhier_table(fundhier_level2);
    CREATE INDEX NC_INDEX_32 ON coa_db.fundhier_table(fundhier_level3);
    CREATE INDEX NC_INDEX_42 ON coa_db.fundhier_table(fundhier_level4);
    CREATE INDEX NC_INDEX_51 ON coa_db.fundhier_table(fundhier_level5);
    CREATE INDEX NC_INDEX_61 ON coa_db.fundhier_table(fundhier_level,fund_code);
    CREATE UNIQUE INDEX SQL120323221904000 ON coa_db.fundhier_table(fundhier_table_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--coa_db.accthier_table'
BEGIN TRY
    CREATE TABLE coa_db.accthier_table
        (
            acct_code                       CHAR(6)                         NOT NULL,
            top_level                       CHAR(1)                         NOT NULL,
            bottom_level                    CHAR(1)                         NOT NULL,
            accthier_level                  SMALLINT                        NOT NULL,
            accthier_level1                 CHAR(6)                         NOT NULL,
            accthier_level2                 CHAR(6)                         NOT NULL,
            accthier_level3                 CHAR(6)                         NOT NULL,
            accthier_level4                 CHAR(6)                         NOT NULL,
            accthier_level5                 CHAR(6)                         NOT NULL,
            accthier_level6                 CHAR(6)                         NOT NULL,
            accthier_level7                 CHAR(6)                         NOT NULL,
            accthier_level8                 CHAR(6)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            accthier_table_id               DECIMAL(10,0)                   NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE CLUSTERED INDEX C_INDEX1 ON coa_db.accthier_table(acct_code);
    CREATE INDEX NC_INDEX_11 ON coa_db.accthier_table(accthier_level1);
    CREATE INDEX NC_INDEX_21 ON coa_db.accthier_table(accthier_level2);
    CREATE INDEX NC_INDEX_3 ON coa_db.accthier_table(accthier_level3);
    CREATE INDEX NC_INDEX_4 ON coa_db.accthier_table(accthier_level4);
    CREATE INDEX NC_INDEX_6 ON coa_db.accthier_table(accthier_level,acct_code);
    CREATE UNIQUE INDEX SQL120323221858550 ON coa_db.accthier_table(accthier_table_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--coa_db.account'
BEGIN TRY
    CREATE TABLE coa_db.account
        (
            account_key                     INT                             NOT NULL,
            account                         CHAR(6)                         NOT NULL,
            most_recent_flag                CHAR(1)                         NOT NULL,
            start_effective_date            DATETIME2(7)                    NOT NULL,
            end_effective_date              DATETIME2(7)                    NOT NULL,
            last_activity_date              DATE                            NOT NULL,
            [status]                        CHAR(8)                         NOT NULL,
            account_title                   VARCHAR(35)                     NOT NULL,
            sub_account_code                CHAR(6)                         NOT NULL,
            sub_account                     VARCHAR(35)                     NOT NULL,
            pool_account                    CHAR(6)                         NOT NULL,
            account_type_code               CHAR(2)                         NOT NULL,
            account_type                    VARCHAR(35)                     NOT NULL,
            normal_balance_ind              CHAR(1)                         NOT NULL,
            normal_balance                  CHAR(12)                        NOT NULL,
            refresh_date                    DATE                            NOT NULL,
            extrcode                        CHAR(10)                            NULL,
            ucop_acct_group_code            CHAR(6)                             NULL,
            extrcode_desc                   CHAR(35)                            NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_ACCOUNT ON coa_db.account(account,most_recent_flag);
        CREATE UNIQUE INDEX SQL120323221857310 ON coa_db.account(account_key);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--coa_db.indx'
BEGIN TRY
    CREATE TABLE coa_db.indx
        (
            indx_key                        INT                             NOT NULL,
            indx                            CHAR(10)                        NOT NULL,
            most_recent_flag                CHAR(1)                         NOT NULL,
            start_effective_date            DATETIME2(7)                    NOT NULL,
            end_effective_date              DATETIME2(7)                    NOT NULL,
            last_activity_date              DATE                            NOT NULL,
            [status]                        CHAR(8)                         NOT NULL,
            indx_title                      CHAR(35)                        NOT NULL,
            fund                            CHAR(6)                         NOT NULL,
            fund_title                      CHAR(35)                        NOT NULL,
            organization                    CHAR(6)                         NOT NULL,
            organization_title              CHAR(35)                        NOT NULL,
            account                         CHAR(6)                         NOT NULL,
            account_title                   CHAR(35)                        NOT NULL,
            program                         CHAR(6)                         NOT NULL,
            program_title                   CHAR(35)                        NOT NULL,
            [location]                      CHAR(6)                         NOT NULL,
            location_title                  CHAR(35)                        NOT NULL,
            early_inactivation_date         DATE                            NOT NULL,
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
        CREATE INDEX I_ACCOUNT2 ON coa_db.indx(account,most_recent_flag);
        CREATE INDEX I_FUND1 ON coa_db.indx(fund,most_recent_flag);
        CREATE INDEX I_INDX ON coa_db.indx(indx,most_recent_flag);
        CREATE INDEX I_ORGANIZATION ON coa_db.indx(organization,most_recent_flag);
        CREATE INDEX I_PROGRAM ON coa_db.indx(program,most_recent_flag);
        CREATE UNIQUE INDEX SQL120323221907660 ON coa_db.indx(indx_key);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--coa_db.[month]'
BEGIN TRY
    CREATE TABLE coa_db.[month]
        (
          	month_key                       INT                                 NULL,
            month_end_date                  DATETIME2(7)                        NULL,
            special_fiscal_period_flag      CHAR(1)                             NULL,
            month_num                       SMALLINT                            NULL,
            month_num_overall               INT                                 NULL,
            month_name                      CHAR(10)                            NULL,
            month_abbrev                    CHAR(3)                             NULL,
            cal_quarter                     SMALLINT                            NULL,
            cal_year                        INT                                 NULL,
            cal_year_month                  INT                                 NULL,
            fiscal_month                    SMALLINT                            NULL,
            fiscal_quarter                  SMALLINT                            NULL,
            fiscal_year                     INT                                 NULL,
            fiscal_year_month               INT                                 NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO