/***************************************************************************************
Name      : BSO Financial Management Interface - ec_trans_detail_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for pur.ec_trans_detail
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

IF OBJECT_ID('pur.ec_trans_detail_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.ec_trans_detail_UPD
END

EXEC PrintNow '** CREATE [pur].[ec_trans_detail_UPD]';
GO
CREATE PROCEDURE    [pur].[ec_trans_detail_UPD]
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_last_activity_date DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';

                            EXEC PrintNow '-- Find pur.ec_trans_detail'
                            IF OBJECT_ID('pur.ec_trans_detail','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('pur.ec_trans_detail','U') IS NOT NULL DROP TABLE pur.ec_trans_detail
                                    EXEC PrintNow '-- pur.ec_trans_detail'
                                    CREATE TABLE pur.ec_trans_detail
                                    (
                                        import_id                       VARCHAR(10)                         NULL,
                                        workgroup_key                   NUMERIC(18,0)                       NULL,
                                        card_key                        NUMERIC(18,0)                       NULL,
                                        vendor_id                       VARCHAR(16)                         NULL,
                                        transaction_id                  CHAR(10)                            NULL,
                                        transaction_sequence            INTEGER                             NULL,
                                        transaction_date                DATE                                NULL,
                                        account_index                   VARCHAR(10)                         NULL,
                                        fund_code                       VARCHAR(6)                          NULL,
                                        organization_code               VARCHAR(6)                          NULL,
                                        program_code                    VARCHAR(6)                          NULL,
                                        account_code                    VARCHAR(6)                          NULL,
                                        location_code                   VARCHAR(6)                          NULL,
                                        transaction_amount              NUMERIC(19,4)                       NULL,
                                        transaction_description         VARCHAR(35)                         NULL,
                                        equipment_flag                  CHAR(1)                             NULL,
                                        use_tax_flag                    CHAR(1)                             NULL,
                                        use_tax_amount                  NUMERIC(19,4)                       NULL,
                                        comment                         VARCHAR(255)                        NULL,
                                        user_id                         VARCHAR(8)                          NULL,
                                        last_activity_date              DATETIME2                           NULL,
                                        refresh_date                    DATETIME2                           NULL,
                                        rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number                  ROWVERSION
                                    )
                                    CREATE INDEX I_ACCOUNT_INDEX1 ON pur.ec_trans_detail(account_index)
                                    CREATE INDEX I_ACCT_CODE1 ON pur.ec_trans_detail(account_code)
                                    CREATE INDEX I_CARD_KEY4 ON pur.ec_trans_detail(card_key)
                                    CREATE INDEX I_FUND_CODE1 ON pur.ec_trans_detail(fund_code)
                                    CREATE INDEX I_IMPORT_CNTRL3 ON pur.ec_trans_detail(import_id)
                                    CREATE INDEX I_LOC_CODE1 ON pur.ec_trans_detail(location_code)
                                    CREATE INDEX I_ORGN_CODE1 ON pur.ec_trans_detail(organization_code)
                                    CREATE INDEX I_PROG_CODE1 ON pur.ec_trans_detail(program_code)
                                    CREATE INDEX I_TRANSACTION_DES1 ON pur.ec_trans_detail(transaction_description)
                                    CREATE INDEX I_TRANS_ID2 ON pur.ec_trans_detail(transaction_id)
                                    CREATE INDEX I_VENDOR_ID2 ON pur.ec_trans_detail(vendor_id)
                                    CREATE INDEX I_WORKGROUP_KEY6 ON pur.ec_trans_detail(workgroup_key)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.last_activity_date) FROM pur.ec_trans_detail AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);

                            EXEC PrintNow '-- Clearing Temporary Table(s)'
                            IF OBJECT_ID('tempdb..##ec_trans_detail_UPD','U') IS NOT NULL DROP TABLE tempdb.##ec_trans_detail_UPD
                            IF OBJECT_ID('tempdb..##ec_purchase_TMP','U') IS NOT NULL DROP TABLE tempdb.##ec_purchase_TMP
                            
                            EXEC PrintNow '-- Creating Temporary Table'
                            SELECT  *
                            INTO    ##ec_trans_detail_UPD
                            FROM    DW_DB..PUR.EC_TRANS_DETAIL AS s
                            WHERE   s.last_activity_date > @last_last_activity_date;
                            
                            EXEC PrintNow '-- Updating Existing Records'
                            UPDATE  pur.ec_trans_detail
                            SET     import_id = s.import_id,
                                    workgroup_key = s.workgroup_key,
                                    card_key = s.card_key,
                                    vendor_id = s.vendor_id,
                                    transaction_id = s.transaction_id,
                                    transaction_sequence = s.transaction_sequence,
                                    transaction_date = s.transaction_date,
                                    account_index = s.account_index,
                                    fund_code = s.fund_code,
                                    organization_code = s.organization_code,
                                    program_code = s.program_code,
                                    account_code = s.account_code,
                                    location_code = s.location_code,
                                    transaction_amount = s.transaction_amount,
                                    transaction_description = s.transaction_description,
                                    equipment_flag = s.equipment_flag,
                                    use_tax_flag = s.use_tax_flag,
                                    use_tax_amount = s.use_tax_amount,
                                    comment = s.comment,
                                    user_id = s.user_id,
                                    last_activity_date = s.last_activity_date,
                                    refresh_date = s.refresh_date
                            FROM    pur.ec_trans_detail AS d
                                    INNER JOIN ##ec_trans_detail_UPD AS s ON (
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
                            INSERT INTO pur.ec_trans_detail(
                                        import_id,
                                        workgroup_key,
                                        card_key,
                                        vendor_id,
                                        transaction_id,
                                        transaction_sequence,
                                        transaction_date,
                                        account_index,
                                        fund_code,
                                        organization_code,
                                        program_code,
                                        account_code,
                                        location_code,
                                        transaction_amount,
                                        transaction_description,
                                        equipment_flag,
                                        use_tax_flag,
                                        use_tax_amount,
                                        comment,
                                        user_id,
                                        last_activity_date,
                                        refresh_date)
                                        SELECT  s.import_id,
                                                s.workgroup_key,
                                                s.card_key,
                                                s.vendor_id,
                                                s.transaction_id,
                                                s.transaction_sequence,
                                                s.transaction_date,
                                                s.account_index,
                                                s.fund_code,
                                                s.organization_code,
                                                s.program_code,
                                                s.account_code,
                                                s.location_code,
                                                s.transaction_amount,
                                                s.transaction_description,
                                                s.equipment_flag,
                                                s.use_tax_flag,
                                                s.use_tax_amount,
                                                s.comment,
                                                s.user_id,
                                                s.last_activity_date,
                                                s.refresh_date
                                        FROM    ##ec_trans_detail_UPD AS s
                                                LEFT JOIN pur.ec_trans_detail AS d ON (
                                                    d.card_key = s.card_key 
                                                    AND d.workgroup_key = s.workgroup_key
                                                    AND d.transaction_id = s.transaction_id)
                                                INNER JOIN ##ec_purchase_TMP AS c ON (
                                                    s.workgroup_key = c.workgroup_key
                                                    AND s.card_key = c.card_key
                                                    AND s.transaction_id = c.transaction_id)
                                        WHERE   d.card_key IS NULL AND d.workgroup_key IS NULL;

                            EXEC PrintNow '-- Clearing Temporary Table(s)'
                            IF OBJECT_ID('tempdb..##ec_trans_detail_UPD','U') IS NOT NULL DROP TABLE tempdb.##ec_trans_detail_UPD
                            IF OBJECT_ID('tempdb..##ec_purchase_TMP','U') IS NOT NULL DROP TABLE tempdb.##ec_purchase_TMP
                            
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO