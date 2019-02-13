/***************************************************************************************
Name      : BSO Financial Management Interface - ec_cardholder_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for pur.ec_cardholder
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
PRINT '** Error Handling Must Already Be Created';
GO

IF OBJECT_ID('pur.ec_Cardholder_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.ec_cardholder_UPD
END

PRINT '** CREATE [pur].[ec_cardholder_UPD]';
GO
CREATE PROCEDURE    [pur].[ec_cardholder_UPD]
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_last_activity_date DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            -- Create table if it doesn't already exist
                            IF OBJECT_ID('pur.ec_cardholder','U') IS NULL
                                BEGIN
                                    PRINT '-- pur.ec_cardholder'
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
                                    CREATE INDEX EC_CARDHOLDER_CARD_KEY_WRK_KEY ON pur.ec_cardholder(card_key,workgroup_key)
                                    CREATE INDEX I_CARD_KEY1 ON pur.ec_cardholder(card_key)
                                    CREATE INDEX I_CARD_NAME1 ON pur.ec_cardholder(card_name)
                                    CREATE INDEX I_EMPLOYEE_ID1 ON pur.ec_cardholder(employee_id)
                                    CREATE INDEX I_WORKGROUP_KEY1 ON pur.ec_cardholder(workgroup_key)
                                END

                            -- Identify last update and record
                            SELECT @last_last_activity_date = MAX(d.last_activity_date) FROM pur.ec_cardholder AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);

                            -- Delete existing records
                            SET @SQL = 'DELETE FROM pur.ec_cardholder';
                            EXEC(@SQL);
                            
                            -- Add records
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
                                        SELECT  d.role_key,
                                                d.person_key,
                                                d.card_key,
                                                d.workgroup_key,
                                                d.description,
                                                d.campus_id,
                                                d.affiliate_id,
                                                d.card_name,
                                                d.name_comp,
                                                d.ecch_orig_training_date,
                                                d.ecch_training_date,
                                                d.home_department_code,
                                                d.name_salutary,
                                                d.organization_name,
                                                d.mail_drop,
                                                d.employee_id,
                                                d.emp_status_cd,
                                                d.organization,
                                                d.card_number_suffix,
                                                d.date_issued,
                                                d.status,
                                                d.expiration_month,
                                                d.expiration_year,
                                                d.mcc_group,
                                                d.campus_mail_code,
                                                d.email_address,
                                                d.phone_number,
                                                d.embossed_text,
                                                d.first_used_date,
                                                d.last_used_date,
                                                d.cancellation_date,
                                                d.department_name,
                                                d.cancelled_by,
                                                d.user_id,
                                                d.last_activity_date,
                                                d.refresh_date,
                                                d.CARD_TYPE_DESCRIPTION,
                                                d.REPORTING_HIERARCHY,
                                                d.BUYER_CODE,
                                                d.CREDIT_LIMIT,
                                                d.SINGLE_PURCHASE_LIMIT,
                                                d.AUTHORIZATIONS_PER_DAY,
                                                d.TRANSACTIONS_PER_CYCLE
                                        FROM DW_DB..PUR.EC_CARDHOLDER AS d;
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO