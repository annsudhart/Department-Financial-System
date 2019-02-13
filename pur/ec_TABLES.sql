/***************************************************************************************
Name      : BSO Financial Management Interface - IFOAPAL
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates PUR index tables
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

    SET @schemaName = 'pur'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName ='ec_admin_support'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName ='ec_airline_leg_data'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 3
    BEGIN
        SET @objectName ='ec_car_rental_data'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 4
    BEGIN
        SET @objectName ='ec_card_accounting'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 5
    BEGIN
        SET @objectName ='ec_cardholder'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 6
    BEGIN
        SET @objectName ='ec_department_administrator'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 7
    BEGIN
        SET @objectName ='ec_import_control'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 8
    BEGIN
        SET @objectName ='ec_line_item'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 9
    BEGIN
        SET @objectName ='ec_program_administrator'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 10
    BEGIN
        SET @objectName ='ec_purchase'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 11
    BEGIN
        SET @objectName ='ec_trans_detail'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 12
    BEGIN
        SET @objectName ='ec_transaction_reviewer'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 13
    BEGIN
        SET @objectName ='pu_buyer'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 14
    BEGIN
        SET @objectName ='pu_poaccount'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 15
    BEGIN
        SET @objectName ='pu_poheader'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 16
    BEGIN
        SET @objectName ='pu_poheader_text'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 17
    BEGIN
        SET @objectName ='pu_poitem'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 18
    BEGIN
        SET @objectName ='pu_poitem_text'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 19
    BEGIN
        SET @objectName ='pu_shipto'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 20
    BEGIN
        SET @objectName ='pu_vendor'
        SET @objectType = 'U'
    END
      ELSE IF @localCounter = 21
    BEGIN
        SET @objectName ='ec_airline_data'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 22
    BEGIN
        SET @objectName ='ec_hotel_data'
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
CREATE SCHEMA pur;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'UC San Diego Procurement database', 
	 @level0type=N'SCHEMA',
	 @level0name=N'pur';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '-- pur.ec_admin_support'
BEGIN TRY
    CREATE TABLE pur.ec_admin_support
    (
        role_key                        DECIMAL(18,0)                   NOT NULL,
        person_key                      DECIMAL(18,0)                   NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        campus_id                       VARCHAR(9)                      NOT NULL,
        affiliate_id                    DECIMAL(18,0)                   NOT NULL,
        card_name                       VARCHAR(24)                     NOT NULL,
        name_comp                       VARCHAR(26)                     NOT NULL,
        home_department_code            VARCHAR(6)                      NOT NULL,
        name_salutary                   VARCHAR(60)                     NOT NULL,
        email_address                   VARCHAR(40)                     NOT NULL,
        phone_number                    VARCHAR(20)                     NOT NULL,
        mail_drop                       VARCHAR(6)                      NOT NULL,
        employee_id                     VARCHAR(9)                      NOT NULL,
        emp_status_cd                   VARCHAR(1)                          NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CARD_NAME ON pur.ec_admin_support(card_name);
    CREATE INDEX I_EMPLOYEE_ID ON pur.ec_admin_support(employee_id);
    CREATE INDEX I_NAME_COMP ON pur.ec_admin_support(name_comp);
    CREATE INDEX I_WORKGROUP_KEY ON pur.ec_admin_support(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_airline_leg_data'
BEGIN TRY
    CREATE TABLE pur.ec_airline_leg_data
    (
        import_id                       VARCHAR(10)                         NULL,
        workgroup_key                   DECIMAL(18,0)                       NULL,
        card_key                        DECIMAL(18,0)                       NULL,
        vendor_id                       VARCHAR(16)                         NULL,
        modification_indicator          VARCHAR(3)                          NULL,
        data_leg_key                    DECIMAL(18,0)                       NULL,
        airline_data_key                DECIMAL(18,0)                       NULL,
        transaction_id                  CHAR(10)                            NULL,
        data_leg_sequence               INTEGER                             NULL,
        tsys_tran_code                  CHAR(4)                             NULL,
        carrier_code                    CHAR(2)                             NULL,
        service_class                   CHAR(1)                             NULL,
        destination_airport_code        CHAR(3)                             NULL,
        stopover_code                   CHAR(1)                             NULL,
        last_activity_date              SMALLDATETIME                       NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ADL_ALDKEY ON pur.ec_airline_leg_data(airline_data_key);
    CREATE INDEX I_ADL_CARD_KEY ON pur.ec_airline_leg_data(card_key);
    CREATE INDEX I_ADL_DATA_LEG_KEY ON pur.ec_airline_leg_data(data_leg_key);
    CREATE INDEX I_ADL_IMPORT_ID ON pur.ec_airline_leg_data(import_id);
    CREATE INDEX I_ADL_TRANS_ID ON pur.ec_airline_leg_data(transaction_id);
    CREATE INDEX I_ADL_VENDOR_ID ON pur.ec_airline_leg_data(vendor_id);
    CREATE INDEX I_ADL_WORKGROUPKEY ON pur.ec_airline_leg_data(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_car_rental_data'
BEGIN TRY
    CREATE TABLE pur.ec_car_rental_data
    (
        import_id                       VARCHAR(10)                         NULL,
        workgroup_key                   DECIMAL(18,0)                       NULL,
        card_key                        DECIMAL(18,0)                       NULL,
        vendor_id                       VARCHAR(16)                         NULL,
        modification_indicator          VARCHAR(3)                          NULL,
        car_rental_key                  DECIMAL(18,0)                       NULL,
        transaction_id                  CHAR(10)                            NULL,
        tsys_tran_code                  CHAR(4)                             NULL,
        no_show_code                    CHAR(1)                             NULL,
        check_out_date                  SMALLDATETIME                       NULL,
        extra_charges                   VARCHAR(8)                          NULL,
        agreement_number                VARCHAR(25)                         NULL,
        corporate_id                    VARCHAR(12)                         NULL,
        renter_name                     VARCHAR(25)                         NULL,
        return_location                 VARCHAR(18)                         NULL,
        car_class_code                  CHAR(2)                             NULL,
        insurance_charges               DECIMAL(12,2)                       NULL,
        daily_rental_rate               DECIMAL(12,2)                       NULL,
        weekly_rental_rate              DECIMAL(12,2)                       NULL,
        one_way_dropoff_charge          DECIMAL(12,2)                       NULL,
        regular_mileage_charge          DECIMAL(12,2)                       NULL,
        extra_mileage_charge            DECIMAL(12,2)                       NULL,
        late_return_charge              DECIMAL(12,2)                       NULL,
        fuel_charge                     DECIMAL(12,2)                       NULL,
        total_tax                       DECIMAL(19,4)                       NULL,
        last_activity_date              SMALLDATETIME                       NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CRD_AGREENUMBER ON pur.ec_car_rental_data(agreement_number);
    CREATE INDEX I_CRD_CARD_KEY ON pur.ec_car_rental_data(card_key);
    CREATE INDEX I_CRD_CARRENTALKEY ON pur.ec_car_rental_data(car_rental_key);
    CREATE INDEX I_CRD_IMPORT_ID ON pur.ec_car_rental_data(import_id);
    CREATE INDEX I_CRD_RENTER_NAME ON pur.ec_car_rental_data(renter_name);
    CREATE INDEX I_CRD_TRANS_ID ON pur.ec_car_rental_data(transaction_id);
    CREATE INDEX I_CRD_VENDOR_ID ON pur.ec_car_rental_data(vendor_id);
    CREATE INDEX I_CRD_WORKGROUPKEY ON pur.ec_car_rental_data(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_card_accounting'
BEGIN TRY
    CREATE TABLE pur.ec_card_accounting
    (
        card_key                        DECIMAL(18,0)                   NOT NULL,
        [start_date]                    DATETIME2                           NULL,
        end_date                        SMALLDATETIME                       NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund_code                       CHAR(6)                             NULL,
        organization_code               VARCHAR(6)                      NOT NULL,
        program_code                    VARCHAR(6)                      NOT NULL,
        account_code                    VARCHAR(6)                      NOT NULL,
        location_code                   VARCHAR(6)                      NOT NULL,
        most_recent_flag                CHAR(1)                         NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT_INDEX ON pur.ec_card_accounting(account_index);
    CREATE INDEX I_ACCT_CODE ON pur.ec_card_accounting(account_code);
    CREATE INDEX I_CARD_KEY ON pur.ec_card_accounting(card_key);
    CREATE INDEX I_FUND_CODE ON pur.ec_card_accounting(fund_code);
    CREATE INDEX I_LOC_CODE ON pur.ec_card_accounting(location_code);
    CREATE INDEX I_ORGN_CODE ON pur.ec_card_accounting(organization_code);
    CREATE INDEX I_PROG_CODE ON pur.ec_card_accounting(program_code);
    CREATE INDEX I_RECENT_FLAG ON pur.ec_card_accounting(most_recent_flag);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_cardholder'
BEGIN TRY
    CREATE TABLE pur.ec_cardholder
    (
        role_key                        DECIMAL(18,0)                   NOT NULL,
        person_key                      DECIMAL(18,0)                   NOT NULL,
        card_key                        DECIMAL(18,0)                   NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        campus_id                       VARCHAR(9)                          NULL,
        affiliate_id                    DECIMAL(18,0)                       NULL,
        card_name                       VARCHAR(24)                     NOT NULL,
        name_comp                       VARCHAR(26)                     NOT NULL,
        ecch_orig_training_date         DATE                                NULL,
        ecch_training_date              DATE                                NULL,
        home_department_code            VARCHAR(6)                          NULL,
        name_salutary                   VARCHAR(60)                     NOT NULL,
        organization_name               VARCHAR(60)                         NULL,
        mail_drop                       VARCHAR(6)                          NULL,
        employee_id                     VARCHAR(9)                          NULL,
        emp_status_cd                   VARCHAR(1)                          NULL,
        organization                    CHAR(6)                             NULL,
        card_number_suffix              VARCHAR(4)                          NULL,
        date_issued                     DATETIME2                           NULL,
        [status]                        CHAR(1)                         NOT NULL,
        expiration_month                VARCHAR(2)                          NULL,
        expiration_year                 VARCHAR(2)                          NULL,
        mcc_group                       VARCHAR(6)                      NOT NULL,
        campus_mail_code                VARCHAR(5)                          NULL,
        email_address                   VARCHAR(40)                         NULL,
        phone_number                    VARCHAR(20)                         NULL,
        embossed_text                   VARCHAR(24)                         NULL,
        first_used_date                 DATE                                NULL,
        last_used_date                  DATE                                NULL,
        cancellation_date               DATE                                NULL,
        department_name                 VARCHAR(35)                         NULL,
        cancelled_by                    VARCHAR(35)                         NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        CARD_TYPE_DESCRIPTION           VARCHAR(50)                         NULL,
        REPORTING_HIERARCHY             VARCHAR(5)                          NULL,
        BUYER_CODE                      VARCHAR(6)                          NULL,
        CREDIT_LIMIT                    DECIMAL(8,0)                        NULL,
        SINGLE_PURCHASE_LIMIT           DECIMAL(8,0)                        NULL,
        AUTHORIZATIONS_PER_DAY          DECIMAL(3,0)                        NULL,
        TRANSACTIONS_PER_CYCLE          DECIMAL(4,0)                        NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX EC_CARDHOLDER_CARD_KEY_WRK_KEY ON pur.ec_cardholder(card_key,workgroup_key);
    CREATE INDEX I_CARD_KEY1 ON pur.ec_cardholder(card_key);
    CREATE INDEX I_CARD_NAME1 ON pur.ec_cardholder(card_name);
    CREATE INDEX I_EMPLOYEE_ID1 ON pur.ec_cardholder(employee_id);
    CREATE INDEX I_WORKGROUP_KEY1 ON pur.ec_cardholder(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_department_administrator'
BEGIN TRY
    CREATE TABLE pur.ec_department_administrator
    (
        role_key                        DECIMAL(18,0)                   NOT NULL,
        person_key                      DECIMAL(18,0)                   NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        campus_id                       VARCHAR(9)                      NOT NULL,
        affiliate_id                    DECIMAL(18,0)                   NOT NULL,
        card_name                       VARCHAR(24)                     NOT NULL,
        name_comp                       VARCHAR(26)                     NOT NULL,
        ecda_training_date              SMALLDATETIME                   NOT NULL,
        home_department_code            VARCHAR(6)                      NOT NULL,
        name_salutary                   VARCHAR(60)                     NOT NULL,
        email_address                   VARCHAR(40)                     NOT NULL,
        phone_number                    VARCHAR(20)                     NOT NULL,
        mail_drop                       VARCHAR(6)                      NOT NULL,
        employee_id                     VARCHAR(9)                      NOT NULL,
        emp_status_cd                   VARCHAR(1)                      NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CARD_NAME2 ON pur.ec_department_administrator(card_name);
    CREATE INDEX I_EMPLOYEE_ID2 ON pur.ec_department_administrator(employee_id);
    CREATE INDEX I_NAME_COMP1 ON pur.ec_department_administrator(name_comp);
    CREATE INDEX I_WORKGROUP_KEY2 ON pur.ec_department_administrator(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_import_control'
BEGIN TRY
    CREATE TABLE pur.ec_import_control
    (
        import_id                       VARCHAR(10)                         NULL,
        import_file_name                VARCHAR(255)                        NULL,
        import_total_debits             DECIMAL(19,4)                       NULL,
        import_total_credits            DECIMAL(19,4)                       NULL,
        import_date                     DATETIME2                           NULL,
        import_type_02_count            DECIMAL(6,0)                        NULL,
        import_type_05_count            DECIMAL(6,0)                    NOT NULL,
        import_type_50_count            DECIMAL(6,0)                        NULL,
        import_status                   CHAR(1)                         NOT NULL,
        import_edit_date                DATETIME2                           NULL,
        import_load_date                DATETIME2                           NULL,
        import_notify_date              DATETIME2                       NOT NULL,
        payment_document_number         VARCHAR(8)                          NULL,
        payment_amount                  DECIMAL(19,4)                   NOT NULL,
        payment_date                    SMALLDATETIME                       NULL,
        voucher_number                  VARCHAR(8)                          NULL,
        voucher_target_date             DATETIME2                           NULL,
        voucher_submit_date             SMALLDATETIME                       NULL,
        voucher_date                    SMALLDATETIME                       NULL,
        voucher_item_count              DECIMAL(4,0)                        NULL,
        voucher_control_total           DECIMAL(19,4)                   NOT NULL,
        user_id                         VARCHAR(8)                          NULL,
        last_activity_date              SMALLDATETIME                       NULL,
        refresh_date                    DATETIME2                           NULL,
        additional_status               CHAR(1)                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_IMPORT_CNTRL ON pur.ec_import_control(import_id);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_line_item'
BEGIN TRY
    CREATE TABLE pur.ec_line_item
    (
        import_id                       VARCHAR(10)                     NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        card_key                        DECIMAL(18,0)                   NOT NULL,
        vendor_id                       VARCHAR(16)                     NOT NULL,
        modification_indicator          VARCHAR(3)                      NOT NULL,
        transaction_id                  CHAR(10)                        NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        line_item_sequence              DECIMAL(4,0)                    NOT NULL,
        line_item_description           VARCHAR(26)                     NOT NULL,
        quantity                        VARCHAR(10)                     NOT NULL,
        unit_of_measure                 VARCHAR(10)                     NOT NULL,
        unit_cost                       VARCHAR(12)                     NOT NULL,
        commodity_code                  VARCHAR(15)                     NOT NULL,
        supply_type                     VARCHAR(2)                          NULL,
        purchase_invoice_number         VARCHAR(15)                         NULL,
        vendor_order_number             VARCHAR(12)                         NULL,
        discount_amount                 DECIMAL(19,4)                       NULL,
        freight_amount                  DECIMAL(19,4)                   NOT NULL,
        duty_amount                     DECIMAL(19,4)                   NOT NULL,
        order_date                      SMALLDATETIME                   NOT NULL,
        destination_country             CHAR(2)                         NOT NULL,
        destination_zip                 VARCHAR(9)                      NOT NULL,
        origin_zip_code                 VARCHAR(9)                      NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CARD_KEY2 ON pur.ec_line_item(card_key);
    CREATE INDEX I_IMPORT_CNTRL1 ON pur.ec_line_item(import_id);
    CREATE INDEX I_TRANS_ID ON pur.ec_line_item(transaction_id);
    CREATE INDEX I_VENDOR_ID ON pur.ec_line_item(vendor_id);
    CREATE INDEX I_WORKGROUP_KEY3 ON pur.ec_line_item(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_program_administrator'
BEGIN TRY
    CREATE TABLE pur.ec_program_administrator
    (
        role_key                        DECIMAL(18,0)                   NOT NULL,
        person_key                      DECIMAL(18,0)                   NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        description                     VARCHAR(35)                     NOT NULL,
        campus_id                       VARCHAR(9)                      NOT NULL,
        affiliate_id                    DECIMAL(18,0)                   NOT NULL,
        card_name                       VARCHAR(24)                     NOT NULL,
        name_comp                       VARCHAR(26)                     NOT NULL,
        ecda_training_date              SMALLDATETIME                   NOT NULL,
        home_department_code            VARCHAR(6)                      NOT NULL,
        name_salutary                   VARCHAR(60)                     NOT NULL,
        email_address                   VARCHAR(40)                     NOT NULL,
        phone_number                    VARCHAR(20)                     NOT NULL,
        mail_drop                       VARCHAR(6)                      NOT NULL,
        employee_id                     VARCHAR(9)                      NOT NULL,
        emp_status_cd                   VARCHAR(1)                      NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CARD_NAME3 ON pur.ec_program_administrator(card_name);
    CREATE INDEX I_EMPLOYEE_ID3 ON pur.ec_program_administrator(employee_id);
    CREATE INDEX I_NAME_COMP2 ON pur.ec_program_administrator(name_comp);
    CREATE INDEX I_WORKGROUP_KEY4 ON pur.ec_program_administrator(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_purchase'
BEGIN TRY
    CREATE TABLE pur.ec_purchase
    (
        import_id                       VARCHAR(10)                     NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        card_key                        DECIMAL(18,0)                   NOT NULL,
        vendor_id                       VARCHAR(16)                     NOT NULL,
        modification_indicator          VARCHAR(3)                      NOT NULL,
        transaction_id                  CHAR(10)                        NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        posted_date                     SMALLDATETIME                   NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        tax_amount                      DECIMAL(19,4)                   NOT NULL,
        reference_number                VARCHAR(23)                     NOT NULL,
        point_of_sales_code             VARCHAR(25)                     NOT NULL,
        local_tax_amount                DECIMAL(19,4)                   NOT NULL,
        local_tax_applicable_code       CHAR(1)                         NOT NULL,
        national_sales_tax_amount       DECIMAL(19,4)                       NULL,
        other_tax_amount                DECIMAL(19,4)                   NOT NULL,
        original_currency_code          VARCHAR(3)                      NOT NULL,
        original_currency_amount        DECIMAL(19,4)                   NOT NULL,
        settlement_conversion_rate      DECIMAL(15,6)                   NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        account_code                    VARCHAR(6)                      NOT NULL,
        posted_use_tax_amount           DECIMAL(19,4)                       NULL,
        calculated_use_tax_amount       DECIMAL(19,4)                       NULL,
        vendor_tax_id                   VARCHAR(12)                     NOT NULL,
        vendor_name                     VARCHAR(25)                     NOT NULL,
        vendor_city                     VARCHAR(15)                         NULL,
        vendor_state                    VARCHAR(3)                          NULL,
        vendor_country                  CHAR(2)                             NULL,
        vendor_zip                      VARCHAR(10)                         NULL,
        vendor_mcc                      VARCHAR(4)                          NULL,
        use_tax_rate                    DECIMAL(5,4)                    NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX EC_PURCHASE_POSTED_DATE ON pur.ec_purchase(posted_date);
    CREATE INDEX I_CARD_KEY3 ON pur.ec_purchase(card_key);
    CREATE INDEX I_IMPORT_CNTRL2 ON pur.ec_purchase(import_id);
    CREATE INDEX I_REF_NBR ON pur.ec_purchase(reference_number);
    CREATE INDEX I_TRANS_ID1 ON pur.ec_purchase(transaction_id);
    CREATE INDEX I_VENDOR_ID1 ON pur.ec_purchase(vendor_id);
    CREATE INDEX I_WORKGROUP_KEY5 ON pur.ec_purchase(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_trans_detail'
BEGIN TRY
    CREATE TABLE pur.ec_trans_detail
    (
        import_id                       VARCHAR(10)                     NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        card_key                        DECIMAL(18,0)                   NOT NULL,
        vendor_id                       VARCHAR(16)                     NOT NULL,
        transaction_id                  CHAR(10)                        NOT NULL,
        transaction_sequence            INTEGER                         NOT NULL,
        transaction_date                SMALLDATETIME                   NOT NULL,
        account_index                   CHAR(10)                        NOT NULL,
        fund_code                       CHAR(6)                             NULL,
        organization_code               VARCHAR(6)                      NOT NULL,
        program_code                    VARCHAR(6)                      NOT NULL,
        account_code                    VARCHAR(6)                      NOT NULL,
        location_code                   VARCHAR(6)                      NOT NULL,
        transaction_amount              DECIMAL(19,4)                   NOT NULL,
        transaction_description         VARCHAR(35)                     NOT NULL,
        equipment_flag                  CHAR(1)                         NOT NULL,
        use_tax_flag                    CHAR(1)                         NOT NULL,
        use_tax_amount                  DECIMAL(19,4)                   NOT NULL,
        comment                         VARCHAR(255)                        NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT_INDEX1 ON pur.ec_trans_detail(account_index);
    CREATE INDEX I_ACCT_CODE1 ON pur.ec_trans_detail(account_code);
    CREATE INDEX I_CARD_KEY4 ON pur.ec_trans_detail(card_key);
    CREATE INDEX I_FUND_CODE1 ON pur.ec_trans_detail(fund_code);
    CREATE INDEX I_IMPORT_CNTRL3 ON pur.ec_trans_detail(import_id);
    CREATE INDEX I_LOC_CODE1 ON pur.ec_trans_detail(location_code);
    CREATE INDEX I_ORGN_CODE1 ON pur.ec_trans_detail(organization_code);
    CREATE INDEX I_PROG_CODE1 ON pur.ec_trans_detail(program_code);
    CREATE INDEX I_TRANSACTION_DES1 ON pur.ec_trans_detail(transaction_description);
    CREATE INDEX I_TRANS_ID2 ON pur.ec_trans_detail(transaction_id);
    CREATE INDEX I_VENDOR_ID2 ON pur.ec_trans_detail(vendor_id);
    CREATE INDEX I_WORKGROUP_KEY6 ON pur.ec_trans_detail(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_transaction_reviewer'
BEGIN TRY
    CREATE TABLE pur.ec_transaction_reviewer
    (
        role_key                        DECIMAL(18,0)                   NOT NULL,
        person_key                      DECIMAL(18,0)                   NOT NULL,
        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
        card_key                        DECIMAL(18,0)                       NULL,
        description                     VARCHAR(35)                     NOT NULL,
        campus_id                       VARCHAR(9)                      NOT NULL,
        affiliate_id                    DECIMAL(18,0)                   NOT NULL,
        card_name                       VARCHAR(24)                     NOT NULL,
        name_comp                       VARCHAR(26)                     NOT NULL,
        home_department_code            VARCHAR(6)                      NOT NULL,
        name_salutary                   VARCHAR(60)                     NOT NULL,
        email_address                   VARCHAR(40)                     NOT NULL,
        phone_number                    VARCHAR(20)                     NOT NULL,
        mail_drop                       VARCHAR(6)                      NOT NULL,
        employee_id                     VARCHAR(9)                      NOT NULL,
        emp_status_cd                   VARCHAR(1)                      NOT NULL,
        user_id                         VARCHAR(8)                      NOT NULL,
        last_activity_date              DATETIME2                       NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CARD_NAME4 ON pur.ec_transaction_reviewer(card_name);
    CREATE INDEX I_EMPLOYEE_ID4 ON pur.ec_transaction_reviewer(employee_id);
    CREATE INDEX I_NAME_COMP3 ON pur.ec_transaction_reviewer(name_comp);
    CREATE INDEX I_WORKGROUP_KEY8 ON pur.ec_transaction_reviewer(workgroup_key,card_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_buyer'
BEGIN TRY
    CREATE TABLE pur.pu_buyer
    (
        buy_buyer_code                  CHAR(4)                         NOT NULL,
        buy_timestamp                   DATETIME2                       NOT NULL,
        buy_buyer_name                  CHAR(35)                        NOT NULL,
        buy_buyer_phone                 VARCHAR(17)                     NOT NULL,
        buy_buyer_pid                   CHAR(10)                        NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        most_recent_flag                CHAR(1)                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_BUYER_CODE ON pur.pu_buyer(buy_buyer_code);
    CREATE INDEX I_BUYER_NAME ON pur.pu_buyer(buy_buyer_name);
    CREATE INDEX I_BUYER_PID ON pur.pu_buyer(buy_buyer_pid);
    CREATE UNIQUE INDEX SQL120323230132910 ON pur.pu_buyer(buy_buyer_code,buy_timestamp);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_poaccount'
BEGIN TRY
    CREATE TABLE pur.pu_poaccount
    (
        poh_number                      CHAR(8)                         NOT NULL,
        poh_change_sequence_number      CHAR(3)                         NOT NULL,
        poi_item_number                 SMALLINT                        NOT NULL,
        poa_account_sequence_number     SMALLINT                        NOT NULL,
        pi_account_index                CHAR(10)                        NOT NULL,
        pf_fund                         CHAR(6)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        pa_account                      CHAR(6)                         NOT NULL,
        pp_program                      CHAR(6)                         NOT NULL,
        poa_amount                      DECIMAL(19,4)                   NOT NULL,
        poa_account_error_indicator     CHAR(1)                         NOT NULL,
        poa_rule_class_code             CHAR(4)                         NOT NULL,
        poa_discount_rule_class         CHAR(4)                         NOT NULL,
        poa_tax_rule_class              CHAR(4)                         NOT NULL,
        poa_addl_charge_rule_class      CHAR(4)                         NOT NULL,
        accounting_period               SMALLINT                        NOT NULL,
        poa_additional_charge           DECIMAL(19,4)                   NOT NULL,
        poa_tax_amount                  DECIMAL(19,4)                   NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        full_accounting_period          INTEGER                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACCOUNT ON pur.pu_poaccount(pa_account);
    CREATE INDEX I_ACCTINDEX ON pur.pu_poaccount(pi_account_index);
    CREATE INDEX I_FUND ON pur.pu_poaccount(pf_fund);
    CREATE INDEX I_ORG ON pur.pu_poaccount(po_organization);
    CREATE UNIQUE INDEX SQL120323230133400 ON pur.pu_poaccount(poh_number,poh_change_sequence_number,poi_item_number,poa_account_sequence_number);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_poheader'
BEGIN TRY
    CREATE TABLE pur.pu_poheader
    (
        poh_number                      CHAR(8)                         NOT NULL,
        poh_change_sequence_number      CHAR(3)                         NOT NULL,
        poh_acknowledge_indicator       CHAR(1)                         NOT NULL,
        poh_transit_risk_code           CHAR(2)                         NOT NULL,
        poh_blanket_term_date           SMALLDATETIME                       NULL,
        poh_tax_code                    CHAR(3)                         NOT NULL,
        poh_discount_code               CHAR(2)                         NOT NULL,
        poh_payment_code                CHAR(2)                         NOT NULL,
        shp_shipto_code                 CHAR(6)                         NOT NULL,
        shp_timestamp                   DATETIME2                       NOT NULL,
        poh_class_code                  CHAR(1)                         NOT NULL,
        poh_change_order_flag           CHAR(1)                         NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        v_address_type_code             CHAR(2)                         NOT NULL,
        v_vendor_contact_name           VARCHAR(35)                     NOT NULL,
        v_vendor_name_add1              VARCHAR(35)                     NOT NULL,
        v_address_2                     VARCHAR(35)                     NOT NULL,
        v_address_3                     VARCHAR(35)                     NOT NULL,
        v_address_4                     VARCHAR(35)                     NOT NULL,
        v_city                          VARCHAR(18)                     NOT NULL,
        v_state_code                    CHAR(2)                         NOT NULL,
        v_zip_code                      VARCHAR(10)                     NOT NULL,
        v_country_code                  CHAR(2)                         NOT NULL,
        v_phone                         VARCHAR(17)                     NOT NULL,
        buy_buyer_code                  CHAR(4)                         NOT NULL,
        buy_timestamp                   DATETIME2                       NOT NULL,
        poh_complete_indicator          CHAR(1)                         NOT NULL,
        po_organization                 CHAR(6)                         NOT NULL,
        poh_print_date                  SMALLDATETIME                       NULL,
        poh_print_flag                  CHAR(1)                         NOT NULL,
        poh_delivery_by_date            SMALLDATETIME                       NULL,
        poh_approval_indicator          CHAR(1)                         NOT NULL,
        poh_error_indicator             CHAR(1)                         NOT NULL,
        poh_total_amount                DECIMAL(19,4)                   NOT NULL,
        poh_activity_date               SMALLDATETIME                   NOT NULL,
        poh_cancel_indicator            CHAR(1)                         NOT NULL,
        poh_cancel_date                 SMALLDATETIME                       NULL,
        poh_additional_amount           DECIMAL(19,4)                   NOT NULL,
        poh_item_count                  SMALLINT                        NOT NULL,
        poh_invoice_mailcode            CHAR(6)                         NOT NULL,
        poh_discount_before_tax_ind     CHAR(1)                         NOT NULL,
        poh_discount_percent            DECIMAL(6,3)                    NOT NULL,
        poh_order_date                  SMALLDATETIME                       NULL,
        poh_final_approval_date         DATETIME2                           NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        poh_net_amount                  DECIMAL(19,4)                       NULL,
        resp_fax_nbr                    CHAR(10)                            NULL,
        resp_email_adr                  CHAR(20)                            NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_ACT_DATE ON pur.pu_poheader(poh_activity_date);
    CREATE INDEX I_BUYER1 ON pur.pu_poheader(buy_buyer_code,buy_timestamp);
    CREATE INDEX I_ORDERDATE ON pur.pu_poheader(poh_order_date);
    CREATE INDEX I_ORG1 ON pur.pu_poheader(po_organization);
    CREATE INDEX I_SHIPTO ON pur.pu_poheader(shp_shipto_code,shp_timestamp);
    CREATE INDEX I_VEND_CODE ON pur.pu_poheader(v_vendor_code);
    CREATE INDEX I_VEND_NAME ON pur.pu_poheader(v_vendor_name_add1);
    CREATE UNIQUE INDEX SQL120323230133860 ON pur.pu_poheader(poh_number,poh_change_sequence_number);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_poheader_text'
BEGIN TRY
    CREATE TABLE pur.pu_poheader_text
    (
        poh_number                      CHAR(8)                         NOT NULL,
        poh_change_sequence_number      CHAR(3)                         NOT NULL,
        pht_text_type                   CHAR(7)                         NOT NULL,
        pht_text_line_number            SMALLINT                        NOT NULL,
        pht_clause_code                 CHAR(8)                         NOT NULL,
        pht_comment_text                CHAR(55)                            NULL,
        pht_print_flag                  CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE UNIQUE INDEX SQL120323230134420 ON pur.pu_poheader_text(poh_number,poh_change_sequence_number,pht_text_type,pht_text_line_number);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_poitem'
BEGIN TRY
    CREATE TABLE pur.pu_poitem
    (
        poh_number                      CHAR(8)                         NOT NULL,
        poh_change_sequence_number      CHAR(3)                         NOT NULL,
        poi_item_number                 SMALLINT                        NOT NULL,
        poi_commodity_code              CHAR(8)                         NOT NULL,
        poi_unit_measure_code           CHAR(3)                         NOT NULL,
        poi_activity_date               SMALLDATETIME                   NOT NULL,
        poi_liquidation_indicator       CHAR(1)                         NOT NULL,
        poi_quantity                    DECIMAL(8,2)                    NOT NULL,
        poi_control_account             SMALLINT                        NOT NULL,
        poi_unit_price                  DECIMAL(14,4)                   NOT NULL,
        poi_tax_indicator               CHAR(1)                         NOT NULL,
        poi_model_number                CHAR(30)                            NULL,
        poi_tax_amount                  DECIMAL(19,4)                   NOT NULL,
        poi_item_discount_amount        DECIMAL(19,4)                   NOT NULL,
        poi_discount_before_tax_ind     CHAR(1)                         NOT NULL,
        poi_po_discount_amount          DECIMAL(19,4)                   NOT NULL,
        poi_consolidation_indicator     CHAR(1)                         NOT NULL,
        poi_price_negative_sign         CHAR(1)                         NOT NULL,
        poi_request_code                CHAR(8)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_REQUEST ON pur.pu_poitem(poi_request_code);
    CREATE UNIQUE INDEX SQL120323230134840 ON pur.pu_poitem(poh_number,poh_change_sequence_number,poi_item_number);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_poitem_text'
BEGIN TRY
    CREATE TABLE pur.pu_poitem_text
    (
        poh_number                      CHAR(8)                         NOT NULL,
        poh_change_sequence_number      CHAR(3)                         NOT NULL,
        poi_item_number                 SMALLINT                        NOT NULL,
        pit_text_line_number            SMALLINT                        NOT NULL,
        pit_clause_code                 CHAR(8)                         NOT NULL,
        pit_comment_text                CHAR(55)                            NULL,
        pit_print_flag                  CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE UNIQUE INDEX SQL120323230135280 ON pur.pu_poitem_text(poh_number,poh_change_sequence_number,poi_item_number,pit_text_line_number);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_shipto'
BEGIN TRY
    CREATE TABLE pur.pu_shipto
    (
        shp_shipto_code                 CHAR(6)                         NOT NULL,
        shp_timestamp                   DATETIME2                       NOT NULL,
        shp_ship_type_code              CHAR(1)                         NOT NULL,
        shp_ship_contact_name           CHAR(35)                        NOT NULL,
        shp_address_1                   CHAR(35)                        NOT NULL,
        shp_address_2                   CHAR(35)                        NOT NULL,
        shp_address_3                   CHAR(35)                        NOT NULL,
        shp_address_4                   CHAR(35)                        NOT NULL,
        shp_city                        CHAR(18)                        NOT NULL,
        shp_state_code                  CHAR(2)                         NOT NULL,
        shp_zip_code                    CHAR(10)                        NOT NULL,
        shp_country_code                CHAR(2)                         NOT NULL,
        shp_ship_phone                  VARCHAR(17)                     NOT NULL,
        shp_route_code                  CHAR(4)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        most_recent_flag                CHAR(1)                             NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_CONTACT ON pur.pu_shipto(shp_ship_contact_name);
    CREATE INDEX I_SHIPTO_CODE ON pur.pu_shipto(shp_shipto_code);
    CREATE UNIQUE INDEX SQL120323230135870 ON pur.pu_shipto(shp_shipto_code,shp_timestamp);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.pu_vendor'
BEGIN TRY
    CREATE TABLE pur.pu_vendor
    (
        v_internal_id                   INTEGER                             NULL,
        v_person_entity_ind             CHAR(1)                         NOT NULL,
        v_address_type_code             CHAR(2)                         NOT NULL,
        v_timestamp                     DATETIME2                       NOT NULL,
        v_vendor_code                   CHAR(10)                        NOT NULL,
        v_vendor_contact_name           VARCHAR(35)                     NOT NULL,
        v_vendor_name_add1              VARCHAR(35)                     NOT NULL,
        v_address_2                     VARCHAR(35)                     NOT NULL,
        v_address_3                     VARCHAR(35)                     NOT NULL,
        v_address_4                     VARCHAR(35)                     NOT NULL,
        v_city                          VARCHAR(18)                     NOT NULL,
        v_state_code                    CHAR(2)                         NOT NULL,
        v_zip_code                      VARCHAR(10)                     NOT NULL,
        v_country_code                  CHAR(2)                         NOT NULL,
        v_phone                         VARCHAR(17)                     NOT NULL,
        v_sales_use_tax_indicator       CHAR(1)                         NOT NULL,
        v_state_withheld_percent        DECIMAL(7,4)                    NOT NULL,
        v_federal_withheld_percent      DECIMAL(7,4)                    NOT NULL,
        v_tax_rate_code                 CHAR(3)                         NOT NULL,
        v_one_time_indicator            CHAR(1)                         NOT NULL,
        v_discount_code                 CHAR(2)                         NOT NULL,
        v_income_type_sequence_number   SMALLINT                        NOT NULL,
        v_1099_report_id                CHAR(9)                         NOT NULL,
        v_ap_credit_balance_ind         CHAR(1)                         NOT NULL,
        v_travel_credit_balance_ind     CHAR(1)                         NOT NULL,
        refresh_date                    DATETIME2                       NOT NULL,
        name_sort                       VARCHAR(60)                         NULL,
        v_vendor_code_9                 VARCHAR(9)                          NULL,
        MOST_RECENT_FLAG                CHAR(1)                             NULL,
        BUSINESS_IND                    CHAR(1)                             NULL,
        DUNS_NBR                        VARCHAR(9)                          NULL,
        SQ_VENDOR_NBR                   VARCHAR(25)                         NULL,
        V_1099_IND                      CHAR(1)                             NULL,
        ETHNIC_IND                      CHAR(1)                             NULL,
        GENDER_IND                      CHAR(1)                             NULL,
        PAYMENT_METHOD_IND              CHAR(2)                             NULL,
        ENCUMBRANCE_IND                 CHAR(1)                             NULL,
        CTX_PAYMENT_IND                 CHAR(1)                             NULL,
        IND_592                         CHAR(1)                             NULL,
        STATE_IND_592                   CHAR(1)                             NULL,
        YEARLY_THRESHOLD_592_AMT        DECIMAL(19,4)                       NULL,
        USER_CODE                       VARCHAR(8)                          NULL,
        VENDOR_STATUS                   CHAR(1)                             NULL,
        ACCOUNT_CODE                    VARCHAR(6)                          NULL,
        DEFAULT_ADDRESS_TYPE_CODE       CHAR(2)                             NULL,
        V_MAINTENANCE_END_DATE          SMALLDATETIME                       NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_VENDOR_CODE ON pur.pu_vendor(v_vendor_code);
    CREATE INDEX I_VENDOR_CODE_9 ON pur.pu_vendor(v_vendor_code_9,v_address_type_code,most_recent_flag);
    CREATE UNIQUE INDEX SQL120323221702660 ON pur.pu_vendor(v_internal_id,v_person_entity_ind,v_address_type_code,v_timestamp);
    CREATE UNIQUE INDEX SQL120323221702860 ON pur.pu_vendor(name_sort,v_address_type_code,v_timestamp);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_airline_data'
BEGIN TRY
    CREATE TABLE pur.ec_airline_data
    (
        import_id                       VARCHAR(10)                         NULL,
        workgroup_key                   DECIMAL(18,0)                       NULL,
        card_key                        DECIMAL(18,0)                       NULL,
        vendor_id                       VARCHAR(16)                         NULL,
        modification_indicator          VARCHAR(3)                          NULL,
        airline_data_key                DECIMAL(18,0)                       NULL,
        transaction_id                  CHAR(10)                            NULL,
        tsys_tran_code                  CHAR(4)                             NULL,
        departure_date                  SMALLDATETIME                       NULL,
        iata_airport_code               CHAR(3)                             NULL,
        ticket_number                   VARCHAR(13)                         NULL,
        passenger_name                  VARCHAR(20)                         NULL,
        travel_agency_name              VARCHAR(20)                         NULL,
        travel_agency_code              VARCHAR(8)                          NULL,
        number_of_legs                  INTEGER                             NULL,
        last_activity_date              SMALLDATETIME                       NULL,
        refresh_date                    DATETIME2                           NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_AD_ALDKEY ON pur.ec_airline_data(airline_data_key);
    CREATE INDEX I_AD_CARD_KEY ON pur.ec_airline_data(card_key);
    CREATE INDEX I_AD_IMPORT_ID ON pur.ec_airline_data(import_id);
    CREATE INDEX I_AD_PG_NAME ON pur.ec_airline_data(passenger_name);
    CREATE INDEX I_AD_TICKET_NUMBER ON pur.ec_airline_data(ticket_number);
    CREATE INDEX I_AD_TRANS_ID ON pur.ec_airline_data(transaction_id);
    CREATE INDEX I_AD_VENDOR_ID ON pur.ec_airline_data(vendor_id);
    CREATE INDEX I_AD_WORKGROUP_KEY ON pur.ec_airline_data(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- pur.ec_hotel_data'
BEGIN TRY
    CREATE TABLE pur.ec_hotel_data
    (
        import_id                       VARCHAR(10)                         NULL,
        workgroup_key                   DECIMAL(18,0)                       NULL,
        card_key                        DECIMAL(18,0)                       NULL,
        vendor_id                       VARCHAR(16)                         NULL,
        modification_indicator          VARCHAR(3)                          NULL,
        hotel_data_key                  DECIMAL(18,0)                       NULL,
        transaction_id                  CHAR(10)                            NULL,
        tsys_tran_code                  CHAR(4)                             NULL,
        check_in_date                   SMALLDATETIME                       NULL,
        no_show_code                    CHAR(1)                             NULL,
        extra_charges                   VARCHAR(8)                          NULL,
        hotel_folio_number              VARCHAR(25)                         NULL,
        food_beverage_charges           DECIMAL(12,2)                       NULL,
        prepaid_expenses                DECIMAL(12,2)                       NULL,
        daily_room_rate                 DECIMAL(12,2)                       NULL,
        folio_cash_advance              DECIMAL(12,2)                       NULL,
        valet_parking_charges           DECIMAL(12,2)                       NULL,
        minibar_charges                 DECIMAL(12,2)                       NULL,
        laundry_charges                 DECIMAL(12,2)                       NULL,
        phone_charges                   DECIMAL(12,2)                       NULL,
        gift_shop_charges               DECIMAL(12,2)                       NULL,
        movie_charges                   DECIMAL(12,2)                       NULL,
        business_center_charges         DECIMAL(12,2)                       NULL,
        health_club_charges             DECIMAL(12,2)                       NULL,
        other_charges                   DECIMAL(12,2)                       NULL,
        total_tax                       DECIMAL(19,4)                       NULL,
        last_activity_date              SMALLDATETIME                       NULL,
        refresh_date                    DATETIME2                           NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
        version_number              ROWVERSION
    )
    CREATE INDEX I_HD_CARD_KEY ON pur.ec_hotel_data(card_key);
    CREATE INDEX I_HD_HOTELDATAKEY ON pur.ec_hotel_data(hotel_data_key);
    CREATE INDEX I_HD_IMPORT_ID ON pur.ec_hotel_data(import_id);
    CREATE INDEX I_HD_TRANS_ID ON pur.ec_hotel_data(transaction_id);
    CREATE INDEX I_HD_VENDOR_ID ON pur.ec_hotel_data(vendor_id);
    CREATE INDEX I_HD_WORKGROUPKEY ON pur.ec_hotel_data(workgroup_key);
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH