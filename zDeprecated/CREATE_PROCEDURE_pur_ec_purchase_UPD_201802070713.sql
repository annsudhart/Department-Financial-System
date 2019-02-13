/***************************************************************************************
Name      : BSO Financial Management Interface - ec_purchase_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for pur.ec_purchase
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

/*  SETUP ERROR HANDLING **************************************************************/
EXEC PrintNow '** Error Handling Must Already Be Created';
GO

IF OBJECT_ID('pur.ec_purchase_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.ec_purchase_UPD
END

EXEC PrintNow '** CREATE [pur].[ec_purchase_UPD]';
GO
CREATE PROCEDURE    [pur].[ec_purchase_UPD]
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_last_activity_date DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            EXEC PrintNow '-- Find pur.ec_purchase'
                            IF OBJECT_ID('pur.ec_purchase','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('pur.ec_purchase','U') IS NOT NULL DROP TABLE pur.ec_purchase
                                    EXEC PrintNow '-- Creating pur.ec_purchase'
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
                                        reference_number                VARCHAR(23)                         NULL,
                                        point_of_sales_code             VARCHAR(25)                         NULL,
                                        local_tax_amount                DECIMAL(19,4)                   NOT NULL,
                                        local_tax_applicable_code       CHAR(1)                         NOT NULL,
                                        national_sales_tax_amount       DECIMAL(19,4)                       NULL,
                                        other_tax_amount                DECIMAL(19,4)                   NOT NULL,
                                        original_currency_code          VARCHAR(3)                      NOT NULL,
                                        original_currency_amount        DECIMAL(19,4)                   NOT NULL,
                                        settlement_conversion_rate      DECIMAL(15,6)                   NOT NULL,
                                        account_index                   CHAR(10)                            NULL,
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
                                        use_tax_rate                    DECIMAL(5,4)                        NULL,
                                        user_id                         VARCHAR(8)                      NOT NULL,
                                        last_activity_date              SMALLDATETIME                   NOT NULL,
                                        refresh_date                    DATETIME2                       NOT NULL,
                                        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL    NOT NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number              ROWVERSION
                                    )
                                        CREATE INDEX EC_PURCHASE_POSTED_DATE ON pur.ec_purchase(posted_date)
                                        CREATE INDEX I_CARD_KEY3 ON pur.ec_purchase(card_key)
                                        CREATE INDEX I_IMPORT_CNTRL2 ON pur.ec_purchase(import_id)
                                        CREATE INDEX I_REF_NBR ON pur.ec_purchase(reference_number)
                                        CREATE INDEX I_TRANS_ID1 ON pur.ec_purchase(transaction_id)
                                        CREATE INDEX I_VENDOR_ID1 ON pur.ec_purchase(vendor_id)
                                        CREATE INDEX I_WORKGROUP_KEY5 ON pur.ec_purchase(workgroup_key)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.last_activity_date) FROM pur.ec_purchase AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);
                            PRINT @last_last_activity_date

                            EXEC PrintNow '-- Creating Temporary Table'
                            IF OBJECT_ID('tempdb..##ec_purchase_UPD') IS NOT NULL DROP TABLE tempdb.##ec_purchase_UPD
                            SELECT  *
                            INTO    ##ec_purchase_UPD
                            FROM    DW_DB..PUR.EC_PURCHASE AS s
                            WHERE   s.last_activity_date > @last_last_activity_date;
                            
                            EXEC PrintNow '-- Updating Existing Records'
                            UPDATE  pur.ec_purchase
                            SET     import_id = s.import_id,
                                    workgroup_key = s.workgroup_key,
                                    card_key = s.card_key,
                                    vendor_id = s.vendor_id,
                                    modification_indicator = s.modification_indicator,
                                    transaction_id = s.transaction_id,
                                    transaction_date = s.transaction_date,
                                    posted_date = s.posted_date,
                                    transaction_amount = s.transaction_amount,
                                    tax_amount = s.tax_amount,
                                    reference_number = s.reference_number,
                                    point_of_sales_code = s.point_of_sales_code,
                                    local_tax_amount = s.local_tax_amount,
                                    local_tax_applicable_code = s.local_tax_applicable_code,
                                    national_sales_tax_amount = s.national_sales_tax_amount,
                                    other_tax_amount = s.other_tax_amount,
                                    original_currency_code = s.original_currency_code,
                                    original_currency_amount = s.original_currency_amount,
                                    settlement_conversion_rate = s.settlement_conversion_rate,
                                    account_index = s.account_index,
                                    account_code = s.account_code,
                                    posted_use_tax_amount = s.posted_use_tax_amount,
                                    calculated_use_tax_amount = s.calculated_use_tax_amount,
                                    vendor_tax_id = s.vendor_tax_id,
                                    vendor_name = s.vendor_name,
                                    vendor_city = s.vendor_city,
                                    vendor_state = s.vendor_state,
                                    vendor_country = s.vendor_country,
                                    vendor_zip = s.vendor_zip,
                                    vendor_mcc = s.vendor_mcc,
                                    use_tax_rate = s.use_tax_rate,
                                    user_id = s.user_id,
                                    last_activity_date = s.last_activity_date,
                                    refresh_date = s.refresh_date
                            FROM    pur.ec_purchase AS d
                                    INNER JOIN ##ec_purchase_UPD AS s ON (
                                        d.import_id = s.import_id AND
                                        d.workgroup_key = s.workgroup_key AND
                                        d.card_key = s.card_key AND
                                        d.vendor_id = s.vendor_id AND
                                        d.transaction_id = s.transaction_id)
                            WHERE   s.last_activity_date > @last_last_activity_date;

                            EXEC PrintNow '-- Inserting New Records'
                            INSERT INTO pur.ec_purchase(
                                        import_id,
                                        workgroup_key,
                                        card_key,
                                        vendor_id,
                                        modification_indicator,
                                        transaction_id,
                                        transaction_date,
                                        posted_date,
                                        transaction_amount,
                                        tax_amount,
                                        reference_number,
                                        point_of_sales_code,
                                        local_tax_amount,
                                        local_tax_applicable_code,
                                        national_sales_tax_amount,
                                        other_tax_amount,
                                        original_currency_code,
                                        original_currency_amount,
                                        settlement_conversion_rate,
                                        account_index,
                                        account_code,
                                        posted_use_tax_amount,
                                        calculated_use_tax_amount,
                                        vendor_tax_id,
                                        vendor_name,
                                        vendor_city,
                                        vendor_state,
                                        vendor_country,
                                        vendor_zip,
                                        vendor_mcc,
                                        use_tax_rate,
                                        user_id,
                                        last_activity_date,
                                        refresh_date)
                                        SELECT  s.import_id,
                                                s.workgroup_key,
                                                s.card_key,
                                                s.vendor_id,
                                                s.modification_indicator,
                                                s.transaction_id,
                                                s.transaction_date,
                                                s.posted_date,
                                                s.transaction_amount,
                                                s.tax_amount,
                                                s.reference_number,
                                                s.point_of_sales_code,
                                                s.local_tax_amount,
                                                s.local_tax_applicable_code,
                                                s.national_sales_tax_amount,
                                                s.other_tax_amount,
                                                s.original_currency_code,
                                                s.original_currency_amount,
                                                s.settlement_conversion_rate,
                                                s.account_index,
                                                s.account_code,
                                                s.posted_use_tax_amount,
                                                s.calculated_use_tax_amount,
                                                s.vendor_tax_id,
                                                s.vendor_name,
                                                s.vendor_city,
                                                s.vendor_state,
                                                s.vendor_country,
                                                s.vendor_zip,
                                                s.vendor_mcc,
                                                s.use_tax_rate,
                                                s.user_id,
                                                s.last_activity_date,
                                                s.refresh_date
                                        FROM    ##ec_purchase_UPD AS s
                                                LEFT JOIN   pur.ec_purchase AS d ON (
                                                            d.import_id = s.import_id AND
                                                            d.workgroup_key = s.workgroup_key AND
                                                            d.card_key = s.card_key AND
                                                            d.vendor_id = s.vendor_id AND
                                                            d.transaction_id = s.transaction_id)
                                        WHERE   d.import_id IS NULL 
                                                AND d.workgroup_key IS NULL 
                                                AND d.card_key IS NULL 
                                                AND d.vendor_id IS NULL 
                                                AND d.transaction_id IS NULL 
                                                AND s.last_activity_date > @last_last_activity_date 
                                                AND s.account_index LIKE 'MED%';

                            EXEC PrintNow '-- Identifying External Cardholders'
                            IF OBJECT_ID('tempdb..##ec_cardholder_UPD') IS NOT NULL DROP TABLE tempdb.##ec_cardholder_UPD
                            SELECT  d.workgroup_key,
                                    d.card_key
                            INTO    ##ec_cardholder_UPD
                            FROM    pur.ec_purchase AS d
                                    LEFT JOIN   pur.ec_cardholder AS c on (
                                                d.workgroup_key = c.workgroup_key AND
                                                d.card_key = c.card_key)
                            WHERE   c.person_key IS NULL;

                            EXEC PrintNow '-- Pulling External Cardholder Data'
                            INSERT INTO pur.ec_cardholder(
                                        role_key,
                                        person_key,
                                        card_key,
                                        workgroup_key,
                                        description,
                                        campus_id,
                                        affiliate_id,
                                        card_name,
                                        name_comp,
                                        ecch_orig_training_date,
                                        ecch_training_date,
                                        home_department_code,
                                        name_salutary,
                                        organization_name,
                                        mail_drop,
                                        employee_id,
                                        emp_status_cd,
                                        organization,
                                        card_number_suffix,
                                        date_issued,
                                        status,
                                        expiration_month,
                                        expiration_year,
                                        mcc_group,
                                        campus_mail_code,
                                        email_address,
                                        phone_number,
                                        embossed_text,
                                        first_used_date,
                                        last_used_date,
                                        cancellation_date,
                                        department_name,
                                        cancelled_by,
                                        user_id,
                                        last_activity_date,
                                        refresh_date,
                                        CARD_TYPE_DESCRIPTION,
                                        REPORTING_HIERARCHY,
                                        BUYER_CODE,
                                        CREDIT_LIMIT,
                                        SINGLE_PURCHASE_LIMIT,
                                        AUTHORIZATIONS_PER_DAY,
                                        TRANSACTIONS_PER_CYCLE)
                                        SELECT  s.role_key,
                                                s.person_key,
                                                s.card_key,
                                                s.workgroup_key,
                                                s.description,
                                                s.campus_id,
                                                s.affiliate_id,
                                                s.card_name,
                                                s.name_comp,
                                                s.ecch_orig_training_date,
                                                s.ecch_training_date,
                                                s.home_department_code,
                                                s.name_salutary,
                                                s.organization_name,
                                                s.mail_drop,
                                                s.employee_id,
                                                s.emp_status_cd,
                                                s.organization,
                                                s.card_number_suffix,
                                                s.date_issued,
                                                s.status,
                                                s.expiration_month,
                                                s.expiration_year,
                                                s.mcc_group,
                                                s.campus_mail_code,
                                                s.email_address,
                                                s.phone_number,
                                                s.embossed_text,
                                                s.first_used_date,
                                                s.last_used_date,
                                                s.cancellation_date,
                                                s.department_name,
                                                s.cancelled_by,
                                                s.user_id,
                                                s.last_activity_date,
                                                s.refresh_date,
                                                s.CARD_TYPE_DESCRIPTION,
                                                s.REPORTING_HIERARCHY,
                                                s.BUYER_CODE,
                                                s.CREDIT_LIMIT,
                                                s.SINGLE_PURCHASE_LIMIT,
                                                s.AUTHORIZATIONS_PER_DAY,
                                                s.TRANSACTIONS_PER_CYCLE
                                        FROM    DW_DB..PUR.EC_CARDHOLDER AS s
                                                INNER JOIN ##ec_cardholder_UPD AS d ON (
                                                    d.card_key = s.card_key AND
                                                    d.workgroup_key = s.workgroup_key);

                            EXEC PrintNow '-- Clearing Temporary Table(s)'
                            IF OBJECT_ID('tempdb..##ec_purchase_UPD') IS NOT NULL DROP TABLE tempdb.##ec_purchase_UPD
                            IF OBJECT_ID('tempdb..##ec_cardholder_UPD') IS NOT NULL DROP TABLE tempdb.##ec_cardholder_UPD

                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO