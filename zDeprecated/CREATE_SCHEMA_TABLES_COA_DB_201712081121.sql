/***************************************************************************************
Name      : BSO Financial Management Interface - IFOAPAL
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates IFOAPAL index tables
****************************************************************************************
PREREQUISITES:
- none
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE [bso];
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

/*  SETUP ERROR HANDLING (from AdventureWorks2012) ************************************/
PRINT '** Setup Error Handling';
GO

PRINT '-- dbo.GetErrorInfo';
IF OBJECT_ID ( 'dbo.GetErrorInfo', 'P' ) IS NOT NULL
	DROP PROCEDURE dbo.GetErrorInfo;
GO
CREATE PROCEDURE dbo.GetErrorInfo
AS
SELECT
    ERROR_NUMBER() AS ErrorNumber
    ,ERROR_SEVERITY() AS ErrorSeverity
    ,ERROR_STATE() AS ErrorState
    ,ERROR_PROCEDURE() AS ErrorProcedure
    ,ERROR_LINE() AS ErrorLine
    ,ERROR_MESSAGE() AS ErrorMessage;
GO

-- uspPrintError prints error information about the error that caused 
-- execution to jump to the CATCH block of a TRY...CATCH construct. 
-- Should be executed from within the scope of a CATCH block otherwise 
-- it will return without printing any error information.
PRINT '-- dbo.PrintError';
IF OBJECT_ID ( 'dbo.PrintError', 'P' ) IS NOT NULL
	DROP PROCEDURE dbo.PrintError;
GO
CREATE PROCEDURE dbo.PrintError
AS
BEGIN
    SET NOCOUNT ON;

    -- Print error information. 
    PRINT 'Error ' + CONVERT(varchar(50), ERROR_NUMBER()) +
          ', Severity ' + CONVERT(varchar(5), ERROR_SEVERITY()) +
          ', State ' + CONVERT(varchar(5), ERROR_STATE()) + 
          ', Procedure ' + ISNULL(ERROR_PROCEDURE(), '-') + 
          ', Line ' + CONVERT(varchar(5), ERROR_LINE());
    PRINT ERROR_MESSAGE();
END;
GO

-- uspLogError logs error information in the ErrorLog table about the 
-- error that caused execution to jump to the CATCH block of a 
-- TRY...CATCH construct. This should be executed from within the scope 
-- of a CATCH block otherwise it will return without inserting error 
-- information.
PRINT '-- dbo.LogError'; 
IF OBJECT_ID ( 'dbo.LogError', 'P' ) IS NOT NULL
	DROP PROCEDURE dbo.LogError;
GO
CREATE PROCEDURE dbo.LogError
	(
		@ErrorLogID [int] = 0 OUTPUT	-- contains the ErrorLogID of the row inserted
	)									-- by uspLogError in the ErrorLog table
AS
BEGIN
    SET NOCOUNT ON;

    -- Output parameter value of 0 indicates that error 
    -- information was not logged
    SET @ErrorLogID = 0;

    BEGIN TRY
        -- Return if there is no error information to log
        IF ERROR_NUMBER() IS NULL
            RETURN;

        -- Return if inside an uncommittable transaction.
        -- Data insertion/modification is not allowed when 
        -- a transaction is in an uncommittable state.
        IF XACT_STATE() = -1
        BEGIN
            PRINT 'Cannot log error since the current transaction is in an uncommittable state. ' 
                + 'Rollback the transaction before executing uspLogError in order to successfully log error information.';
            RETURN;
        END

        IF OBJECT_ID('dbo.ErrorLog') IS NULL
            BEGIN
                CREATE TABLE dbo.ErrorLog
                (
                    UserName NVARCHAR(64) NULL,
                    ErrorNumber INT NULL,
                    ErrorSeverity INT NULL,
                    ErrorState INT NULL,
                    ErrorProcedure NVARCHAR(128) NULL,
                    ErrorLine INT NULL,
                    ErrorMessage NVARCHAR(MAX) NULL
                )
            END

        INSERT INTO [dbo].[ErrorLog] 
            (
            [UserName], 
            [ErrorNumber], 
            [ErrorSeverity], 
            [ErrorState], 
            [ErrorProcedure], 
            [ErrorLine], 
            [ErrorMessage]
            ) 
        VALUES 
            (
            CONVERT(sysname, CURRENT_USER), 
            ERROR_NUMBER(),
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_PROCEDURE(),
            ERROR_LINE(),
            ERROR_MESSAGE()
            );

        -- Pass back the ErrorLogID of the row inserted
        SET @ErrorLogID = @@IDENTITY;
    END TRY
    BEGIN CATCH
        PRINT 'An error occurred in stored procedure uspLogError: ';
        EXECUTE [dbo].[PrintError];
        RETURN -1;
    END CATCH
END;
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

    SET @schemaName = 'coa_db'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName ='index_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName ='fund_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 3
    BEGIN
        SET @objectName ='fundtype_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 4
    BEGIN
        SET @objectName ='agency_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 5
    BEGIN
        SET @objectName ='agency_fund_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 6
    BEGIN
        SET @objectName ='invgr_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 7
    BEGIN
        SET @objectName ='invgr_fund_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 8
    BEGIN
        SET @objectName ='idc_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 9
    BEGIN
        SET @objectName ='idc_aplcn_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 10
    BEGIN
        SET @objectName ='idc_dstbn_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 11
    BEGIN
        SET @objectName ='acct_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 12
    BEGIN
        SET @objectName ='accttype_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 13
    BEGIN
        SET @objectName ='lctn_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 14
    BEGIN
        SET @objectName ='orgn_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 15
    BEGIN
        SET @objectName ='prog_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 16
    BEGIN
        SET @objectName ='fundhier_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 17
    BEGIN
        SET @objectName ='proghier_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 18
    BEGIN
        SET @objectName ='lctnhier_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 19
    BEGIN
        SET @objectName ='accthier_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 20
    BEGIN
        SET @objectName ='orgnhier_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 21
    BEGIN
        SET @objectName ='rule_class_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 22
    BEGIN
        SET @objectName ='rule_efctv_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 23
    BEGIN
        SET @objectName ='rule_edits_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 24
    BEGIN
        SET @objectName ='rule_actns_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 25
    BEGIN
        SET @objectName ='fiscal_year_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 26
    BEGIN
        SET @objectName ='period_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 27
    BEGIN
        SET @objectName ='project_index'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 28
    BEGIN
        SET @objectName ='project'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 29
    BEGIN
        SET @objectName ='indx'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 30
    BEGIN
        SET @objectName ='fund'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 31
    BEGIN
        SET @objectName ='fund_hierarchy'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 32
    BEGIN
        SET @objectName ='organization'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 33
    BEGIN
        SET @objectName ='org_hierarchy'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 34
    BEGIN
        SET @objectName ='program'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 35
    BEGIN
        SET @objectName ='prog_hierarchy'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 36
    BEGIN
        SET @objectName ='location'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 37
    BEGIN
        SET @objectName ='lctn_hierarchy'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 38
    BEGIN
        SET @objectName ='code_lookup'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 39
    BEGIN
        SET @objectName ='month'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 40
    BEGIN
        SET @objectName ='date'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 41
    BEGIN
        SET @objectName ='account'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 42
    BEGIN
        SET @objectName ='acct_hierarchy'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 43
    BEGIN
        SET @objectName ='actv_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 44
    BEGIN
        SET @objectName ='coa_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 45
    BEGIN
        SET @objectName ='excluded_funds'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 46
    BEGIN
        SET @objectName ='foap_valid_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 47
    BEGIN
        SET @objectName ='idchxtrn_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 48
    BEGIN
        SET @objectName ='sysdata_table'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 49
    BEGIN
        SET @objectName ='ucop_fund_distinct'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 50
    BEGIN
        SET @objectName ='unvrs_table'
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

BEGIN TRY
    IF SCHEMA_ID(@schemaName) IS NOT NULL SET @SQL = 'DROP SCHEMA ' + @schemaName
    EXEC(@SQL)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

GO


/*  CREATE SCHEMAS ********************************************************************/
PRINT '** Create Schemas';
GO
CREATE SCHEMA coa_db;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'UC San Diego Chart of Accounts database', 
	 @level0type=N'SCHEMA',
	 @level0name=N'coa_db';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '-- coa_db.index_table'
BEGIN TRY
    CREATE TABLE coa_db.index_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        index_code                      CHAR(10)                        NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        index_code_title                VARCHAR(35)                     NOT NULL,
        fund_ovrde                      CHAR(1)                         NOT NULL,
        orgn_ovrde                      CHAR(1)                         NOT NULL,
        acct_ovrde                      CHAR(1)                         NOT NULL,
        prog_ovrde                      CHAR(1)                         NOT NULL,
        actv_ovrde                      CHAR(1)                         NOT NULL,
        lctn_ovrde                      CHAR(1)                         NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        orgn_code                       CHAR(6)                         NOT NULL,
        acct_code                       CHAR(6)                         NOT NULL,
        prog_code                       CHAR(6)                         NOT NULL,
        actv_code                       CHAR(6)                         NOT NULL,
        lctn_code                       CHAR(6)                         NOT NULL,
        early_inactive_date             SMALLDATETIME                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        index_table_id                  DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX14 ON coa_db.index_table(unvrs_code, coa_code, index_code, [start_date], [status])
    CREATE INDEX NC_INDEX_19 ON coa_db.index_table(index_code)
    CREATE INDEX NC_INDEX_28 ON coa_db.index_table(fund_code)
    CREATE INDEX NC_INDEX_33 ON coa_db.index_table(orgn_code)
    CREATE INDEX NC_INDEX_43 ON coa_db.index_table(acct_code)
    CREATE INDEX NC_INDEX_52 ON coa_db.index_table(prog_code)
    CREATE INDEX NC_INDEX_62 ON coa_db.index_table(lctn_code)
    CREATE UNIQUE INDEX SQL120323221907180 ON coa_db.index_table(index_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fundtype_table'
BEGIN TRY
    CREATE TABLE coa_db.fundtype_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        fund_type_code                  CHAR(2)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        fund_type_title                 VARCHAR(35)                     NOT NULL,
        pred_fund_type_code             CHAR(2)                         NOT NULL,
        sbrdt_fund_type_code            CHAR(2)                         NOT NULL,
        intrl_fund_type_code            CHAR(2)                         NOT NULL,
        cptlzn_fund_code                CHAR(6)                         NOT NULL,
        cptlzn_acct_code                CHAR(6)                         NOT NULL,
        indx_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        fund_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        orgn_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        acct_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        prog_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        cntrl_prd_code                  CHAR(1)                         NOT NULL,
        cntrl_svrty_code                CHAR(1)                         NOT NULL,
        dflt_from_ind                   CHAR(1)                         NOT NULL,
        encmbr_jrnl_type                VARCHAR(4)                      NOT NULL,
        cmtmnt_type                     CHAR(1)                         NOT NULL,
        roll_bdgt_ind                   CHAR(1)                         NOT NULL,
        bdgt_dspsn                      CHAR(1)                         NOT NULL,
        encmbr_pct                      DECIMAL(7,4)                    NOT NULL,
        bdgt_jrnl_type                  VARCHAR(4)                      NOT NULL,
        bdgt_clsfn                      CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        fundtype_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX10 ON coa_db.fundtype_table(unvrs_code,coa_code,fund_type_code,[start_date])
    CREATE UNIQUE INDEX SQL120323221904480 ON coa_db.fundtype_table(fundtype_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.agency_table'
BEGIN TRY
    CREATE TABLE coa_db.agency_table
    (
        agency_id                       CHAR(9)                         NOT NULL,
        agency_name                     VARCHAR(35)                     NOT NULL,
        agncy_intrl_ref_id              DECIMAL(10,0)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        agency_table_id                 DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX5 ON coa_db.agency_table(agency_id)
    CREATE INDEX NC_INDEX_13 ON coa_db.agency_table(agency_name)
    CREATE INDEX NC_INDEX_22 ON coa_db.agency_table(agency_table_id)
    CREATE UNIQUE INDEX SQL120323221900430 ON coa_db.agency_table(agency_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.agency_fund_table'
BEGIN TRY
    CREATE TABLE coa_db.agency_fund_table
    (
        agncy_intrl_ref_id              DECIMAL(10,0)                   NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        agency_fund_table_id            DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX4 ON coa_db.agency_fund_table(agncy_intrl_ref_id,fund_code)
    CREATE INDEX NC_INDEX_12 ON coa_db.agency_fund_table(fund_code)
    CREATE UNIQUE INDEX SQL120323221859870 ON coa_db.agency_fund_table(agency_fund_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.invgr_table'
BEGIN TRY
    CREATE TABLE coa_db.invgr_table
    (
        invgr_id                        CHAR(9)                         NOT NULL,
        invgr_name                      VARCHAR(35)                     NOT NULL,
        invgr_intrl_ref_id              DECIMAL(10,0)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        invgr_table_id                  DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX15 ON coa_db.invgr_table(invgr_id)
    CREATE INDEX NC_INDEX_111 ON coa_db.invgr_table(invgr_name)
    CREATE INDEX NC_INDEX_210 ON coa_db.invgr_table(invgr_intrl_ref_id)
    CREATE UNIQUE INDEX SQL120323221908560  ON coa_db.invgr_table(invgr_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.invgr_fund_table'
BEGIN TRY
    CREATE TABLE coa_db.invgr_fund_table
    (
        invgr_intrl_ref_id              DECIMAL(10,0)                   NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        invgr_fund_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_110 ON coa_db.invgr_fund_table(invgr_intrl_ref_id,fund_code)
    CREATE INDEX NC_INDEX_29 ON coa_db.invgr_fund_table(fund_code)
    CREATE UNIQUE INDEX SQL120323221908130 ON coa_db.invgr_fund_table(invgr_fund_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.idc_aplcn_table'
BEGIN TRY
    CREATE TABLE coa_db.idc_aplcn_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        idc_code                        CHAR(6)                         NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        idc_from_acct                   CHAR(6)                         NOT NULL,
        idc_thru_acct                   CHAR(6)                         NOT NULL,
        idc_pct                         DECIMAL(7,4)                    NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        idc_aplcn_table_id              DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX11 ON coa_db.idc_aplcn_table(unvrs_code,coa_code,idc_code,[start_date],idc_from_acct,idc_thru_acct)
    CREATE UNIQUE INDEX SQL120323221905320 ON coa_db.idc_aplcn_table(idc_aplcn_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.idc_dstbn_table'
BEGIN TRY
    CREATE TABLE coa_db.idc_dstbn_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        idc_code                        CHAR(6)                         NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        idc_dstbn_pct                   DECIMAL(7,4)                    NOT NULL,
        indx_code                       VARCHAR(10)                     NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        orgn_code                       CHAR(6)                         NOT NULL,
        acct_code                       CHAR(6)                         NOT NULL,
        prog_code                       CHAR(6)                         NOT NULL,
        actv_code                       CHAR(6)                         NOT NULL,
        lctn_code                       CHAR(6)                         NOT NULL,
        idc_acct_code                   CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        idc_dstbn_table_id              DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX12 ON coa_db.idc_dstbn_table(unvrs_code,coa_code,idc_code,[start_date])
    CREATE UNIQUE INDEX SQL120323221905750 ON coa_db.idc_dstbn_table(idc_dstbn_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.idc_table'
BEGIN TRY
    CREATE TABLE coa_db.idc_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        idc_code                        CHAR(6)                         NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        [status]                        CHAR(1)                         NOT NULL,
        cmplt_ind                       CHAR(1)                         NOT NULL,
        idc_desc                        VARCHAR(35)                     NOT NULL,
        idc_basis                       CHAR(1)                         NOT NULL,
        idc_std_pct                     DECIMAL(7,4)                    NOT NULL,
        idc_aplcn_basis_ind             CHAR(1)                         NOT NULL,
        idc_memo_ind                    CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        idc_table_id                    DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX13 ON coa_db.idc_table(unvrs_code,coa_code,idc_code,[start_date],[status])
    CREATE INDEX I_IDC_TABLE_IDC_CODE ON coa_db.idc_table(idc_code)
    CREATE UNIQUE INDEX SQL120323233814690 ON coa_db.idc_table(idc_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fund_table'
BEGIN TRY
    CREATE TABLE coa_db.fund_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        fund_title                      VARCHAR(35)                     NOT NULL,
        pred_fund_code                  CHAR(6)                         NOT NULL,
        data_entry_ind                  CHAR(1)                         NOT NULL,
        fdrl_flow_thru_ind              CHAR(1)                         NOT NULL,
        rvnu_acct                       CHAR(6)                         NOT NULL,
        acrl_acct                       CHAR(6)                         NOT NULL,
        cptlzn_acct_code                CHAR(6)                         NOT NULL,
        cptlzn_fund_code                CHAR(6)                         NOT NULL,
        dflt_orgn_code                  CHAR(6)                         NOT NULL,
        dflt_prog_code                  CHAR(6)                         NOT NULL,
        dftl_actv_code                  CHAR(6)                         NOT NULL,
        dflt_lctn_code                  CHAR(6)                         NOT NULL,
        bank_acct_code                  CHAR(2)                         NOT NULL,
        cnstrctn_prjct_code             VARCHAR(15)                     NOT NULL,
        prjct_desc                      VARCHAR(35)                     NOT NULL,
        eqty_acct_code                  CHAR(6)                         NOT NULL,
        cnstrctn_cptlzn_acct            CHAR(6)                         NOT NULL,
        cnstrctn_cptlzn_fund            CHAR(6)                         NOT NULL,
        funding_srce                    CHAR(6)                         NOT NULL,
        cip_acct                        CHAR(6)                         NOT NULL,
        asset_acct                      CHAR(6)                         NOT NULL,
        max_cnstrctn_amt                DECIMAL(19,4)                   NOT NULL,
        close_prjct_ind                 CHAR(1)                         NOT NULL,
        prjct_cost_share                CHAR(6)                         NOT NULL,
        prjct_cost_share_amt            DECIMAL(19,4)                   NOT NULL,
        cum_auth_amt                    DECIMAL(19,4)                   NOT NULL,
        grant_cntrct_nmbr               VARCHAR(20)                     NOT NULL,
        pms_code                        VARCHAR(15)                     NOT NULL,
        report_cycle_code               CHAR(1)                         NOT NULL,
        billing_frmt                    CHAR(1)                         NOT NULL,
        auth_funding_amt                DECIMAL(19,4)                   NOT NULL,
        pay_mthd_code                   VARCHAR(4)                      NOT NULL,
        grant_cost_share_code           CHAR(6)                         NOT NULL,
        grant_cost_share_amt            DECIMAL(19,4)                   NOT NULL,
        grant_indrt_cost_code           CHAR(6)                         NOT NULL,
        estmd_cmpln_date                SMALLDATETIME                   NOT NULL,
        prjct_close_date                SMALLDATETIME                   NOT NULL,
        cntrl_fund                      CHAR(6)                         NOT NULL,
        cmbnd_cntrl_ind                 CHAR(1)                         NOT NULL,
        indx_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        fund_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        orgn_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        acct_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        prog_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        cntrl_prd_code                  CHAR(1)                         NOT NULL,
        cntrl_svrty_code                CHAR(1)                         NOT NULL,
        cmplt_ind                       CHAR(1)                         NOT NULL,
        alt_pool_ind                    CHAR(1)                         NOT NULL,
        agncy_intrl_ref_id              DECIMAL(10,0)                   NOT NULL,
        mgr_intrl_ref_id                DECIMAL(10,0)                   NOT NULL,
        cnstrctn_intrl_ref              DECIMAL(10,0)                   NOT NULL,
        invgr_intrl_ref                 DECIMAL(10,0)                   NOT NULL,
        co_invgr_intrl_ref              DECIMAL(10,0)                   NOT NULL,
        from_bdgt_date                  SMALLDATETIME                   NOT NULL,
        to_bdgt_date                    SMALLDATETIME                   NOT NULL,
        from_grant_date                 SMALLDATETIME                   NOT NULL,
        to_grant_date                   SMALLDATETIME                   NOT NULL,
        from_prjct_date                 SMALLDATETIME                   NOT NULL,
        to_prjct_date                   SMALLDATETIME                   NOT NULL,
        asset_lctn_code                 CHAR(6)                         NOT NULL,
        roll_bdgt_ind                   CHAR(1)                         NOT NULL,
        tax_ind                         CHAR(1)                         NOT NULL,
        ar_acct_id_digt_one             CHAR(1)                         NOT NULL,
        ar_acct_id_last_nine            VARCHAR(9)                      NOT NULL,
        fund_type_code                  CHAR(2)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        fund_table_id                   DECIMAL(10,0)                   NOT NULL,
        base_ucsd_award_number      VARCHAR(8)                         NULL,
        agency_code                 VARCHAR(9)                         NULL,
        agency_name                 VARCHAR(35)                        NULL,
        manager_employee_id         VARCHAR(9)                         NULL,
        manager_name                VARCHAR(35)                        NULL,
        investigator_employee_id    VARCHAR(9)                         NULL,
        investigator_name           VARCHAR(35)                        NULL,
        co_investigator_name        VARCHAR(35)                        NULL,
        co_investigator_id          VARCHAR(9)                         NULL,
        sponsor_award_number        VARCHAR(20)                        NULL,
        grant_contract_number       VARCHAR(20)                        NULL,
        budget_treatment_code       CHAR(4)                            NULL,
        deficit_bal_report_code     CHAR(2)                            NULL,
        deficit_bal_report_descr    VARCHAR(35)                        NULL,
        from_award_fin_date         DATETIME2                          NULL,
        to_award_fin_date           DATETIME2                          NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX8 ON coa_db.fund_table(unvrs_code,coa_code,fund_code,[start_date],[status],data_entry_ind,fund_type_code)
    CREATE INDEX NC_INDEX_16 ON coa_db.fund_table(agncy_intrl_ref_id)
    CREATE INDEX NC_INDEX_25 ON coa_db.fund_table(invgr_intrl_ref)
    CREATE INDEX NC_INDEX_31 ON coa_db.fund_table(co_invgr_intrl_ref)
    CREATE INDEX NC_INDEX_41 ON coa_db.fund_table(fund_code)
    CREATE INDEX NC_INDEX_5 ON coa_db.fund_table(fund_type_code)
    CREATE UNIQUE INDEX SQL120323221903530 ON coa_db.fund_table(fund_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.accttype_table'
BEGIN TRY
    CREATE TABLE coa_db.accttype_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        acct_type_code                  CHAR(2)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        acct_type_title                 VARCHAR(35)                     NOT NULL,
        pred_acct_type_code             CHAR(2)                         NOT NULL,
        sbrdt_acct_type_code            CHAR(2)                         NOT NULL,
        intrl_acct_type_code            CHAR(2)                         NOT NULL,
        nrml_bal_ind                    CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        accttype_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX8 ON coa_db.accttype_table(unvrs_code,coa_code,acct_type_code,[start_date])
    CREATE UNIQUE INDEX SQL120323221903530 ON coa_db.accttype_table(accttype_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.acct_table'
BEGIN TRY
    CREATE TABLE coa_db.acct_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        acct_code                       CHAR(6)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        acct_code_title                 VARCHAR(35)                     NOT NULL,
        pred_acct_code                  CHAR(6)                         NOT NULL,
        data_entry_ind                  CHAR(1)                         NOT NULL,
        asset_acct                      CHAR(6)                         NOT NULL,
        pool_acct                       CHAR(6)                         NOT NULL,
        frng_acct                       CHAR(6)                         NOT NULL,
        frng_pct                        DECIMAL(7,4)                    NOT NULL,
        incm_type_seq_nmbr              SMALLINT                        NOT NULL,
        acct_type_code                  CHAR(2)                         NOT NULL,
        nrml_bal_ind                    CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        acct_table_id                   DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX ON coa_db.acct_table(unvrs_code,coa_code,acct_code,[start_date],[status],data_entry_ind,acct_type_code)
    CREATE INDEX NC_INDEX_1 ON coa_db.acct_table(acct_code)
    CREATE INDEX NC_INDEX_2 ON coa_db.acct_table(acct_type_code,acct_code)
    CREATE UNIQUE INDEX SQL120323221859050 ON coa_db.acct_table(acct_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.lctn_table'
BEGIN TRY
    CREATE TABLE coa_db.lctn_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        lctn_code                       CHAR(6)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        lctn_title                      VARCHAR(35)                     NOT NULL,
        pred_lctn_code                  CHAR(6)                         NOT NULL,
        addr_line1                      VARCHAR(35)                     NOT NULL,
        addr_line2                      VARCHAR(35)                     NOT NULL,
        addr_line3                      VARCHAR(35)                     NOT NULL,
        city_name                       VARCHAR(35)                     NOT NULL,
        state_code                      CHAR(2)                         NOT NULL,
        zip_code                        VARCHAR(10)                     NOT NULL,
        county_code                     VARCHAR(4)                      NOT NULL,
        country_code                    CHAR(2)                         NOT NULL,
        tlphn_area_code                 VARCHAR(3)                      NOT NULL,
        tlphn_xchng_id                  VARCHAR(3)                      NOT NULL,
        tlphn_seq_id                    SMALLINT                        NOT NULL,
        tlphn_xtnsn_id                  VARCHAR(4)                      NOT NULL,
        sqr_ftge                        DECIMAL(6,0)                    NOT NULL,
        sqr_ftge_rate                   DECIMAL(8,2)                    NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        lctn_table_id                   DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX16 ON coa_db.lctn_table(unvrs_code,coa_code,lctn_code,[start_date],[status])
    CREATE UNIQUE INDEX SQL120323221909420 ON coa_db.lctn_table(lctn_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.orgn_table'
BEGIN TRY
    CREATE TABLE coa_db.orgn_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        orgn_code                       CHAR(6)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        orgn_code_title                 VARCHAR(35)                     NOT NULL,
        pred_orgn_code                  CHAR(6)                         NOT NULL,
        data_entry_ind                  CHAR(1)                         NOT NULL,
        dflt_fund_code                  CHAR(6)                         NOT NULL,
        dflt_prog_code                  CHAR(6)                         NOT NULL,
        dftl_actv_code                  CHAR(6)                         NOT NULL,
        dflt_lctn_code                  CHAR(6)                         NOT NULL,
        cmbnd_cntrl_ind                 CHAR(1)                         NOT NULL,
        bdgt_cntrl_orgn                 CHAR(6)                         NOT NULL,
        encmbr_plcy_ind                 CHAR(2)                         NOT NULL,
        mgr_intrl_ref_id                DECIMAL(10,0)                   NOT NULL,
        encmbr_ldgr_ind                 CHAR(1)                         NOT NULL,
        encmbr_ldgr_user                VARCHAR(8)                      NOT NULL,
        oper_ldgr_ind                   CHAR(1)                         NOT NULL,
        oper_ldgr_user                  VARCHAR(8)                      NOT NULL,
        dept_lvl_ind                    CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        orgn_table_id                   DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX18 ON coa_db.orgn_table(unvrs_code,coa_code,orgn_code,[start_date],[status],data_entry_ind)
    CREATE INDEX NC_INDEX_113 ON coa_db.orgn_table(orgn_code)
    CREATE UNIQUE INDEX SQL120323221911640 ON coa_db.orgn_table(orgn_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.prog_table'
BEGIN TRY
    CREATE TABLE coa_db.prog_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        prog_code                       CHAR(6)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        prog_code_title                 VARCHAR(35)                     NOT NULL,
        pred_prog_code                  CHAR(6)                         NOT NULL,
        data_entry_ind                  CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        prog_table_id                   DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX20 ON coa_db.prog_table(unvrs_code,coa_code,prog_code,[start_date],[status],data_entry_ind)
    CREATE INDEX NC_INDEX_116 ON coa_db.prog_table(prog_code)
    CREATE UNIQUE INDEX SQL120323221913590 ON coa_db.prog_table(prog_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fundhier_table'
BEGIN TRY
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
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.proghier_table'
BEGIN TRY
    CREATE TABLE coa_db.proghier_table
    (
        prog_code                       CHAR(6)                         NOT NULL,
        [top]                           CHAR(1)                         NOT NULL,
        bottom                          CHAR(1)                         NOT NULL,
        code_level                      SMALLINT                        NOT NULL,
        code_1                          CHAR(6)                         NOT NULL,
        code_2                          CHAR(6)                         NOT NULL,
        code_3                          CHAR(6)                         NOT NULL,
        code_4                          CHAR(6)                         NOT NULL,
        code_5                          CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        proghier_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX21 ON coa_db.proghier_table(prog_code)
    CREATE INDEX NC_INDEX_117 ON coa_db.proghier_table(code_1)
    CREATE INDEX NC_INDEX_214 ON coa_db.proghier_table(code_2)
    CREATE INDEX NC_INDEX_36 ON coa_db.proghier_table(code_3)
    CREATE INDEX NC_INDEX_46 ON coa_db.proghier_table(code_level,prog_code)
    CREATE UNIQUE INDEX SQL120323221914100 ON coa_db.proghier_table(proghier_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.lctnhier_table'
BEGIN TRY
    CREATE TABLE coa_db.lctnhier_table
    (
        lctn_code                       CHAR(6)                         NOT NULL,
        [top]                           CHAR(1)                         NOT NULL,
        bottom                          CHAR(1)                         NOT NULL,
        code_level                      SMALLINT                        NOT NULL,
        code_1                          CHAR(6)                         NOT NULL,
        code_2                          CHAR(6)                         NOT NULL,
        code_3                          CHAR(6)                         NOT NULL,
        code_4                          CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        lctnhier_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX17 ON coa_db.lctnhier_table(lctn_code)
    CREATE INDEX NC_INDEX_112 ON coa_db.lctnhier_table(code_1)
    CREATE INDEX NC_INDEX_211 ON coa_db.lctnhier_table(code_2)
    CREATE INDEX NC_INDEX_34 ON coa_db.lctnhier_table(code_3)
    CREATE INDEX NC_INDEX_44 ON coa_db.lctnhier_table(code_level,lctn_code)
    CREATE UNIQUE INDEX SQL120323221909850 ON coa_db.lctnhier_table(lctnhier_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.accthier_table'
BEGIN TRY
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
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.orgnhier_table'
BEGIN TRY
    CREATE TABLE coa_db.orgnhier_table
    (
        orgn_code                       CHAR(6)                         NOT NULL,
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
        orgnhier_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX19 ON coa_db.orgnhier_table(orgn_code)
    CREATE INDEX IDX008130417480000 ON coa_db.orgnhier_table(orgn_code,code_3,code_2,code_1)
    CREATE INDEX NC_INDEX_114 ON coa_db.orgnhier_table(code_1)
    CREATE INDEX NC_INDEX_212 ON coa_db.orgnhier_table(code_2)
    CREATE INDEX NC_INDEX_35 ON coa_db.orgnhier_table(code_3)
    CREATE INDEX NC_INDEX_45 ON coa_db.orgnhier_table(code_4)
    CREATE INDEX NC_INDEX_53 ON coa_db.orgnhier_table(code_level,orgn_code)
    CREATE UNIQUE INDEX SQL120323221912100 ON coa_db.orgnhier_table(orgnhier_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.rule_edits_table'
BEGIN TRY
    CREATE TABLE coa_db.rule_edits_table
    (
        rule_efctv_key                  DECIMAL(11,0)                   NOT NULL,
        unvrs_code                      CHAR(2)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        seq_nmbr                        SMALLINT                        NOT NULL,
        edit_code                       VARCHAR(4)                      NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        error_svrty_ind                 CHAR(1)                         NOT NULL,
        cntnu_error_ind                 CHAR(1)                         NOT NULL,
        error_msg                       VARCHAR(39)                     NOT NULL,
        oper                            VARCHAR(3)                      NOT NULL,
        ltrl_field_1                    VARCHAR(30)                     NOT NULL,
        ltrl_field_2                    VARCHAR(30)                     NOT NULL,
        elmnt_name                      VARCHAR(30)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rule_edits_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_RULE_EFCTV_KEY ON coa_db.rule_edits_table(rule_efctv_key,rule_class_code,edit_code)
    CREATE INDEX NC_INDEX_120 ON coa_db.rule_edits_table(unvrs_code,rule_class_code,seq_nmbr)
    CREATE INDEX NC_INDEX_216 ON coa_db.rule_edits_table(rule_efctv_key)
    CREATE UNIQUE INDEX SQL120323221916350 ON coa_db.rule_edits_table(rule_edits_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.rule_actns_table'
BEGIN TRY
    CREATE TABLE coa_db.rule_actns_table
    (
        rule_efctv_key                  DECIMAL(11,0)                   NOT NULL,
        unvrs_code                      CHAR(2)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        seq_nmbr                        SMALLINT                        NOT NULL,
        proc_code                       VARCHAR(4)                      NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        pstng_actn_ind                  CHAR(1)                         NOT NULL,
        acrl_impact_ind                 CHAR(1)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        index_code                      CHAR(10)                        NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        orgn_code                       CHAR(6)                         NOT NULL,
        acct_code                       CHAR(6)                         NOT NULL,
        prog_code                       CHAR(6)                         NOT NULL,
        actv_code                       CHAR(6)                         NOT NULL,
        lctn_code                       CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rule_actns_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_118 ON coa_db.rule_actns_table(unvrs_code,rule_class_code,seq_nmbr)
    CREATE INDEX NC_INDEX_215 ON coa_db.rule_actns_table(rule_efctv_key)
    CREATE UNIQUE INDEX SQL120323221912100 ON coa_db.rule_actns_table(rule_actns_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.rule_efctv_table'
BEGIN TRY
    CREATE TABLE coa_db.rule_efctv_table
    (
        rule_class_key                  DECIMAL(11,0)                   NOT NULL,
        rule_efctv_key                  DECIMAL(11,0)                   NOT NULL,
        unvrs_code                      CHAR(2)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        rule_class_desc                 VARCHAR(35)                     NOT NULL,
        rule_class_type                 CHAR(1)                         NOT NULL,
        rsrv_bdgt_ind                   CHAR(1)                         NOT NULL,
        bal_mthd_ind                    CHAR(1)                         NOT NULL,
        cmplt_ind                       CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rule_efctv_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX23 ON coa_db.rule_efctv_table(unvrs_code,rule_class_code,[start_date],[status])
    CREATE INDEX I_RULE_CLASS_CODE ON coa_db.rule_efctv_table(rule_class_code,[start_date])
    CREATE INDEX I_STATUS ON coa_db.rule_efctv_table([status],rule_class_code,[start_date],rule_efctv_key)
    CREATE INDEX NC_INDEX_121 ON coa_db.rule_efctv_table(rule_class_key)
    CREATE INDEX NC_INDEX_217 ON coa_db.rule_efctv_table(rule_efctv_key)
    CREATE UNIQUE INDEX SQL120323221916820 ON coa_db.rule_efctv_table(rule_efctv_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.rule_class_table'
BEGIN TRY
    CREATE TABLE coa_db.rule_class_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        actvy_date                      SMALLDATETIME                   NOT NULL,
        rule_class_key                  DECIMAL(11,0)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rule_class_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX22 ON coa_db.rule_class_table(unvrs_code,rule_class_code)
    CREATE INDEX NC_INDEX_119 ON coa_db.rule_class_table(rule_class_key)
    CREATE UNIQUE INDEX SQL120323221915900 ON coa_db.rule_class_table(rule_class_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fiscal_year_table'
BEGIN TRY
    CREATE TABLE coa_db.fiscal_year_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        full_fscl_yr                    CHAR(4)                         NOT NULL,
        fscl_yr                         CHAR(2)                         NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        nmbr_of_prds                    DECIMAL(2,0)                    NOT NULL,
        fscl_yr_start_date              SMALLDATETIME                   NOT NULL,
        fscl_yr_end_date                SMALLDATETIME                   NOT NULL,
        acrl_prd_status                 CHAR(1)                         NOT NULL,
        prd_0_purge_flag                CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        fiscal_year_table_id            DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_14 ON coa_db.fiscal_year_table(full_fscl_yr)
    CREATE INDEX NC_INDEX_23 ON coa_db.fiscal_year_table(unvrs_code,coa_code,fscl_yr,acrl_prd_status)
    CREATE UNIQUE INDEX SQL120323221901700 ON coa_db.fiscal_year_table(fiscal_year_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.period_table'
BEGIN TRY
    CREATE TABLE coa_db.period_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        fscl_yr                         CHAR(2)                         NOT NULL,
        prd                             CHAR(2)                         NOT NULL,
        prd_start_date                  SMALLDATETIME                       NULL,
        prd_end_date                    SMALLDATETIME                       NULL,
        prd_status                      CHAR(1)                         NOT NULL,
        end_of_qtr_ind                  CHAR(1)                         NOT NULL,
        prd_purge_flag                  CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        period_table_id                 DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_115 ON coa_db.period_table(unvrs_code,coa_code,prd_start_date,prd_status,fscl_yr)
    CREATE INDEX NC_INDEX_213 ON coa_db.period_table(full_accounting_period)
    CREATE UNIQUE INDEX SQL120323221912640 ON coa_db.period_table(period_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.project'
BEGIN TRY
    CREATE TABLE coa_db.project
    (
        project_key                 INTEGER                        NOT NULL,
        project                     CHAR(35)                       NOT NULL,
        most_recent_flag            CHAR(1)                        NOT NULL,
        start_effective_date        DATETIME2                          NULL,
        end_effective_date          DATETIME2                      NOT NULL,
        project_title               VARCHAR(35)                    NOT NULL,
        date_entered                DATETIME2                      NOT NULL,
        project_last_run            DATETIME2                      NOT NULL,
        refresh_date                DATETIME2                      NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_PROJECT ON coa_db.project(project,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323231705190 ON coa_db.project(project_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.project_index'
BEGIN TRY
    CREATE TABLE coa_db.project_index
    (
        project_key                 INTEGER                        NOT NULL,
        indx_key                    INTEGER                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_PROJINDX ON coa_db.project_index(project_key,indx_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.code_lookup'
BEGIN TRY
    CREATE TABLE coa_db.code_lookup
    (
        code_type                       VARCHAR(25)                      NOT NULL,
        code                            VARCHAR(10)                     NOT NULL,
        short_description               VARCHAR(10)                     NOT NULL,
        long_description                VARCHAR(255)                    NOT NULL,
        active_flag                     CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CODE_TYPE ON coa_db.code_lookup(code_type)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.date'
BEGIN TRY
    CREATE TABLE coa_db.[date]
    (
        date_key                        INTEGER                         NOT NULL,
        [date]                          DATETIME2                       NOT NULL,
        special_fiscal_period_flag      CHAR(1)                         NOT NULL,
        day_of_week                     SMALLINT                        NOT NULL,
        day_num_in_month                INTEGER                         NOT NULL,
        day_num_overall                 INTEGER                         NOT NULL,
        day_name                        CHAR(10)                        NOT NULL,
        day_abbrev                      CHAR(3)                         NOT NULL,
        weekday_flag                    CHAR(1)                         NOT NULL,
        week_num_in_year                SMALLINT                        NOT NULL,
        week_num_overall                INTEGER                         NOT NULL,
        week_begin_date                 SMALLDATETIME                   NOT NULL,
        week_begin_date_key             INTEGER                         NOT NULL,
        month_num                       SMALLINT                        NOT NULL,
        month_num_overall               INTEGER                         NOT NULL,
        month_name                      CHAR(10)                        NOT NULL,
        month_abbrev                    CHAR(3)                         NOT NULL,
        cal_quarter                     SMALLINT                        NOT NULL,
        cal_year                        INTEGER                         NOT NULL,
        cal_year_month                  INTEGER                         NOT NULL,
        fiscal_month                    SMALLINT                        NOT NULL,
        fiscal_quarter                  SMALLINT                        NOT NULL,
        fiscal_year                     INTEGER                         NOT NULL,
        fiscal_period                   INTEGER                         NOT NULL,
        last_day_in_month_flag          CHAR(1)                         NOT NULL,
        same_weekday_year_ago           DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX DATE_FISCAL_PERIOD_LAST_DAY_IN_MONTH_FLAG ON coa_db.[date](fiscal_period,last_day_in_month_flag)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fund'
BEGIN TRY
    CREATE TABLE coa_db.fund
    (
        fund_key                        INTEGER                         NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        fund_title                      VARCHAR(35)                     NOT NULL,
        predecessor_fund                CHAR(6)                         NOT NULL,
        predecessor_fund_title          VARCHAR(35)                     NOT NULL,
        fed_demo_proj_ind               CHAR(1)                         NOT NULL,
        revenue_account                 CHAR(6)                         NOT NULL,
        accrual_account                 CHAR(6)                         NOT NULL,
        bank_account_code               CHAR(2)                         NOT NULL,
        bank_account                    VARCHAR(35)                     NOT NULL,
        project_auth_amt                DECIMAL(19,4)                   NOT NULL,
        agency_award_number             VARCHAR(22)                     NOT NULL,
        phs_payment_mgmt_id             CHAR(15)                        NOT NULL,
        report_cycle_code               CHAR(1)                         NOT NULL,
        report_cycle                    VARCHAR(35)                     NOT NULL,
        billing_format_code             CHAR(1)                         NOT NULL,
        billing_format                  VARCHAR(35)                     NOT NULL,
        budgeted_funding_amt            DECIMAL(19,4)                   NOT NULL,
        payment_method_code             CHAR(4)                         NOT NULL,
        payment_method                  VARCHAR(35)                     NOT NULL,
        grant_cost_share_code           CHAR(6)                         NOT NULL,
        grant_cost_share                VARCHAR(35)                     NOT NULL,
        grant_cost_share_amt            DECIMAL(19,4)                   NOT NULL,
        grant_indirect_cost_cd          CHAR(6)                         NOT NULL,
        grant_indirect_cost             VARCHAR(35)                     NOT NULL,
        sponsor_code                    CHAR(9)                         NOT NULL,
        sponsor                         VARCHAR(35)                     NOT NULL,
        from_budget_date                DATETIME2                       NOT NULL,
        to_budget_date                  SMALLDATETIME                   NOT NULL,
        from_award_date                 SMALLDATETIME                   NOT NULL,
        to_award_date                   SMALLDATETIME                   NOT NULL,
        fund_type_code                  CHAR(2)                         NOT NULL,
        fund_type                       CHAR(2)                         NOT NULL,
        ucop_fund_number                CHAR(5)                             NULL,
        ucop_fund_name                  VARCHAR(35)                     NOT NULL,
        fund_restriction_code           CHAR(1)                         NOT NULL,
        fund_restriction                CHAR(12)                        NOT NULL,
        method_of_payment_code          CHAR(2)                         NOT NULL,
        method_of_payment               VARCHAR(250)                    NOT NULL,
        endowment_restriction_code      CHAR(5)                         NOT NULL,
        endowment_restriction           VARCHAR(250)                    NOT NULL,
        endowment_purpose               VARCHAR(250)                    NOT NULL,
        ucop_sponsor_code               CHAR(4)                         NOT NULL,
        sponsor_category_code           INTEGER                         NOT NULL,
        sponsor_category                VARCHAR(90)                     NOT NULL,
        type_of_award_code              CHAR(1)                         NOT NULL,
        type_of_award                   VARCHAR(75)                     NOT NULL,
        on_off_campus_code              CHAR(1)                         NOT NULL,
        on_off_campus                   VARCHAR(20)                     NOT NULL,
        federal_flow_through_code       CHAR(1)                         NOT NULL,
        federal_flow_through            VARCHAR(120)                    NOT NULL,
        fund_group_code                 CHAR(6)                         NOT NULL,
        indirect_cost_rate              DECIMAL(10,6)                   NOT NULL,
        indirect_cost_base_code         CHAR(1)                         NOT NULL,
        indirect_cost_base              VARCHAR(57)                     NOT NULL,
        ifis_index                      CHAR(10)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        base_ucsd_award_number      VARCHAR(8)                         NULL,
        grant_contract_number       VARCHAR(20)                        NULL,
        budget_treatment_code       CHAR(4)                            NULL,
        deficit_bal_report_code     CHAR(2)                            NULL,
        deficit_bal_report_descr    VARCHAR(35)                        NULL,
        from_award_fin_date         DATETIME2                          NULL,
        to_award_fin_date           DATETIME2                          NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_BASE_AWARD_NUMB1 ON coa_db.fund(base_ucsd_award_number)
    CREATE INDEX I_FUND ON coa_db.fund(fund,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221902700 ON coa_db.fund(fund_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.fund_hierarchy'
BEGIN TRY
    CREATE TABLE coa_db.fund_hierarchy
    (
        parent_fund                     CHAR(6)                         NOT NULL,
        subsidiary_fund                 CHAR(6)                         NOT NULL,
        number_of_levels                SMALLINT                        NOT NULL,
        top_most_flag                   CHAR(1)                         NOT NULL,
        bottom_most_flag                CHAR(1)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX PARENT_FUND ON coa_db.fund_hierarchy(parent_fund)
    CREATE INDEX SUBSIDIARY_FUND ON coa_db.fund_hierarchy(subsidiary_fund)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.indx'
BEGIN TRY
    CREATE TABLE coa_db.indx
    (
        indx_key                        INTEGER                         NOT NULL,
        indx                            CHAR(10)                        NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        indx_title                      VARCHAR(35)                     NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        fund_title                      VARCHAR(35)                     NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        organization_title              VARCHAR(35)                     NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        account_title                   VARCHAR(35)                     NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        program_title                   VARCHAR(35)                     NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        location_title                  VARCHAR(35)                     NOT NULL,
        early_inactivation_date         SMALLDATETIME                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT2 ON coa_db.indx(account,most_recent_flag)
    CREATE INDEX I_FUND1 ON coa_db.indx(fund,most_recent_flag)
    CREATE INDEX I_INDX ON coa_db.indx(indx,most_recent_flag)
    CREATE INDEX I_ORGANIZATION ON coa_db.indx(organization,most_recent_flag)
    CREATE INDEX I_PROGRAM ON coa_db.indx(program,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221907660 ON coa_db.indx(indx_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.lctn_hierarchy'
BEGIN TRY
    CREATE TABLE coa_db.lctn_hierarchy
    (
        parent_lctn                     CHAR(6)                         NOT NULL,
        subsidiary_lctn                 CHAR(6)                         NOT NULL,
        number_of_levels                SMALLINT                        NOT NULL,
        top_most_flag                   CHAR(1)                         NOT NULL,
        bottom_most_flag                CHAR(1)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX PARENT_LCTN ON coa_db.lctn_hierarchy(parent_lctn)
    CREATE INDEX SUBSIDIARY_LCTN ON coa_db.lctn_hierarchy(subsidiary_lctn)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.location'
BEGIN TRY
    CREATE TABLE coa_db.location
    (
        location_key                    INTEGER                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        location_title                  VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_LOCATION ON coa_db.location(location,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221910330 ON coa_db.location(location_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.month'
BEGIN TRY
    CREATE TABLE coa_db.month
    (
        month_key                       INTEGER                         NOT NULL,
        month_end_date                  DATETIME2                       NOT NULL,
        special_fiscal_period_flag      CHAR(1)                         NOT NULL,
        month_num                       SMALLINT                        NOT NULL,
        month_num_overall               INTEGER                         NOT NULL,
        month_name                      CHAR(10)                        NOT NULL,
        month_abbrev                    CHAR(3)                         NOT NULL,
        cal_quarter                     SMALLINT                        NOT NULL,
        cal_year                        INTEGER                         NOT NULL,
        cal_year_month                  INTEGER                         NOT NULL,
        fiscal_month                    SMALLINT                        NOT NULL,
        fiscal_quarter                  SMALLINT                        NOT NULL,
        fiscal_year                     INTEGER                         NOT NULL,
        fiscal_year_month               INTEGER                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.org_hierarchy'
BEGIN TRY
    CREATE TABLE coa_db.org_hierarchy
    (
        parent_org                      CHAR(6)                         NOT NULL,
        subsidiary_org                  CHAR(6)                         NOT NULL,
        number_of_levels                SMALLINT                        NOT NULL,
        top_most_flag                   CHAR(1)                         NOT NULL,
        bottom_most_flag                CHAR(1)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX PARENT_ORG ON coa_db.org_hierarchy(parent_org)
    CREATE INDEX SUBSIDIARY_ORG ON coa_db.org_hierarchy(subsidiary_org)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.organization'
BEGIN TRY
    CREATE TABLE coa_db.organization
    (
        organization_key                INTEGER                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        organization_title              VARCHAR(35)                     NOT NULL,
        department_level_ind            CHAR(10)                        NOT NULL,
        manager_pid                     CHAR(9)                         NOT NULL,
        manager_int_ref_id              DECIMAL(10,0)                   NOT NULL,
        manager_name                    VARCHAR(35)                     NOT NULL,
        manager_mail_code               CHAR(6)                         NOT NULL,
        org_hierarchy_level1            CHAR(6)                         NOT NULL,
        ucop_account_number             CHAR(6)                         NOT NULL,
        ucop_account_name               VARCHAR(35)                     NOT NULL,
        annual_report_code              CHAR(6)                         NOT NULL,
        uniform_acctg_str_cd            CHAR(6)                         NOT NULL,
        academic_discipline_cd          CHAR(3)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ORGANIZATION1 ON coa_db.organization(organization,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221911190 ON coa_db.organization(organization_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.prog_hierarchy'
BEGIN TRY
    CREATE TABLE coa_db.prog_hierarchy
    (
        parent_prog                     CHAR(6)                         NOT NULL,
        subsidiary_prog                 CHAR(6)                         NOT NULL,
        number_of_levels                SMALLINT                        NOT NULL,
        top_most_flag                   CHAR(1)                         NOT NULL,
        bottom_most_flag                CHAR(1)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX PARENT_PROG ON coa_db.prog_hierarchy(parent_prog)
    CREATE INDEX SUBSIDIARY_PROG ON coa_db.prog_hierarchy(subsidiary_prog)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.program'
BEGIN TRY
    CREATE TABLE coa_db.program
    (
        program_key                     INTEGER                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        program_title                   VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_PROGRAM1 ON coa_db.program(program,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221914620 ON coa_db.program(program_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.account'
BEGIN TRY
    CREATE TABLE coa_db.account
    (
        account_key                     INTEGER                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        start_effective_date            DATETIME2                           NULL,
        end_effective_date              DATETIME2                       NOT NULL,
        last_activity_date              SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        account_title                   VARCHAR(35)                     NOT NULL,
        sub_account_code                CHAR(6)                         NOT NULL,
        sub_account                     VARCHAR(35)                     NOT NULL,
        pool_account                    CHAR(6)                         NOT NULL,
        account_type_code               CHAR(2)                         NOT NULL,
        account_type                    CHAR(2)                         NOT NULL,
        normal_balance_ind              CHAR(1)                         NOT NULL,
        normal_balance                  CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT ON coa_db.account(account,most_recent_flag)
    CREATE UNIQUE INDEX SQL120323221857310 ON coa_db.account(account_key)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.acct_hierarchy'
BEGIN TRY
    CREATE TABLE coa_db.acct_hierarchy
    (
        parent_acct                     CHAR(6)                         NOT NULL,
        subsidiary_acct                 CHAR(6)                         NOT NULL,
        number_of_levels                SMALLINT                        NOT NULL,
        top_most_flag                   CHAR(1)                         NOT NULL,
        bottom_most_flag                CHAR(1)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX PARENT_ACCT ON coa_db.acct_hierarchy(parent_acct)
    CREATE INDEX SUBSIDIARY_ACCT ON coa_db.acct_hierarchy(subsidiary_acct)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.actv_table'
BEGIN TRY
    CREATE TABLE coa_db.actv_table
    (
        unvrs_code                      CHAR(2)                             NULL,
        coa_code                        CHAR(1)                             NULL,
        actv_code                       CHAR(6)                             NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                       NULL,
        [status]                        CHAR(1)                             NULL,
        user_code                       VARCHAR(8)                          NULL,
        actv_code_title                 VARCHAR(35)                         NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        actv_table_id                   DECIMAL(10,0)                       NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX3 ON coa_db.actv_table(unvrs_code,coa_code,actv_code,[start_date],[status])
    CREATE UNIQUE INDEX SQL120323221859450 ON coa_db.actv_table(actv_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.coa_table'
BEGIN TRY
    CREATE TABLE coa_db.coa_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        coa_code_title                  VARCHAR(35)                     NOT NULL,
        fdrl_emplr_id                   VARCHAR(9)                      NOT NULL,
        actg_mthd                       CHAR(1)                         NOT NULL,
        fscl_yr_start_prd               VARCHAR(4)                      NOT NULL,
        fscl_yr_end_prd                 VARCHAR(4)                      NOT NULL,
        indx_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        fund_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        orgn_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        acct_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        prog_bdgt_cntrl                 CHAR(1)                         NOT NULL,
        cntrl_prd_code                  CHAR(1)                         NOT NULL,
        cntrl_svrty_code                CHAR(1)                         NOT NULL,
        encmbr_jrnl_type                VARCHAR(4)                      NOT NULL,
        cmtmnt_type                     CHAR(1)                         NOT NULL,
        roll_bdgt_ind                   CHAR(1)                         NOT NULL,
        bdgt_dspsn                      CHAR(1)                         NOT NULL,
        encmbr_pct                      DECIMAL(7,4)                    NOT NULL,
        bdgt_jrnl_type                  VARCHAR(4)                      NOT NULL,
        bdgt_clsfn                      CHAR(1)                         NOT NULL,
        carry_frwrd_type                CHAR(1)                         NOT NULL,
        bdgt_pct                        DECIMAL(7,4)                    NOT NULL,
        due_to_acct_code                CHAR(6)                         NOT NULL,
        due_from_acct_code              CHAR(6)                         NOT NULL,
        fund_bal_acct_code              CHAR(6)                         NOT NULL,
        ap_acrl_acct_code               CHAR(6)                         NOT NULL,
        ar_acrl_acct_code               CHAR(6)                         NOT NULL,
        close_ldgr_rule                 VARCHAR(4)                      NOT NULL,
        roll_encmbr_ind                 CHAR(1)                         NOT NULL,
        roll_po_ind                     CHAR(1)                         NOT NULL,
        roll_memo_ind                   CHAR(1)                         NOT NULL,
        roll_rqst_ind                   CHAR(1)                         NOT NULL,
        roll_labor_encmbr_ind           CHAR(1)                         NOT NULL,
        cmplt_ind                       CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        coa_table_id                    DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX6 ON coa_db.coa_table(unvrs_code,coa_code,[start_date],[status])
    CREATE UNIQUE INDEX SQL120323221900870 ON coa_db.coa_table(coa_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.excluded_funds'
BEGIN TRY
    CREATE TABLE coa_db.excluded_funds
    (
        fund_code                       CHAR(6)                         NOT NULL,
        ucop_fund_number                CHAR(5)                             NULL,
        fund_title                      VARCHAR(35)                     NOT NULL,
        fund_group_code                 CHAR(6)                         NOT NULL,
        date_added                      SMALLDATETIME                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_EXCL_FUNDS1 ON coa_db.excluded_funds(fund_code)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.foap_valid_table'
BEGIN TRY
    CREATE TABLE coa_db.foap_valid_table
    (
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        foap_valid_type                 VARCHAR(4)                      NOT NULL,
        fund_code                       CHAR(6)                         NOT NULL,
        orgn_code                       CHAR(6)                         NOT NULL,
        acct_code                       CHAR(6)                         NOT NULL,
        prog_code                       CHAR(6)                         NOT NULL,
        accttype_code                   CHAR(2)                         NOT NULL,
        fundtype_code                   CHAR(2)                         NOT NULL,
        [status]                        CHAR(1)                         NOT NULL,
        foap_val_inval_ind              CHAR(1)                         NOT NULL,
        foap_edit_type                  CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        foap_valid_table_id             DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE CLUSTERED INDEX C_INDEX7 ON coa_db.foap_valid_table(unvrs_code,coa_code,foap_valid_type,fund_code,orgn_code,acct_code,prog_code,accttype_code,fundtype_code)
    CREATE INDEX NC_INDEX_15 ON coa_db.foap_valid_table(fund_code)
    CREATE INDEX NC_INDEX_24 ON coa_db.foap_valid_table(acct_code)
    CREATE UNIQUE INDEX SQL120323221902140 ON coa_db.foap_valid_table(foap_valid_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.idchxtrn_table'
BEGIN TRY
    CREATE TABLE coa_db.idchxtrn_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        external_entity_code            VARCHAR(4)                      NOT NULL,
        external_entity_desc            VARCHAR(35)                     NOT NULL,
        external_code                   VARCHAR(10)                     NOT NULL,
        external_code_desc              VARCHAR(35)                     NOT NULL,
        extrnl_last_activity_date       SMALLDATETIME                   NOT NULL,
        internal_entity_code            VARCHAR(4)                      NOT NULL,
        internal_entity_desc            VARCHAR(35)                     NOT NULL,
        internal_code                   VARCHAR(10)                     NOT NULL,
        intrnl_last_activity_date       SMALLDATETIME                   NOT NULL,
        external_entity_crss_cd         VARCHAR(4)                      NOT NULL,
        internal_entity_crss_cd         VARCHAR(4)                      NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        idchxtrn_table_id               DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_18 ON coa_db.idchxtrn_table(external_code)
    CREATE INDEX NC_INDEX_27 ON coa_db.idchxtrn_table(internal_code)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.sysdata_table'
BEGIN TRY
    CREATE TABLE coa_db.sysdata_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        fims_entity_code                CHAR(8)                         NOT NULL,
        element_name                    VARCHAR(30)                     NOT NULL,
        coa_code                        CHAR(1)                         NOT NULL,
        optn_1_code                     CHAR(8)                         NOT NULL,
        optn_2_code                     CHAR(8)                         NOT NULL,
        level_nmbr                      DECIMAL(2,0)                    NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        long_desc                       VARCHAR(35)                     NOT NULL,
        short_desc                      VARCHAR(20)                     NOT NULL,
        data_desc                       VARCHAR(15)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        sysdata_table_id                DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX NC_INDEX_122 ON coa_db.sysdata_table(unvrs_code,fims_entity_code,element_name,coa_code,optn_1_code,optn_2_code,level_nmbr)
    CREATE UNIQUE INDEX SQL120323221917340 ON coa_db.sysdata_table(sysdata_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.ucop_fund_distinct'
BEGIN TRY
    CREATE TABLE coa_db.ucop_fund_distinct
    (
        ucop_fund_number                CHAR(5)                          NULL,
        budgeted_fund_code              CHAR(1)                             NULL,
        fund_restriction_code           CHAR(1)                             NULL,
        method_of_payment               VARCHAR(250)                        NULL,
        endowment_restriction_code      CHAR(5)                             NULL,
        sponsor_code                    CHAR(9)                             NULL,
        sponsor_category_code           INTEGER                             NULL,
        type_of_award_code              CHAR(1)                             NULL,
        on_off_campus_code              CHAR(1)                             NULL,
        federal_flow_through_code       CHAR(1)                             NULL,
        fund_group_code                 CHAR(6)                             NULL,
        indirect_cost_rate              DECIMAL(10,6)                       NULL,
        indirect_cost_base_code         CHAR(1)                             NULL,
        ctlg_fdrl_domestic_asst         VARCHAR(5)                          NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        calendar_year_month             INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_FUND_DISTINCT ON coa_db.ucop_fund_distinct(calendar_year_month,ucop_fund_number,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- coa_db.unvrs_table'
BEGIN TRY
    CREATE TABLE coa_db.unvrs_table
    (
        unvrs_code                      CHAR(2)                         NOT NULL,
        user_code                       VARCHAR(8)                      NOT NULL,
        last_actvy_date                 SMALLDATETIME                   NOT NULL,
        fice_code                       DECIMAL(6,0)                    NOT NULL,
        short_name                      VARCHAR(10)                     NOT NULL,
        full_name                       VARCHAR(35)                     NOT NULL,
        addr_line_1                     VARCHAR(35)                     NOT NULL,
        addr_line_2                     VARCHAR(35)                     NOT NULL,
        addr_line_3                     VARCHAR(35)                     NOT NULL,
        addr_line_4                     VARCHAR(35)                     NOT NULL,
        tlphn_area_code                 VARCHAR(3)                      NOT NULL,
        tlphn_xchng_id                  VARCHAR(3)                      NOT NULL,
        tlphn_seq_id                    SMALLINT                        NOT NULL,
        tlphn_xtnsn_id                  VARCHAR(4)                      NOT NULL,
        city_name                       VARCHAR(35)                     NOT NULL,
        state_code                      CHAR(2)                         NOT NULL,
        zip_code                        VARCHAR(10)                     NOT NULL,
        country_code                    CHAR(2)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        unvrs_table_id                  DECIMAL(10,0)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE UNIQUE INDEX SQL120323221917810 ON coa_db.unvrs_table(unvrs_table_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH