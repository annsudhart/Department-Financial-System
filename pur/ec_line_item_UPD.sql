/***************************************************************************************
Name      : BSO Financial Management Interface - ec_line_item_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for pur.ec_line_item
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

IF OBJECT_ID('pur.ec_line_item_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.ec_line_item_UPD
END

EXEC PrintNow '** CREATE [pur].[ec_line_item_UPD]';
GO
CREATE PROCEDURE    [pur].[ec_line_item_UPD]
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_last_activity_date DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            EXEC PrintNow '-- Find pur.ec_line_item'
                            IF OBJECT_ID('pur.ec_line_item','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('pur.ec_line_item','U') IS NOT NULL DROP TABLE pur.ec_line_item
                                    EXEC PrintNow '-- pur.ec_line_item'
                                    CREATE TABLE pur.ec_line_item
                                    (
                                        import_id                       VARCHAR(10)                         NULL,
                                        workgroup_key                   DECIMAL(18,0)                       NULL,
                                        card_key                        DECIMAL(18,0)                       NULL,
                                        vendor_id                       VARCHAR(16)                         NULL,
                                        modification_indicator          VARCHAR(3)                          NULL,
                                        transaction_id                  VARCHAR(10)                         NULL,
                                        transaction_date                DATE                                NULL,
                                        line_item_sequence              DECIMAL(4,0)                        NULL,
                                        line_item_description           VARCHAR(26)                         NULL,
                                        quantity                        VARCHAR(10)                         NULL,
                                        unit_of_measure                 VARCHAR(10)                         NULL,
                                        unit_cost                       VARCHAR(12)                         NULL,
                                        commodity_code                  VARCHAR(15)                         NULL,
                                        supply_type                     VARCHAR(2)                          NULL,
                                        purchase_invoice_number         VARCHAR(15)                         NULL,
                                        vendor_order_number             VARCHAR(12)                         NULL,
                                        discount_amount                 DECIMAL(19,4)                       NULL,
                                        freight_amount                  DECIMAL(19,4)                       NULL,
                                        duty_amount                     DECIMAL(19,4)                       NULL,
                                        order_date                      DATE                                NULL,
                                        destination_country             VARCHAR(3)                          NULL,
                                        destination_zip                 VARCHAR(9)                          NULL,
                                        origin_zip_code                 VARCHAR(9)                          NULL,
                                        user_id                         VARCHAR(8)                          NULL,
                                        last_activity_date              DATETIME2                           NULL,
                                        refresh_date                    DATETIME2                           NULL,
                                        rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number                  ROWVERSION
                                    )
                                        CREATE INDEX I_CARD_KEY2 ON pur.ec_line_item(card_key)
                                        CREATE INDEX I_IMPORT_CNTRL1 ON pur.ec_line_item(import_id)
                                        CREATE INDEX I_TRANS_ID ON pur.ec_line_item(transaction_id)
                                        CREATE INDEX I_VENDOR_ID ON pur.ec_line_item(vendor_id)
                                        CREATE INDEX I_WORKGROUP_KEY3 ON pur.ec_line_item(workgroup_key)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.last_activity_date) FROM pur.ec_line_item AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);

                            EXEC PrintNow '-- Clearing Temporary Table(s)'
                            IF OBJECT_ID('tempdb..##ec_line_item_UPD','U') IS NOT NULL DROP TABLE tempdb.##ec_line_item_UPD
                            IF OBJECT_ID('tempdb..##ec_purchase_TMP','U') IS NOT NULL DROP TABLE tempdb.##ec_purchase_TMP
                            
                            EXEC PrintNow '-- Creating Temporary Table'
                            SELECT  *
                            INTO    ##ec_line_item_UPD
                            FROM    DW_DB..PUR.EC_LINE_ITEM AS s
                            WHERE   s.last_activity_date > @last_last_activity_date;
                            
                            EXEC PrintNow '-- Updating Existing Records'
                            UPDATE  pur.ec_line_item
                            SET     import_id = s.import_id,
                                    vendor_id = s.vendor_id,
                                    modification_indicator = s.modification_indicator,
                                    transaction_date = s.transaction_date,
                                    line_item_sequence = s.line_item_sequence,
                                    line_item_description = s.line_item_description,
                                    quantity = s.quantity,
                                    unit_of_measure = s.unit_of_measure,
                                    unit_cost = s.unit_cost,
                                    commodity_code = s.commodity_code,
                                    supply_type = s.supply_type,
                                    purchase_invoice_number = s.purchase_invoice_number,
                                    vendor_order_number = s.vendor_order_number,
                                    discount_amount = s.discount_amount,
                                    freight_amount = s.freight_amount,
                                    duty_amount = s.duty_amount,
                                    order_date = s.order_date,
                                    destination_country = s.destination_country,
                                    destination_zip = s.destination_zip,
                                    origin_zip_code = s.origin_zip_code,
                                    user_id = s.user_id,
                                    last_activity_date = s.last_activity_date,
                                    refresh_date = s.refresh_date
                            FROM    pur.ec_line_item AS d
                                    INNER JOIN ##ec_line_item_UPD AS s ON (
                                        d.card_key = s.card_key 
                                        AND d.workgroup_key = s.workgroup_key
                                        AND d.transaction_id = s.transaction_id)
                            WHERE   s.last_activity_date > @last_last_activity_date;

                            EXEC PrintNow '-- Identifying Purchase Transactions'
                            SELECT  c.workgroup_key,
                                    c.card_key,
                                    c.transaction_id
                            INTO    ##ec_purchase_TMP
                            FROM    pur.ec_purchase AS c;

                            EXEC PrintNow '-- Inserting New Records'
                            INSERT INTO pur.ec_line_item(
                                        import_id,
                                        workgroup_key,
                                        card_key,
                                        vendor_id,
                                        modification_indicator,
                                        transaction_id,
                                        transaction_date,
                                        line_item_sequence,
                                        line_item_description,
                                        quantity,
                                        unit_of_measure,
                                        unit_cost,
                                        commodity_code,
                                        supply_type,
                                        purchase_invoice_number,
                                        vendor_order_number,
                                        discount_amount,
                                        freight_amount,
                                        duty_amount,
                                        order_date,
                                        destination_country,
                                        destination_zip,
                                        origin_zip_code,
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
                                                s.line_item_sequence,
                                                s.line_item_description,
                                                s.quantity,
                                                s.unit_of_measure,
                                                s.unit_cost,
                                                s.commodity_code,
                                                s.supply_type,
                                                s.purchase_invoice_number,
                                                s.vendor_order_number,
                                                s.discount_amount,
                                                s.freight_amount,
                                                s.duty_amount,
                                                s.order_date,
                                                s.destination_country,
                                                s.destination_zip,
                                                s.origin_zip_code,
                                                s.user_id,
                                                s.last_activity_date,
                                                s.refresh_date
                                        FROM    ##ec_line_item_UPD AS s
                                                LEFT JOIN pur.ec_line_item AS d ON (
                                                    d.card_key = s.card_key 
                                                    AND d.workgroup_key = s.workgroup_key
                                                    AND d.transaction_id = s.transaction_id)
                                                INNER JOIN ##ec_purchase_TMP AS c ON (
                                                    s.workgroup_key = c.workgroup_key
                                                    AND s.card_key = c.card_key
                                                    AND s.transaction_id = c.transaction_id)
                                        WHERE   d.card_key IS NULL AND d.workgroup_key IS NULL;

                            EXEC PrintNow '-- Clearing Temporary Table(s)'
                            IF OBJECT_ID('tempdb..##ec_line_item_UPD','U') IS NOT NULL DROP TABLE tempdb.##ec_line_item_UPD
                            IF OBJECT_ID('tempdb..##ec_purchase_TMP','U') IS NOT NULL DROP TABLE tempdb.##ec_purchase_TMP
                            
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO