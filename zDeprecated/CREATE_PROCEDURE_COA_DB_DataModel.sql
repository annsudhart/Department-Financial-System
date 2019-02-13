/***************************************************************************************
Name      : BSO Financial Management Interface - Chart of Accounts Data Model
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Update procedures for COA_DB (Chat of Accounts Table Model)
****************************************************************************************
PREREQUISITES:
- none
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

IF OBJECT_ID('coa_db.data_model_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.data_model_UPD;
GO
CREATE PROCEDURE    coa_db.data_model_UPD
                    AS
                    BEGIN
                        BEGIN TRY

                            -- Create code tables
                            IF SCHEMA_ID('codes') IS NULL EXEC('CREATE SCHEMA codes');
                            IF OBJECT_ID('codes.top','U') IS NULL
                                BEGIN
                                    CREATE TABLE codes.[top]
                                    (
                                        [top]                           CHAR(1)                         NOT NULL,
                                        top_description                 VARCHAR(3)                      NOT NULL 
                                    )
                                    CREATE UNIQUE INDEX SQLidx_codes_top on codes.[top]([top]);
                                    INSERT INTO codes.[top]([top],top_description) VALUES ('N','No'),('Y','Yes');
                                END
                            IF OBJECT_ID('codes.bottom','U') IS NULL
                                BEGIN
                                    CREATE TABLE codes.[bottom]
                                    (
                                        [bottom]                        CHAR(1)                         NOT NULL,
                                        bottom_description              VARCHAR(3)                      NOT NULL 
                                    )
                                    CREATE UNIQUE INDEX SQLidx_codes_bottom on codes.[bottom]([bottom]);
                                    INSERT INTO codes.[bottom]([bottom],bottom_description) VALUES ('N','No'),('Y','Yes');
                                END
                            IF OBJECT_ID('codes.code_level','U') IS NULL
                                BEGIN
                                    CREATE TABLE codes.code_level
                                    (
                                        code_level                      SMALLINT                        NOT NULL,
                                        code_level_description          VARCHAR(35)                     NOT NULL,
                                        last_actvy_date                 DATETIME2                       NOT NULL
                                    )
                                    CREATE UNIQUE INDEX SQLidx_codes_code_level ON codes.code_level(code_level);
                                    INSERT INTO codes.code_level(code_level, code_level_description,last_actvy_date)
                                                VALUES  (1,'Program Level One',CAST('1991-04-22' AS DATETIME2)),
                                                        (2,'Program Level Two',CAST('1991-04-22' AS DATETIME2)),
                                                        (3,'Program Level Three',CAST('1991-04-22' AS DATETIME2)),
                                                        (4,'Program Level Four',CAST('1991-04-22' AS DATETIME2)),
                                                        (5,'Program Level Five',CAST('1991-04-22' AS DATETIME2));
                                END

                            -- Run update sub-procedures
                            EXEC coa_db.accthier_table_UPD;
                            EXEC coa_db.fundhier_table_UPD;
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO

IF OBJECT_ID('coa_db.accthier_table_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.accthier_table_UPD;
GO
CREATE PROCEDURE    coa_db.accthier_table_UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_refresh DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            -- Create table if it doesn't already exist
                            IF OBJECT_ID('coa_db.accthier_table','U') IS NULL
                                BEGIN
                                        CREATE TABLE coa_db.accthier_table
                                        (
                                            acct_code                       CHAR(6)                         NOT NULL,
                                            [top]                           CHAR(1)                         NOT NULL,
                                            bottom                          CHAR(1)                         NOT NULL,
                                            code_level                      SMALLINT                        NOT NULL,
                                            code_1                          CHAR(6)                         NOT NULL,
                                            code_2                          CHAR(6)                         NOT NULL,
                                            code_3                          CHAR(6)                         NOT NULL,
                                            code_4                          CHAR(6)                         NOT NULL,
                                            code_5                          CHAR(6)                         NOT NULL,
                                            code_6                          CHAR(6)                         NOT NULL,
                                            code_7                          CHAR(6)                         NOT NULL,
                                            code_8                          CHAR(6)                         NOT NULL,
                                            refresh_date                    DATETIME2                       NOT NULL,
                                            accthier_table_id               DECIMAL(10,0)                   NOT NULL,
                                            rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
                                            version_number              ROWVERSION
                                        )
                                        CREATE CLUSTERED INDEX C_INDEX1 ON coa_db.accthier_table(acct_code)
                                        CREATE INDEX NC_INDEX_11 ON coa_db.accthier_table(code_1)
                                        CREATE INDEX NC_INDEX_21 ON coa_db.accthier_table(code_2)
                                        CREATE INDEX NC_INDEX_3 ON coa_db.accthier_table(code_3)
                                        CREATE INDEX NC_INDEX_4 ON coa_db.accthier_table(code_4)
                                        CREATE INDEX NC_INDEX_6 ON coa_db.accthier_table(code_level,acct_code)
                                        CREATE UNIQUE INDEX SQL120323221909850 ON coa_db.accthier_table(accthier_table_id)
                                END

                            -- Identify last update and record
                            SELECT @last_refresh = MAX(ah.refresh_date), @last_id = MAX(ah.accthier_table_id) FROM coa_db.accthier_table AS ah;
                            IF @last_refresh IS NULL SET @last_refresh = CAST('01/01/1900' AS DATETIME2);
                            IF @last_id IS NULL SET @last_id = 0;

                            -- Update existing records
                            IF OBJECT_ID('tempdb..##accthier_table_UPD') IS NOT NULL DROP TABLE tempdb.##accthier_table_UPD;
                            SET @SQL = 'SELECT  * INTO ##accthier_table_UPD FROM ' +
                                       'OPENQUERY(dw_db, ''SELECT *
                                        FROM    coa_db.accthier_table AS ah
                                        WHERE   ah.REFRESH_DATE > CAST(''''' + CAST(@last_refresh AS VARCHAR(MAX)) + ''''' AS DATE) AND
                                                ah.ACCTHIER_TABLE_ID <= CAST(''''' + CAST(@last_id AS VARCHAR(MAX)) + ''''' AS DECIMAL(10,0))'')';
                            EXEC(@SQL);
                            UPDATE  ah
                                    SET     ah.acct_code = zAH.ACCT_CODE,
                                            ah.[top] = zAH.[top],
                                            ah.bottom = zAH.bottom,
                                            ah.code_level = zAH.CODE_LEVEL,
                                            ah.code_1 = zAH.CODE_1,
                                            ah.code_2 = zAH.CODE_2,
                                            ah.code_3 = zAH.CODE_3,
                                            ah.code_4 = zAH.CODE_4,
                                            ah.code_5 = zAH.CODE_5,
                                            ah.code_6 = zAH.CODE_6,
                                            ah.code_7 = zAH.CODE_7,
                                            ah.code_8 = zAH.CODE_8,
                                            ah.refresh_date = zAH.REFRESH_DATE
                                    FROM    coa_db.accthier_table AS ah
                                            INNER JOIN ##accthier_table_UPD AS zAH ON (ah.accthier_table_id = zAH.ACCTHIER_TABLE_ID);
                            IF OBJECT_ID('tempdb..##accthier_table_UPD') IS NOT NULL DROP TABLE tempdb.##accthier_table_UPD;

                            -- Add new records
                            IF OBJECT_ID('tempdb..##accthier_table_ADD') IS NOT NULL DROP TABLE tempdb.##accthier_table_ADD;
                            SET @SQL = 'SELECT * INTO ##accthier_table_ADD FROM ' + 
                                       'OPENQUERY(dw_db, ''SELECT  ah.ACCT_CODE,
                                                ah.TOP,
                                                ah.BOTTOM,
                                                ah.CODE_LEVEL,
                                                ah.CODE_1,
                                                ah.CODE_2,
                                                ah.CODE_3,
                                                ah.CODE_4,
                                                ah.CODE_5,
                                                ah.CODE_6,
                                                ah.CODE_7,
                                                ah.CODE_8,
                                                ah.REFRESH_DATE,
                                                ah.ACCTHIER_TABLE_ID 
                                        FROM coa_db.accthier_table AS ah 
                                        WHERE ah.ACCTHIER_TABLE_ID > CAST(''''' + CAST(@last_id AS VARCHAR(MAX)) + ''''' AS DECIMAL(10,0))'')';
                            EXEC(@SQL);
                            INSERT INTO coa_db.accthier_table(
                                        acct_code,
                                        [top],
                                        bottom,
                                        code_level,
                                        code_1,
                                        code_2,
                                        code_3,
                                        code_4,
                                        code_5,
                                        code_6,
                                        code_7,
                                        code_8,
                                        refresh_date,
                                        accthier_table_id)
                                        SELECT * FROM ##accthier_table_ADD;
                            IF OBJECT_ID('tempdb..##accthier_table_ADD') IS NOT NULL DROP TABLE tempdb.##accthier_table_ADD;
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO

IF OBJECT_ID('coa_db.fundhier_table_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.fundhier_table_UPD;
GO
CREATE PROCEDURE    coa_db.fundhier_table_UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_refresh DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            -- Create table if it doesn't already exist
                            IF OBJECT_ID('coa_db.fundhier_table','U') IS NULL
                                BEGIN
                                    CREATE TABLE coa_db.fundhier_table
                                    (
                                        fund_code                       CHAR(6)                         NOT NULL,
                                        [top]                           CHAR(1)                         NOT NULL,
                                        bottom                          CHAR(1)                         NOT NULL,
                                        code_level                      SMALLINT                        NOT NULL,
                                        code_1                          CHAR(6)                         NOT NULL,
                                        code_2                          CHAR(6)                         NOT NULL,
                                        code_3                          CHAR(6)                         NOT NULL,
                                        code_4                          CHAR(6)                         NOT NULL,
                                        code_5                          CHAR(6)                         NOT NULL,
                                        code_6                          CHAR(6)                         NOT NULL,
                                        code_7                          CHAR(6)                         NOT NULL,
                                        code_8                          CHAR(6)                         NOT NULL,
                                        refresh_date                    DATETIME2                       NOT NULL,
                                        fundhier_table_id               DECIMAL(10,0)                   NOT NULL,
                                        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number              ROWVERSION
                                    )
                                    CREATE CLUSTERED INDEX C_INDEX9 ON coa_db.fundhier_table(fund_code)
                                    CREATE INDEX IDX008130419320000 ON coa_db.fundhier_table(fund_code,code_3,code_2,code_1)
                                    CREATE INDEX NC_INDEX_17 ON coa_db.fundhier_table(code_1)
                                    CREATE INDEX NC_INDEX_26 ON coa_db.fundhier_table(code_2)
                                    CREATE INDEX NC_INDEX_32 ON coa_db.fundhier_table(code_3)
                                    CREATE INDEX NC_INDEX_42 ON coa_db.fundhier_table(code_4)
                                    CREATE INDEX NC_INDEX_51 ON coa_db.fundhier_table(code_5)
                                    CREATE INDEX NC_INDEX_61 ON coa_db.fundhier_table(code_level,fund_code)
                                    CREATE UNIQUE INDEX SQL120323221904000 ON coa_db.fundhier_table(fundhier_table_id)
                                END

                            -- Identify last update and record
                            SELECT @last_refresh = MAX(ah.refresh_date), @last_id = MAX(ah.fundhier_table_id) FROM coa_db.fundhier_table AS ah;
                            IF @last_refresh IS NULL SET @last_refresh = CAST('01/01/1900' AS DATETIME2);
                            IF @last_id IS NULL SET @last_id = 0;

                            -- Update existing records
                            IF OBJECT_ID('tempdb..##fundhier_table_UPD') IS NOT NULL DROP TABLE tempdb.##fundhier_table_UPD;
                            SET @SQL = 'SELECT  * INTO ##fundhier_table_UPD FROM ' +
                                       'OPENQUERY(dw_db, ''SELECT *
                                        FROM    coa_db.fundhier_table AS ah
                                        WHERE   ah.REFRESH_DATE > CAST(''''' + CAST(@last_refresh AS VARCHAR(MAX)) + ''''' AS DATE) AND
                                                ah.fundHIER_TABLE_ID <= CAST(''''' + CAST(@last_id AS VARCHAR(MAX)) + ''''' AS DECIMAL(10,0))'')';
                            EXEC(@SQL);
                            UPDATE  ah
                                    SET     ah.fund_code = zAH.fund_CODE,
                                            ah.[top] = zAH.[top],
                                            ah.bottom = zAH.bottom,
                                            ah.code_level = zAH.CODE_LEVEL,
                                            ah.code_1 = zAH.CODE_1,
                                            ah.code_2 = zAH.CODE_2,
                                            ah.code_3 = zAH.CODE_3,
                                            ah.code_4 = zAH.CODE_4,
                                            ah.code_5 = zAH.CODE_5,
                                            ah.code_6 = zAH.CODE_6,
                                            ah.code_7 = zAH.CODE_7,
                                            ah.code_8 = zAH.CODE_8,
                                            ah.refresh_date = zAH.REFRESH_DATE
                                    FROM    coa_db.fundhier_table AS ah
                                            INNER JOIN ##fundhier_table_UPD AS zAH ON (ah.fundhier_table_id = zAH.fundHIER_TABLE_ID);
                            IF OBJECT_ID('tempdb..##fundhier_table_UPD') IS NOT NULL DROP TABLE tempdb.##fundhier_table_UPD;

                            -- Add new records
                            IF OBJECT_ID('tempdb..##fundhier_table_ADD') IS NOT NULL DROP TABLE tempdb.##fundhier_table_ADD;
                            SET @SQL = 'SELECT * INTO ##fundhier_table_ADD FROM ' + 
                                       'OPENQUERY(dw_db, ''SELECT  ah.fund_CODE,
                                                ah.TOP,
                                                ah.BOTTOM,
                                                ah.CODE_LEVEL,
                                                ah.CODE_1,
                                                ah.CODE_2,
                                                ah.CODE_3,
                                                ah.CODE_4,
                                                ah.CODE_5,
                                                ah.CODE_6,
                                                ah.CODE_7,
                                                ah.CODE_8,
                                                ah.REFRESH_DATE,
                                                ah.fundHIER_TABLE_ID 
                                        FROM coa_db.fundhier_table AS ah 
                                        WHERE ah.fundHIER_TABLE_ID > CAST(''''' + CAST(@last_id AS VARCHAR(MAX)) + ''''' AS DECIMAL(10,0))'')';
                            EXEC(@SQL);
                            INSERT INTO coa_db.fundhier_table(
                                        fund_code,
                                        [top],
                                        bottom,
                                        code_level,
                                        code_1,
                                        code_2,
                                        code_3,
                                        code_4,
                                        code_5,
                                        code_6,
                                        code_7,
                                        code_8,
                                        refresh_date,
                                        fundhier_table_id)
                                        SELECT * FROM ##fundhier_table_ADD;
                            IF OBJECT_ID('tempdb..##fundhier_table_ADD') IS NOT NULL DROP TABLE tempdb.##fundhier_table_ADD;
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO