/***************************************************************************************
Name      : BSO Financial Management Interface - GA
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates GA Schema Mirrored to Hopper DW_DB
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

    SET @schemaName = 'ga'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName = 'f_accounting_period'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName = 'f_bud_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 3
    BEGIN
        SET @objectName = 'f_cumulative_balance'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 4
    BEGIN
        SET @objectName = 'f_cumulative_beginning_balance'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 5
    BEGIN
        SET @objectName = 'f_current_prior_activity'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 6
    BEGIN
        SET @objectName = 'f_data_location'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 7
    BEGIN
        SET @objectName = 'f_document_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 8
    BEGIN
        SET @objectName = 'f_el_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 9
    BEGIN
        SET @objectName = 'f_fin_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 10
    BEGIN
        SET @objectName = 'f_general_ledger'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 11
    BEGIN
        SET @objectName = 'f_gl_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 12
    BEGIN
        SET @objectName = 'f_ifoapal'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 13
    BEGIN
        SET @objectName = 'f_ledger_activity'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 14
    BEGIN
        SET @objectName = 'f_ledger_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 15
    BEGIN
        SET @objectName = 'f_ledger_transaction'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 16
    BEGIN
        SET @objectName = 'f_ol_detail_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 17
    BEGIN
        SET @objectName = 'f_operating_ledger'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 18
    BEGIN
        SET @objectName = 'f_operating_ledger_v'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 19
    BEGIN
        SET @objectName = 'f_period_account'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 20
    BEGIN
        SET @objectName = 'f_period_account_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 21
    BEGIN
        SET @objectName = 'f_period_fund'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 22
    BEGIN
        SET @objectName = 'f_period_fund_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 23
    BEGIN
        SET @objectName = 'f_period_index'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 24
    BEGIN
        SET @objectName = 'f_period_location'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 25
    BEGIN
        SET @objectName = 'f_period_organization'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 26
    BEGIN
        SET @objectName = 'f_period_program'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 27
    BEGIN
        SET @objectName = 'f_prior_encumbrance_bal'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 28
    BEGIN
        SET @objectName = 'f_prior_month_balance'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 29
    BEGIN
        SET @objectName = 'f_transaction_type'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 30
    BEGIN
        SET @objectName = 'f_vendor'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 31
    BEGIN
        SET @objectName = 'gl_detail'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 32
    BEGIN
        SET @objectName = 'tf_transfer_detail'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 33
    BEGIN
        SET @objectName = 'tf_transfer_header'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 34
    BEGIN
        SET @objectName = 'tf_transfer_text'
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
CREATE SCHEMA ga;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'UC San Diego General Accounting schema', 
	 @level0type=N'SCHEMA',
	 @level0name=N'ga';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '-- ga.f_accounting_period'
BEGIN TRY
    CREATE TABLE ga.f_accounting_period
    (
        accounting_period               SMALLINT                        NOT NULL,
        ac_status                       CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        calendar_year_month             INTEGER                         NOT NULL,
        period_code                     CHAR(1)                         NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE UNIQUE INDEX SQL130510172303880 ON ga.f_accounting_period(full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_bud_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_bud_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_cumulative_balance'
BEGIN TRY
    CREATE TABLE ga.f_cumulative_balance
    (
        cu_fiscal_year                  SMALLINT                        NOT NULL,
        cu_account_index                CHAR(10)                        NOT NULL,
        cu_fund                         CHAR(6)                         NOT NULL,
        cu_organization                 CHAR(6)                         NOT NULL,
        cu_account                      CHAR(6)                         NOT NULL,
        cu_program                      CHAR(6)                         NOT NULL,
        cu_location                     CHAR(6)                         NOT NULL,
        cu_budget_amount                DECIMAL(19,4)                   NOT NULL,
        cu_financial_amount             DECIMAL(19,4)                   NOT NULL,
        full_fiscal_year                SMALLINT                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CU_ACCT_INDEX ON ga.f_cumulative_balance(cu_account_index,cu_fiscal_year,cu_account)
    CREATE INDEX I_CU_ORGFUND ON ga.f_cumulative_balance(cu_fiscal_year,cu_organization,cu_fund,cu_program)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_cumulative_beginning_balance'
BEGIN TRY
    CREATE TABLE ga.f_cumulative_beginning_balance
    (
        pl_location                     CHAR(6)                         NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        cb_financial_amount             DECIMAL(19,4)                   NOT NULL,
        cb_fiscal_year                  SMALLINT                        NOT NULL,
        full_fiscal_year                SMALLINT                        NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        cb_budget_amount                DECIMAL(19,4)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CUBB_ACCT_INDEX ON ga.f_cumulative_balance(cu_account_index,cu_fiscal_year,cu_account)
    CREATE INDEX I_CUBB_ORGFUND ON ga.f_cumulative_balance(cu_fiscal_year,cu_organization,cu_fund,cu_program)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_current_prior_activity'
BEGIN TRY
    CREATE TABLE ga.f_current_prior_activity
    (
        calendar_year_month             INTEGER                         NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        pl_location                     CHAR(6)                         NOT NULL,
        dt_sequence_number              SMALLINT                        NOT NULL,
        lt_document_number              CHAR(8)                         NOT NULL,
        lt_transaction_date             SMALLDATETIME                   NOT NULL,
        lt_item_number                  SMALLINT                        NOT NULL,
        lt_sequence_number              SMALLINT                        NOT NULL,
        lt_budget_period                SMALLINT                        NOT NULL,
        lt_amount                       DECIMAL(19,4)                   NOT NULL,
        lt_description                  VARCHAR(35)                     NOT NULL,
        lt_document_reference_number    VARCHAR(10)                     NOT NULL,
        lt_debit_credit_indicator       CHAR(1)                         NOT NULL,
        lt_activity_date                DATETIME2                       NOT NULL,
        lt_encumbrance_number           VARCHAR(8)                      NOT NULL,
        lt_encumbrance_action           CHAR(1)                         NOT NULL,
        lt_encumbrance_item             SMALLINT                        NOT NULL,
        lt_encumbrance_sequence         SMALLINT                        NOT NULL,
        lt_encumbrance_type             CHAR(1)                         NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        lt_rule_class_code              CHAR(4)                         NOT NULL,
        lt_encumbrance_doc_type         VARCHAR(3)                      NOT NULL,
        la_ledger_indicator             CHAR(1)                         NOT NULL,
        la_field_indicator              CHAR(2)                         NOT NULL,
        la_amount                       DECIMAL(19,4)                   NOT NULL,
        la_rule_sequence                SMALLINT                        NOT NULL,
        la_process_code                 CHAR(4)                         NOT NULL,
        la_debit_credit                 CHAR(1)                         NOT NULL,
        la_id                           CHAR(12)                        NOT NULL,
        lt_id                           CHAR(12)                        NOT NULL,
        if_id                           CHAR(12)                        NOT NULL,
        ol_id                           CHAR(12)                        NOT NULL,
        gl_id                           CHAR(12)                        NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX IDX_CPACT_1 ON ga.f_current_prior_activity(la_id)
    CREATE INDEX IDX_CPACT_2 ON ga.f_current_prior_activity(calendar_year_month,la_ledger_indicator,la_field_indicator)
    CREATE INDEX IDX_CPACT_3 ON ga.f_current_prior_activity(full_accounting_period,la_ledger_indicator,la_field_indicator)
    CREATE INDEX IDX_CPACT_5 ON ga.f_current_prior_activity(lt_document_number)
    CREATE INDEX IDX_CPACT_6 ON ga.f_current_prior_activity(pi_account_index)
    CREATE INDEX IDX_CPACT_7 ON ga.f_current_prior_activity(calendar_year_month,pf_fund,po_organization,pa_account,pp_program,pl_location)
    CREATE INDEX IDX_CPACT_8 ON ga.f_current_prior_activity(refresh_date)
    CREATE INDEX IDX_CPACT_9 ON ga.f_current_prior_activity(calendar_year_month,po_organization)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_data_location'
BEGIN TRY
    CREATE TABLE ga.f_data_location
    (
        dl_fiscal_year                  SMALLINT                        NOT NULL,
        dl_location                     VARCHAR(30)                     NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_document_type'
BEGIN TRY
    CREATE TABLE ga.f_document_type
    (
        dt_sequence_number              SMALLINT                        NOT NULL,
        dt_document_type                CHAR(3)                         NOT NULL,
        dt_title                        VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX INDX_DOCUMENT_TYP2 ON ga.f_document_type(dt_document_type)
    CREATE UNIQUE INDEX SQL130510203817060 ON ga.f_document_type(dt_sequence_number)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_el_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_el_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_fin_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_fin_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_general_ledger'
BEGIN TRY
    CREATE TABLE ga.f_general_ledger
    (
        gl_id                           CHAR(12)                        NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        gl_activity_date                SMALLDATETIME                   NOT NULL,
        gl_debits                       DECIMAL(19,4)                   NOT NULL,
        gl_credits                      DECIMAL(19,4)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_GEN_ACCOUNT ON ga.f_general_ledger(pa_account)
    CREATE INDEX I_GEN_FUND ON ga.f_general_ledger(pf_fund)
    CREATE INDEX I_GEN_FUNDPD ON ga.f_general_ledger(full_accounting_period,pf_fund,pa_account)
    CREATE INDEX I_LDGR_GEN_ACCTPD ON ga.f_general_ledger(accounting_period)
    CREATE INDEX SQL130510172312810 ON ga.f_general_ledger(gl_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_gl_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_gl_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_ifoapal'
BEGIN TRY
    CREATE TABLE ga.f_ifoapal
    (
        if_id                           CHAR(12)                        NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        pl_location                     CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        end_full_accounting_period      INTEGER                         NOT NULL,
        ledger_date                     SMALLDATETIME                   NOT NULL,
        end_ledger_date                 SMALLDATETIME                   NOT NULL,
        account_type                    CHAR(2)                         NOT NULL,
        fund_type                       CHAR(2)                         NOT NULL,
        current_mo_budget_amount        DECIMAL(19,4)                   NOT NULL,
        current_mo_financial_amount     DECIMAL(19,4)                   NOT NULL,
        current_mo_encumbrance_amount   DECIMAL(19,4)                   NOT NULL,
        prior_yrs_budget_amount         DECIMAL(19,4)                   NOT NULL,
        prior_yrs_financial_amount      DECIMAL(19,4)                   NOT NULL,
        prior_mos_budget_amount         DECIMAL(19,4)                   NOT NULL,
        prior_mos_financial_amount      DECIMAL(19,4)                   NOT NULL,
        prior_mos_encumbrance_amount    DECIMAL(19,4)                   NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE UNIQUE INDEX IDX008130419170000 ON ga.f_ifoapal(if_id,pa_account,pf_fund,pp_program,po_organization,full_accounting_period)
    CREATE INDEX INDX_ACCOUNT ON ga.f_ifoapal(pa_account,full_accounting_period)
    CREATE INDEX INDX_IFOAPAL_PERI1 ON ga.f_ifoapal(full_accounting_period,pi_account_index,pf_fund,po_organization,pa_account,pp_program,if_id)
    CREATE INDEX I_IFOAPAL_FUND ON ga.f_ifoapal(pf_fund,po_organization,pp_program,full_accounting_period)
    CREATE INDEX I_IFOAPAL_FUND_IDX ON ga.f_ifoapal(pf_fund,pi_account_index)
    CREATE INDEX I_IFOAPAL_IDX ON ga.f_ifoapal(pi_account_index,full_accounting_period)
    CREATE INDEX I_IFOAPAL_IDX_FUND ON ga.f_ifoapal(pi_account_index,pf_fund)
    CREATE INDEX I_IFOAPAL_ORGANIZ1 ON ga.f_ifoapal(po_organization,pa_account,pf_fund,pp_program,pl_location,pi_account_index,full_accounting_period)
    CREATE INDEX I_IFOAPAL_PO_PROG ON ga.f_ifoapal(po_organization,pp_program,pa_account,pf_fund,pi_account_index,if_id,full_accounting_period)
    CREATE INDEX PI_ACC_IND_PFF_PPP_POO_PAA_PLL ON ga.f_ifoapal(pi_account_index,pf_fund,pp_program,po_organization,pa_account,pl_location)
    CREATE UNIQUE INDEX SQL130510172409260 ON ga.f_ifoapal(if_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_ledger_activity'
BEGIN TRY
    CREATE TABLE ga.f_ledger_activity
    (
        la_id                           CHAR(12)                        NOT NULL,
        lt_id                           CHAR(12)                        NOT NULL,
        if_id                           CHAR(12)                        NOT NULL,
        ol_id                           CHAR(12)                        NOT NULL,
        gl_id                           CHAR(12)                        NOT NULL,
        la_ledger_indicator             CHAR(1)                         NOT NULL,
        la_field_indicator              CHAR(2)                         NOT NULL,
        la_amount                       DECIMAL(19,4)                   NOT NULL,
        la_rule_sequence                SMALLINT                        NOT NULL,
        la_process_code                 CHAR(4)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        la_debit_credit                 CHAR(1)                         NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_LDGR_ACT_IFOAPAL ON ga.f_ledger_activity(if_id)
    CREATE INDEX I_LDGR_ACT_IX1 ON ga.f_ledger_activity(la_ledger_indicator,if_id)
    CREATE INDEX I_LDGR_ACT_LT_ID ON ga.f_ledger_activity(la_ledger_indicator,lt_id)
    CREATE INDEX I_LDGR_ACT_TRANS ON ga.f_ledger_activity(lt_id)
    CREATE INDEX I_LDGR_INDICATOR ON ga.f_ledger_activity(accounting_period,la_ledger_indicator,la_field_indicator)
    CREATE INDEX I_LDGR_PD_INDICAT1 ON ga.f_ledger_activity(full_accounting_period,la_ledger_indicator,la_field_indicator)
    CREATE UNIQUE INDEX SQL130510172315220 ON ga.f_ledger_activity(la_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_ledger_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_ledger_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_ledger_transaction'
BEGIN TRY
    CREATE TABLE ga.f_ledger_transaction
    (
        lt_id                           CHAR(12)                        NOT NULL,
        if_id                           CHAR(12)                        NOT NULL,
        dt_sequence_number              SMALLINT                        NOT NULL,
        lt_document_number              CHAR(8)                         NOT NULL,
        lt_transaction_date             SMALLDATETIME                   NOT NULL,
        lt_item_number                  SMALLINT                        NOT NULL,
        lt_sequence_number              SMALLINT                        NOT NULL,
        lt_budget_period                SMALLINT                        NOT NULL,
        lt_amount                       DECIMAL(19,4)                   NOT NULL,
        lt_description                  VARCHAR(35)                     NOT NULL,
        lt_document_reference_number    VARCHAR(10)                     NOT NULL,
        lt_debit_credit_indicator       CHAR(1)                         NOT NULL,
        lt_activity_date                DATETIME2                       NOT NULL,
        lt_encumbrance_number           VARCHAR(8)                      NOT NULL,
        lt_encumbrance_action           CHAR(1)                         NOT NULL,
        lt_encumbrance_item             SMALLINT                        NOT NULL,
        lt_encumbrance_sequence         SMALLINT                        NOT NULL,
        lt_encumbrance_type             CHAR(1)                         NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        lt_rule_class_code              CHAR(4)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        lt_encumbrance_doc_type         VARCHAR(3)                      NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        auto_journal_id                 VARCHAR(3)                          NULL,
        auto_journal_reversal           CHAR(1)                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX F_LEDGER_TRANSACTION_ACC_P_LT_ID ON ga.f_ledger_transaction(full_accounting_period,lt_id)
    CREATE INDEX F_LEDGER_TRANSACTION_FULL_ACC_P ON ga.f_ledger_transaction(full_accounting_period)
    CREATE UNIQUE INDEX IDX008130419510000 ON ga.f_ledger_transaction(lt_id,dt_sequence_number,lt_rule_class_code)
    CREATE INDEX I_LDGR_TRANS_ACCT1 ON ga.f_ledger_transaction(accounting_period)
    CREATE INDEX I_LDGR_TRANS_DATE ON ga.f_ledger_transaction(lt_transaction_date)
    CREATE INDEX I_LDGR_TRANS_DOC ON ga.f_ledger_transaction(lt_document_reference_number)
    CREATE UNIQUE INDEX I_LDGR_TRANS_IX1_ ON ga.f_ledger_transaction(lt_id,lt_description,lt_document_number,lt_transaction_date,lt_rule_class_code,dt_sequence_number)
    CREATE INDEX I_LEDGER_TRANS_PD ON ga.f_ledger_transaction(lt_document_number,full_accounting_period)
    CREATE UNIQUE INDEX I_LT_ID ON ga.f_ledger_transaction(lt_id,dt_sequence_number)
    CREATE INDEX I_VENDOR_CODE ON ga.f_ledger_transaction(v_vendor_code)
    CREATE UNIQUE INDEX SQL130510172317590 ON ga.f_ledger_transaction(lt_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_ol_detail_v'
BEGIN TRY
    CREATE TABLE ga.f_ol_detail_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        rule_class_code                 CHAR(4)                         NOT NULL,
        document_number                 CHAR(8)                         NOT NULL,
        sequence_number                 SMALLINT                        NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        document_reference_number       VARCHAR(10)                     NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        amount                          DECIMAL(19,4)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        debit_credit_indicator          CHAR(1)                         NOT NULL,
        debit_credit                    CHAR(1)                         NOT NULL,
        encumbrance_number              CHAR(8)                         NOT NULL,
        encumbrance_action              CHAR(1)                         NOT NULL,
        encumbrance_type                CHAR(1)                         NOT NULL,
        vendor_code                     CHAR(10)                        NOT NULL,
        item_number                     SMALLINT                        NOT NULL,
        encumbrance_item                SMALLINT                        NOT NULL,
        encumbrance_sequence            SMALLINT                        NOT NULL,
        budget_period                   SMALLINT                        NOT NULL,
        document_type_sequence_number   SMALLINT                        NOT NULL,
        ledger_indicator                CHAR(1)                         NOT NULL,
        field_indicator                 CHAR(2)                         NOT NULL,
        process_code                    CHAR(4)                         NOT NULL,
        rule_sequence                   SMALLINT                        NOT NULL,
        ledger_activity_id              CHAR(12)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        ledger_transaction_id           CHAR(12)                        NOT NULL,
        ifoapal_id                      CHAR(12)                        NOT NULL,
        operating_ledger_id             CHAR(12)                        NOT NULL,
        general_ledger_id               CHAR(12)                        NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_operating_ledger'
BEGIN TRY
    CREATE TABLE ga.f_operating_ledger
    (
        ol_id                           CHAR(12)                        NOT NULL,
        if_id                           CHAR(12)                        NOT NULL,
        ol_activity_date                SMALLDATETIME                   NOT NULL,
        ol_budget_amount                DECIMAL(19,4)                   NOT NULL,
        ol_financial_amount             DECIMAL(19,4)                   NOT NULL,
        ol_encumbrance_amount           DECIMAL(19,4)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_LDGR_OPER_ACCTPD ON ga.f_operating_ledger(accounting_period)
    CREATE INDEX I_OPERATING_LEDGE1 ON ga.f_operating_ledger(if_id)
    CREATE INDEX I_OPERATING_LEDGE2 ON ga.f_operating_ledger(full_accounting_period)
    CREATE UNIQUE INDEX SQL130510172320230 ON ga.f_operating_ledger(ol_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_operating_ledger_v'
BEGIN TRY
    CREATE TABLE ga.f_operating_ledger_v
    (
        accounting_period               SMALLINT                        NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund                            CHAR(6)                         NOT NULL,
        organization                    CHAR(6)                         NOT NULL,
        account                         CHAR(6)                         NOT NULL,
        program                         CHAR(6)                         NOT NULL,
        [location]                      CHAR(6)                         NOT NULL,
        activity_date                   DATETIME2                       NOT NULL,
        budget_amount                   DECIMAL(19,4)                   NOT NULL,
        financial_amount                DECIMAL(19,4)                   NOT NULL,
        encumbrance_amount              DECIMAL(19,4)                   NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_account'
BEGIN TRY
    CREATE TABLE ga.f_period_account
    (
        pa_account                      CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pat_account_type                CHAR(2)                         NOT NULL,
        pa_effective_date               SMALLDATETIME                   NOT NULL,
        pa_normal_balance_indicator     CHAR(1)                         NOT NULL,
        pa_predecessor                  CHAR(6)                         NOT NULL,
        pa_title                        VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT_PRED ON ga.f_period_account(pa_predecessor)
    CREATE INDEX I_ACCOUNT_TITLE ON ga.f_period_account(pa_title)
    CREATE INDEX I_ACCOUNT_TYPE ON ga.f_period_account(pat_account_type)
    CREATE UNIQUE INDEX I_PERIOD_ACCT_IX1 ON ga.f_period_account(pa_account,full_accounting_period,pa_title)
    CREATE UNIQUE INDEX SQL130510172322720 ON ga.f_period_account(pa_account,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_account_type'
BEGIN TRY
    CREATE TABLE ga.f_period_account_type
    (
        pat_account_type                CHAR(2)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pat_effective_date              SMALLDATETIME                   NOT NULL,
        pat_predecessor                 CHAR(2)                         NOT NULL,
        pat_title                       VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT_TYPE_PR1 ON ga.f_period_account_type(pat_predecessor)
    CREATE INDEX I_ACCOUNT_TYPE_TI1 ON ga.f_period_account_type(pat_title)
    CREATE UNIQUE INDEX SQL130510172327370 ON ga.f_period_account_type(pat_account_type,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_fund'
BEGIN TRY
    CREATE TABLE ga.f_period_fund
    (
        pf_fund                         CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pft_fund_type                   CHAR(2)                         NOT NULL,
        pf_effective_date               SMALLDATETIME                   NOT NULL,
        pf_predecessor                  CHAR(6)                         NOT NULL,
        pf_title                        VARCHAR(35)                     NOT NULL,
        pf_grant_contract               VARCHAR(35)                     NOT NULL,
        pf_indirect_cost_code           CHAR(6)                         NOT NULL,
        pf_standard_percent             DECIMAL(7,4)                    NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_FUND_PRED ON ga.f_period_fund(pf_predecessor)
    CREATE INDEX I_FUND_TITLE ON ga.f_period_fund(pf_title)
    CREATE INDEX I_FUND_TYPE ON ga.f_period_fund(pft_fund_type)
    CREATE UNIQUE INDEX I_PERIOD_FUND_IX1 ON ga.f_period_fund(pf_fund,full_accounting_period,pf_title)
    CREATE UNIQUE INDEX SQL130510172403820 ON ga.f_period_fund(pf_fund,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_fund_type'
BEGIN TRY
    CREATE TABLE ga.f_period_fund_type
    (
        pft_fund_type                   CHAR(2)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pft_effective_date              SMALLDATETIME                   NOT NULL,
        pft_predecessor                 CHAR(2)                         NOT NULL,
        pft_title                       VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_FUND_TYPE_PRED ON ga.f_period_fund_type(pft_predecessor)
    CREATE INDEX I_FUND_TYPE_TITLE ON ga.f_period_fund_type(pft_title)
    CREATE UNIQUE INDEX SQL130510172332450 ON ga.f_period_fund_type(pft_fund_type,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_index'
BEGIN TRY
    CREATE TABLE ga.f_period_index
    (
        pi_account_index                CHAR(10)                        NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pi_effective_date               SMALLDATETIME                   NOT NULL,
        pi_title                        VARCHAR(35)                     NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        pl_location                     CHAR(6)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX F_PERIOD_INDEX_FACC_PI_ACC ON ga.f_period_index(full_accounting_period,pi_account_index)
    CREATE INDEX I_ACCT_INDEX_TITLE ON ga.f_period_index(pi_title)
    CREATE INDEX I_FULL_ACCTG ON ga.f_period_index(full_accounting_period,pi_title,pi_account_index)
    CREATE INDEX I_INDEX_ACCT ON ga.f_period_index(pa_account)
    CREATE INDEX I_INDEX_FUND ON ga.f_period_index(pf_fund)
    CREATE INDEX I_INDEX_LOC ON ga.f_period_index(pl_location)
    CREATE INDEX I_INDEX_ORG ON ga.f_period_index(po_organization)
    CREATE INDEX I_INDEX_PROG ON ga.f_period_index(pp_program)
    CREATE UNIQUE INDEX SQL130510172337480 ON ga.f_period_index(pi_account_index,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_location'
BEGIN TRY
    CREATE TABLE ga.f_period_location
    (
        pl_location                     CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pl_effective_date               SMALLDATETIME                   NOT NULL,
        pl_predecessor                  CHAR(6)                         NOT NULL,
        pl_title                        VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_LOCATION_PRED ON ga.f_period_location(pl_predecessor)
    CREATE INDEX I_LOCATION_TITLE ON ga.f_period_location(pl_title)
    CREATE UNIQUE INDEX SQL130510172342210 ON ga.f_period_location(pl_location,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_organization'
BEGIN TRY
    CREATE TABLE ga.f_period_organization
    (
        po_organization                 CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        po_effective_date               SMALLDATETIME                   NOT NULL,
        po_finance_manager              VARCHAR(35)                     NOT NULL,
        po_predecessor                  CHAR(6)                         NOT NULL,
        po_title                        VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ORG_PRED ON ga.f_period_organization(po_predecessor)
    CREATE INDEX I_ORG_TITLE ON ga.f_period_organization(po_title)
    CREATE UNIQUE INDEX I_PERIOD_ORG_IX1 ON ga.f_period_organization(po_organization,full_accounting_period,po_title)
    CREATE UNIQUE INDEX SQL130510172346560 ON ga.f_period_organization(po_organization,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_period_program'
BEGIN TRY
    CREATE TABLE ga.f_period_program
    (
        pp_program                      CHAR(6)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        pp_effective_date               SMALLDATETIME                   NOT NULL,
        pp_predecessor                  CHAR(6)                         NOT NULL,
        pp_title                        VARCHAR(35)                     NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_PROGRAM_PRED ON ga.f_period_program(pp_predecessor)
    CREATE INDEX I_PROGRAM_TITLE ON ga.f_period_program(pp_title)
    CREATE UNIQUE INDEX SQL130510172350510 ON ga.f_period_program(pp_program,full_accounting_period)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_prior_encumbrance_bal'
BEGIN TRY
    CREATE TABLE ga.f_prior_encumbrance_bal
    (
        accounting_period               SMALLINT                        NOT NULL,
        pe_organization                 CHAR(6)                         NOT NULL,
        pe_program                      CHAR(6)                         NOT NULL,
        pe_fund                         CHAR(6)                         NOT NULL,
        pe_account_level1               CHAR(6)                         NOT NULL,
        pe_account_index                CHAR(10)                        NOT NULL,
        pe_encumbrance_no               CHAR(8)                         NOT NULL,
        pe_document_type                CHAR(3)                         NOT NULL,
        pe_encumbrance_item             SMALLINT                        NOT NULL,
        pe_encumbrance_sequence         SMALLINT                        NOT NULL,
        pe_encumbrance_descrip          VARCHAR(35)                     NOT NULL,
        pe_account                      CHAR(6)                         NOT NULL,
        pe_establish_date               SMALLDATETIME                       NULL,
        pe_amount                       DECIMAL(19,4)                   NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_FULL_ACCT_PERIOD ON ga.f_prior_encumbrance_bal(full_accounting_period,pe_organization,pe_fund,pe_program)
    CREATE INDEX I_PE_ACCT_INDEX ON ga.f_prior_encumbrance_bal(pe_account_index,full_accounting_period)
    CREATE INDEX I_PE_ENCUMNO ON ga.f_prior_encumbrance_bal(pe_encumbrance_no)
    CREATE INDEX I_PE_ORGFUND ON ga.f_prior_encumbrance_bal(accounting_period,pe_organization,pe_fund,pe_program)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_prior_month_balance'
BEGIN TRY
    CREATE TABLE ga.f_prior_month_balance
    (
        accounting_period               SMALLINT                        NOT NULL,
        pm_account_index                CHAR(10)                        NOT NULL,
        pm_fund                         CHAR(6)                         NOT NULL,
        pm_organization                 CHAR(6)                         NOT NULL,
        pm_account                      CHAR(6)                         NOT NULL,
        pm_program                      CHAR(6)                         NOT NULL,
        pm_location                     CHAR(6)                         NOT NULL,
        pm_budget_amount                DECIMAL(19,4)                   NOT NULL,
        pm_financial_amount             DECIMAL(19,4)                   NOT NULL,
        pm_encumbrance_amount           DECIMAL(19,4)                   NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_FUND_ACCTPD ON ga.f_prior_month_balance(pm_fund,full_accounting_period,pm_account,pm_organization)
    CREATE INDEX I_ORGFUND ON ga.f_prior_month_balance(full_accounting_period,pm_organization,pm_fund,pm_program)
    CREATE INDEX I_PM_ACCT_INDEX ON ga.f_prior_month_balance(pm_account_index)
    CREATE INDEX I_PM_FUND_ACCTPD ON ga.f_prior_month_balance(pm_fund,accounting_period,pm_account,pm_organization)
    CREATE INDEX I_PM_ORGFUND ON ga.f_prior_month_balance(accounting_period,pm_organization,pm_fund,pm_program)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_transaction_type'
BEGIN TRY
    CREATE TABLE ga.f_transaction_type
    (
        tt_budget                       SMALLINT                        NOT NULL,
        tt_financial                    SMALLINT                        NOT NULL,
        tt_encumbrance                  SMALLINT                        NOT NULL,
        tt_field_indicator              CHAR(2)                         NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.f_vendor'
BEGIN TRY
    CREATE TABLE ga.f_vendor
    (
        v_state_withheld_percent        DECIMAL(7,4)                    NOT NULL,
        v_income_type_sequence_number   SMALLINT                        NOT NULL,
        v_ap_credit_balance_ind         CHAR(1)                         NOT NULL,
        v_travel_credit_balance_ind     CHAR(1)                         NOT NULL,
        v_state_code                    CHAR(2)                         NOT NULL,
        v_discount_code                 CHAR(2)                         NOT NULL,
        v_tax_rate_code                 CHAR(3)                         NOT NULL,
        v_person_entity_ind             CHAR(1)                         NOT NULL,
        v_country_code                  CHAR(2)                         NOT NULL,
        v_address_type_code             CHAR(2)                         NOT NULL,
        v_one_time_indicator            CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        v_sales_use_tax_indicator       CHAR(1)                         NOT NULL,
        v_timestamp                     DATETIME2                       NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        v_vendor_contact_name           VARCHAR(35)                     NOT NULL,
        v_vendor_name                   VARCHAR(35)                     NOT NULL,
        v_vendor_name_add1              VARCHAR(35)                     NOT NULL,
        v_zip_code                      VARCHAR(10)                     NOT NULL,
        name_sort                       VARCHAR(60)                         NULL,
        v_1099_report_id                CHAR(9)                         NOT NULL,
        v_federal_withheld_percent      DECIMAL(7,4)                    NOT NULL,
        v_internal_id                   INTEGER                             NULL,
        v_address_2                     VARCHAR(35)                     NOT NULL,
        v_city                          VARCHAR(18)                     NOT NULL,
        v_address_4                     VARCHAR(35)                     NOT NULL,
        v_address_3                     VARCHAR(35)                     NOT NULL,
        v_phone                         VARCHAR(17)                     NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.gl_detail'
BEGIN TRY
    CREATE TABLE ga.gl_detail
    (
        calendar_year_month             INTEGER                         NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        pl_location                     CHAR(6)                         NOT NULL,
        dt_sequence_number              SMALLINT                        NOT NULL,
        lt_document_number              CHAR(8)                         NOT NULL,
        lt_transaction_date             SMALLDATETIME                   NOT NULL,
        lt_item_number                  SMALLINT                        NOT NULL,
        lt_sequence_number              SMALLINT                        NOT NULL,
        lt_budget_period                SMALLINT                        NOT NULL,
        lt_amount                       DECIMAL(19,4)                   NOT NULL,
        lt_description                  VARCHAR(35)                     NOT NULL,
        lt_document_reference_number    VARCHAR(10)                     NOT NULL,
        lt_debit_credit_indicator       CHAR(1)                         NOT NULL,
        lt_activity_date                DATETIME2                       NOT NULL,
        lt_encumbrance_number           VARCHAR(8)                      NOT NULL,
        lt_encumbrance_action           CHAR(1)                         NOT NULL,
        lt_encumbrance_item             SMALLINT                        NOT NULL,
        lt_encumbrance_sequence         SMALLINT                        NOT NULL,
        lt_encumbrance_type             CHAR(1)                         NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        lt_rule_class_code              CHAR(4)                         NOT NULL,
        lt_encumbrance_doc_type         VARCHAR(3)                      NOT NULL,
        la_ledger_indicator             CHAR(1)                         NOT NULL,
        la_field_indicator              CHAR(2)                         NOT NULL,
        la_amount                       DECIMAL(19,4)                   NOT NULL,
        la_rule_sequence                SMALLINT                        NOT NULL,
        la_process_code                 CHAR(4)                         NOT NULL,
        la_debit_credit                 CHAR(1)                         NOT NULL,
        la_id                           CHAR(12)                        NOT NULL,
        lt_id                           CHAR(12)                        NOT NULL,
        if_id                           CHAR(12)                        NOT NULL,
        ol_id                           CHAR(12)                        NOT NULL,
        gl_id                           CHAR(12)                        NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                         NOT NULL,
        bank_account_code               CHAR(2)                         NOT NULL,
        auto_journal_id                 VARCHAR(3)                      NOT NULL,
        auto_journal_reversal           CHAR(1)                         NOT NULL,
        description_privy               VARCHAR(35)                     NOT NULL,
        document_reference_no_privy     VARCHAR(10)                     NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_GLDTL_ACCOUNT_I1 ON ga.gl_detail(pi_account_index,full_accounting_period)
    CREATE INDEX I_GLDTL_DOC_NUMBER ON ga.gl_detail(lt_document_number,full_accounting_period)
    CREATE INDEX I_GLDTL_DOC_REFER1 ON ga.gl_detail(lt_document_reference_number,full_accounting_period)
    CREATE INDEX I_GLDTL_FULL_ACCT1 ON ga.gl_detail(full_accounting_period,la_field_indicator)
    CREATE INDEX I_GLDTL_PA_ACCOUNT ON ga.gl_detail(pa_account,full_accounting_period,pf_fund)
    CREATE INDEX I_GLDTL_PF_FUND ON ga.gl_detail(pf_fund,lt_document_reference_number,pa_account,full_accounting_period)
    CREATE INDEX I_NP_ACCT_PERIOD ON ga.gl_detail(full_accounting_period,pf_fund,pa_account,lt_document_reference_number)
    CREATE UNIQUE INDEX SQL130510172358990 ON ga.gl_detail(la_id)
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.tf_transfer_detail'
BEGIN TRY
    CREATE TABLE ga.tf_transfer_detail
    (
        td_perm_fte_equivalent_signed   DECIMAL(19,4)                   NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        td_perm_class                   CHAR(1)                             NULL,
        td_perm_type                    CHAR(1)                             NULL,
        td_perm_syswide_admin_unit      CHAR(1)                             NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        td_perm_amount_signed           DECIMAL(19,4)                   NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        td_sequence_number              SMALLINT                        NOT NULL,
        td_perm_full_time_equivalent    DECIMAL(19,4)                       NULL,
        td_perm_description             VARCHAR(35)                         NULL,
        full_accounting_period          INTEGER                             NULL,
        pl_location                     CHAR(6)                         NOT NULL,
        th_document_number              CHAR(8)                             NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        td_perm_subcampus               CHAR(1)                             NULL,
        accounting_period               SMALLINT                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        td_current_amount               DECIMAL(19,4)                       NULL,
        td_fte_dbcr_indicator           DECIMAL(19,4)                       NULL,
        td_perm_dbcr_indicator          CHAR(1)                             NULL,
        td_current_amount_signed        DECIMAL(19,4)                   NOT NULL,
        td_current_dbcr_indicator       CHAR(1)                             NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        td_current_description          VARCHAR(35)                         NULL,
        td_perm_amount                  DECIMAL(19,4)                       NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.tf_transfer_header'
BEGIN TRY
    CREATE TABLE ga.tf_transfer_header
    (
        th_current_posting_date         SMALLDATETIME                       NULL,
        th_perm_extract_date            SMALLDATETIME                       NULL,
        th_document_status              CHAR(2)                             NULL,
        th_document_number              CHAR(8)                             NULL,
        th_document_date                SMALLDATETIME                       NULL,
        th_document_amount              DECIMAL(19,4)                       NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- ga.tf_transfer_text'
BEGIN TRY
    CREATE TABLE ga.tf_transfer_text
    (
        tt_print_flag                   CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        tt_clause_code                  CHAR(1)                         NOT NULL,
        tt_sequence_number              SMALLINT                        NOT NULL,
        tt_text                         VARCHAR(35)                         NULL,
        th_document_number              CHAR(8)                             NULL,
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH