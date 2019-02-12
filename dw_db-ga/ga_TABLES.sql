/***************************************************************************************
Name      : Medicine Financial System - GA Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Replicates GA Schema
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
IF SCHEMA_ID('ga') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA ga');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'General Accounting', 
            @level0type=N'SCHEMA',
            @level0name=N'ga';
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

        SET @schemaName = 'ga'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='f_ledger_activity'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='la_ledger_indicator'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 3
        BEGIN
            SET @objectName ='idx_ledger_indicator'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 4
        BEGIN
            SET @objectName ='idx_field_indicator'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 5
        BEGIN
            SET @objectName ='idx_process_code'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 6
        BEGIN
            SET @objectName ='idx_debit_credit'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 7
        BEGIN
            SET @objectName ='f_ledger_transaction'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 8
        BEGIN
            SET @objectName ='idx_if_id'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 9
        BEGIN
            SET @objectName ='idx_lt_encumbrance_action'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 10
        BEGIN
            SET @objectName ='idx_lt_encumbrance_type'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 11
        BEGIN
            SET @objectName ='idx_lt_encumbrance_doc_type'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 12
        BEGIN
            SET @objectName ='idx_auto_journal_reversal'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 13
        BEGIN
            SET @objectName ='f_document_type'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 14
        BEGIN
            SET @objectName ='idx_dt_sequence_number'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 15
        BEGIN
            SET @objectName ='f_period_index'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 16
        BEGIN
            SET @objectName ='f_period_fund'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 17
        BEGIN
            SET @objectName ='f_period_fund_type'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 18
        BEGIN
            SET @objectName ='idx_pft_predecessor'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 19
        BEGIN
            SET @objectName ='idx_pft_predecessor'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 20
        BEGIN
            SET @objectName ='f_period_organization'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 21
        BEGIN
            SET @objectName ='f_period_location'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 22
        BEGIN
            SET @objectName ='f_period_account'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 23
        BEGIN
            SET @objectName ='f_period_account_type'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 24
        BEGIN
            SET @objectName ='f_period_program'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 25
        BEGIN
            SET @objectName = 'f_ifoapal'
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

PRINT '--ga.f_ledger_activity'
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
            la_amount                       DECIMAL(19, 4)                  NOT NULL,
            la_rule_sequence                SMALLINT                        NOT NULL,
            la_process_code                 CHAR(4)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            la_debit_credit                 CHAR(1)                             NULL,
            full_accounting_period          INT                                 NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX I_LDGR_ACT_IFOAPAL ON ga.f_ledger_activity(if_id);
    CREATE INDEX I_LDGR_ACT_IX1 ON ga.f_ledger_activity(la_ledger_indicator,if_id);
    CREATE INDEX I_LDGR_ACT_LT_ID ON ga.f_ledger_activity(la_ledger_indicator,lt_id);
    CREATE INDEX I_LDGR_ACT_TRANS ON ga.f_ledger_activity(lt_id);
    CREATE INDEX I_LDGR_INDICATOR ON ga.f_ledger_activity(accounting_period,la_ledger_indicator,la_field_indicator);
    CREATE INDEX I_LDGR_PD_INDICAT1 ON ga.f_ledger_activity(full_accounting_period,la_ledger_indicator,la_field_indicator);
    CREATE UNIQUE INDEX SQL130510172315220 ON ga.f_ledger_activity(la_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_ledger_indicator'
BEGIN TRY
    CREATE TABLE ga.idx_ledger_indicator
        (
            la_ledger_indicator             CHAR(1)                         NOT NULL,
            la_ledger_name                  VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_ledger_indicator          PRIMARY KEY CLUSTERED(la_ledger_indicator)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_ledger_indicator (default data)'
BEGIN TRY
    INSERT INTO ga.idx_ledger_indicator
        (
            la_ledger_indicator,
            la_ledger_name
        )
        VALUES
        ('E','Encumbrance Ledger'),
        ('G','General Ledger'),
        ('O','Operating Ledger');
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_field_indicator'
BEGIN TRY
    CREATE TABLE ga.idx_field_indicator
        (
            la_ledger_indicator             CHAR(1)                         NOT NULL,
            la_field_indicator              CHAR(2)                         NOT NULL,
            la_field_name                   VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_field_indicator          PRIMARY KEY CLUSTERED(la_field_indicator,la_ledger_indicator)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_field_indicator (default data)'
BEGIN TRY
    INSERT INTO ga.idx_field_indicator
        (
            la_ledger_indicator,
            la_field_indicator,
            la_field_name
        )
        VALUES
        ('G','01','Debit Amount'),
        ('E','01','Original Encumbrance Amount'),
        ('G','02','Credit Amount'),
        ('E','02','Encumbrance Adjustment Amount'),
        ('O','03','Expenditure Amount'),
        ('E','03','Encumbrance Liquidation Amount'),
        ('O','04','Encumbrance Amount');
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_process_code'
BEGIN TRY
    CREATE TABLE ga.idx_process_code
        (
            la_process_code                 CHAR(4)                         NOT NULL,
            la_process_name                 VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_process_code             PRIMARY KEY CLUSTERED(la_process_code)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_process_code (default data)'
BEGIN TRY
    INSERT INTO ga.idx_process_code
        (
            la_process_code,
            la_process_name
        )
        VALUES
        ('E010','Post Original Encumbrance'),
        ('E011','Post Original Reservation'),
        ('E012','Post Orig/Adj Encumbrance E012'),
        ('E013','Post Orig/Adj Encumbrance E013'),
        ('E015','Post Orig/Adj Encumbrance E015'),
        ('E016','Post Orig/Adj Encumbrance E016'),
        ('E017','Post Orig/Adj Encumbrance E017'),
        ('E018','Post Orig/Adj Encumbrance E018'),
        ('E020','Post Adjustments'),
        ('E030','Post Liquidations - P/T from Input'),
        ('E031','Post Liquidations - Partial'),
        ('E032','Post Liquidations - Total'),
        ('E090','Year End Carry Forward to Period 0'),
        ('E110','Post Orig Encumbrance Use Dcmtnt No'),
        ('E111','Post Orig Rsrvtn Use Dcmt No.'),
        ('E112','Post Orig Adj to Enc Use Dcmt No.'),
        ('E113','Post Orig Adj to Rsrvn use Dcmnt No'),
        ('E115','Post Orig Encumbrance Use Encmbr No'),
        ('E116','Post Orig Reservation Use Enc. No'),
        ('E117','Post Orig Adj to Encmbrc Use Enc No'),
        ('E118','Post Orig Adj to Reservation-Enc No'),
        ('G010','Direct Posting to G/L'),
        ('G011','Beg Bal Posting to G/L'),
        ('G020','Post Claim on Cash Input Fund'),
        ('G021','Post Claim Same; Cash Opp Bank Fund'),
        ('G022','Post Claim on Cash Same - Bank Fund'),
        ('G023','Post Claim on Cash Opp - Bank Fund'),
        ('G024','Post Cash Same - Bank Fund'),
        ('G025','Post Cash Opp - Bank Fund'),
        ('G026','Post Input Account - Bank Fund'),
        ('G030','Post Interfund Dr-Due to;Cr-Due Frm'),
        ('G031','Post Interfund Due from Opposite'),
        ('G032','Post Interfund Due to Opposite'),
        ('G033','Post Interchart D-Due to; C-Due Frm'),
        ('G034','Post Interchart Due from opposite'),
        ('G035','Post Interchart Due to opposite'),
        ('I011','Interpret Disbursement AType + =DR'),
        ('I012','Interpret Disbursement Acct + = Dr'),
        ('I021','Interpret Receipts Atype + = CR'),
        ('I022','Interpret Receipts Acct + = CR'),
        ('I031','Interpret Incr/Decr AType + = DR'),
        ('I032','Interpret Incr./Decr. Acct + = Dr'),
        ('I040','Interpret Contra Accts. Atyp Op'),
        ('I050','Interpret Contra Accts. Acct Op'),
        ('I061','Interpret Dr/Cr on Input Atyp'),
        ('I062','Interpret Dr/Cr on Input Acct'),
        ('O010','Post Permanent Adopted Budget'),
        ('O011','Post Temporary Adopted Budget'),
        ('O015','Post Prior Year Control Accounts'),
        ('O020','Post Permanent Budget Adjustments'),
        ('O021','Post Temporary Budget Adjustments'),
        ('O025','Post Prior Year Control Accounts'),
        ('O030','Post Operatng ledger'),
        ('O031','Post Ytd Actual; Cap; No Grant'),
        ('O040','Adjust Operating Ledger Encumbrance'),
        ('Y010','Post Accrued Accounts Payable'),
        ('Y020','Post Accrued Accounts Receivable');
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_debit_credit'
BEGIN TRY
    CREATE TABLE ga.idx_debit_credit
        (
            la_debit_credit                 CHAR(1)                         NOT NULL,
            la_debit_credit_name            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_debit_credit             PRIMARY KEY CLUSTERED(la_debit_credit)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_debit_credit (default data)'
BEGIN TRY
    INSERT INTO ga.idx_debit_credit
        (
            la_debit_credit,
            la_debit_credit_name
        )
        VALUES
        ('+','Debit'),
        ('-','Credit'),
        ('C','Credit'),
        ('D','Debit');
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_ledger_transaction'
BEGIN TRY
    CREATE TABLE ga.f_ledger_transaction
        (
            lt_id                           CHAR(12)                        NOT NULL,
            if_id                           CHAR(12)                        NOT NULL,
            dt_sequence_number              SMALLINT                        NOT NULL,
            lt_document_number              CHAR(8)                         NOT NULL,
            lt_transaction_date             DATE                            NOT NULL,
            lt_item_number                  SMALLINT                        NOT NULL,
            lt_sequence_number              SMALLINT                        NOT NULL,
            lt_budget_period                SMALLINT                        NOT NULL,
            lt_amount                       DECIMAL(19,4)                   NOT NULL,
            lt_description                  VARCHAR(35)                     NOT NULL,
            lt_document_reference_number    CHAR(10)                        NOT NULL,
            lt_debit_credit_indicator       CHAR(1)                         NOT NULL,
            lt_activity_date                DATETIME2(7)                    NOT NULL,
            lt_encumbrance_number           CHAR(8)                         NOT NULL,
            lt_encumbrance_action           CHAR(1)                         NOT NULL,
            lt_encumbrance_item             SMALLINT                        NOT NULL,
            lt_encumbrance_sequence         SMALLINT                        NOT NULL,
            lt_encumbrance_type             CHAR(1)                         NOT NULL,
            v_vendor_code                   CHAR(10)                        NOT NULL,
            lt_rule_class_code              CHAR(4)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            lt_encumbrance_doc_type         VARCHAR(3)                          NULL,
            full_accounting_period          INT                                 NULL,
            bank_account_code               VARCHAR(2)                          NULL,
            auto_journal_id                 VARCHAR(3)                          NULL,
            auto_journal_reversal           CHAR(1)                             NULL,
            description_privy               VARCHAR(35)                         NULL,
            document_reference_no_privy     VARCHAR(10)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
    CREATE INDEX F_LEDGER_TRANSACTION_ACC_P_LT_ID ON ga.f_ledger_transaction(full_accounting_period, lt_id);
    CREATE INDEX F_LEDGER_TRANSACTION_FULL_ACC_P ON ga.f_ledger_transaction(full_accounting_period);
    CREATE UNIQUE INDEX IDX008130419510000 ON ga.f_ledger_transaction(lt_id, dt_sequence_number, lt_rule_class_code);
    CREATE INDEX I_LDGR_TRANS_ACCT1 ON ga.f_ledger_transaction(accounting_period);
    CREATE INDEX I_LDGR_TRANS_DATE ON ga.f_ledger_transaction(lt_transaction_date);
    CREATE INDEX I_LDGR_TRANS_DOC ON ga.f_ledger_transaction(lt_document_reference_number);
    CREATE UNIQUE INDEX I_LDGR_TRANS_IX1_ ON ga.f_ledger_transaction(lt_id, lt_description, lt_document_number, lt_transaction_date, lt_rule_class_code, dt_sequence_number);
    CREATE INDEX I_LEDGER_TRANS_PD ON ga.f_ledger_transaction(lt_document_number, full_accounting_period);
    CREATE UNIQUE INDEX I_LT_ID ON ga.f_ledger_transaction(lt_id, dt_sequence_number);
    CREATE INDEX I_VENDOR_CODE ON ga.f_ledger_transaction(v_vendor_code);
    CREATE UNIQUE INDEX SQL130510172317590 ON ga.f_ledger_transaction(lt_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_if_id'
BEGIN TRY
    CREATE TABLE ga.idx_if_id
        (
            if_id                           CHAR(12)                        NOT NULL,
            if_id_name                      VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_if_id                    PRIMARY KEY CLUSTERED(if_id)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_if_id (default data)'
BEGIN TRY
    INSERT INTO ga.idx_if_id
        (
            if_id,
            if_id_name
        )
        VALUES
        ('0001','Agreements'),
        ('0002','Bids'),
        ('0003','Invoices'),
        ('0004','Purchase Oders'),
        ('0005','Requests'),
        ('0006','Encumbrances'),
        ('0007','Journal Vouchers'),
        ('0008','Check Disbursements'),
        ('0009','Check Cancellation'),
        ('0010','Reestablish Checks'),
        ('0011','Credit Memo'),
        ('0012','Auto Journals'),
        ('0013','Trip'),
        ('0014','Reconciliation'),
        ('0015','Advance'),
        ('0016','Expense'),
        ('0017','Travel Invoice'),
        ('0018','Commonity'),
        ('0019','Returns'),
        ('0020','Travel Event'),
        ('0021','Budget/Current Transfer Of Funds'),
        ('0022','Budget/Permanent Transfer Of Funds'),
        ('0023','Automated Clearing House Credit'),
        ('0024','Automated Clearing House Cr-Cancel'),
        ('0025','Fax')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_action'
BEGIN TRY
    CREATE TABLE ga.idx_lt_encumbrance_action
        (
            lt_encumbrance_action           CHAR(1)                         NOT NULL,
            lt_encumbrance_action_name      VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_lt_encumbrance_action                    PRIMARY KEY CLUSTERED(lt_encumbrance_action)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_action (default data)'
BEGIN TRY
    INSERT INTO ga.idx_lt_encumbrance_action
        (
            lt_encumbrance_action,
            lt_encumbrance_action_name
        )
        VALUES
        ('P','Partial'),
        ('T','Total')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_type'
BEGIN TRY
    CREATE TABLE ga.idx_lt_encumbrance_type
        (
            lt_encumbrance_type             CHAR(1)                         NOT NULL,
            lt_encumbrance_type_name        VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_lt_encumbrance_type      PRIMARY KEY CLUSTERED(lt_encumbrance_type)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_type (default data)'
BEGIN TRY
    INSERT INTO ga.idx_lt_encumbrance_type
        (
            lt_encumbrance_type,
            lt_encumbrance_type_name
        )
        VALUES
        ('C','Commit - Roll Over From Prior Year'),
        ('E','Standard Encumbrance'),
        ('G','General'),
        ('L','Payroll'),
        ('M','Memo'),
        ('P','Purchase Order'),
        ('R','Requisition'),
        ('T','Travel')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_doc_type'
BEGIN TRY
    CREATE TABLE ga.idx_lt_encumbrance_doc_type
        (
            lt_encumbrance_doc_type         VARCHAR(3)                      NOT NULL,
            lt_encumbrance_doc_type_name    VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_lt_encumbrance_doc_type  PRIMARY KEY CLUSTERED(lt_encumbrance_doc_type)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_lt_encumbrance_doc_type (default data)'
BEGIN TRY
    INSERT INTO ga.idx_lt_encumbrance_doc_type
        (
            lt_encumbrance_doc_type,
            lt_encumbrance_doc_type_name
        )
        VALUES
        ('ACC','Automated Clearing House Cr-Cancel'),
        ('ACH','Automated Clearing House Credit'),
        ('ADV','Advance'),
        ('AGR','Agreements'),
        ('AJV','Auto Journals'),
        ('BID','Bids'), /*SHOULD BE 'BIDS' PER DATALINK*/
        ('BSC','Budget/Current Transfer Of Funds'),
        ('BSP','Budget/Permanent Transfer Of Funds'),
        ('CAN','Check Cancellation'),
        ('CMD','Commonity'),
        ('CRD','Credit Memo'),
        ('DIS','Check Disbursements'),
        ('ENC','Encumbrances'),
        ('EVN','Travel Event'),
        ('EXP','Expense'),
        ('FAX','Fax'),
        ('INV','Invoices'),
        ('JV','Journal Vouchers'),
        ('PUR','Purchase Oders'),
        ('RCN','Reconciliation'),
        ('RES','Reestablish Checks'),
        ('RQT','Requests'),
        ('RTN','Returns'),
        ('TIV','Travel Invoice'),
        ('TRP','Trip')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_auto_journal_reversal'
BEGIN TRY
    CREATE TABLE ga.idx_auto_journal_reversal
        (
            auto_journal_reversal           CHAR(1)                         NOT NULL,
            auto_journal_reversal_name      VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_auto_journal_reversal  PRIMARY KEY CLUSTERED(auto_journal_reversal)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_auto_journal_reversal (default data)'
BEGIN TRY
    INSERT INTO ga.idx_auto_journal_reversal
        (
            auto_journal_reversal,
            auto_journal_reversal_name
        )
        VALUES
        ('N','No')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_document_type'
BEGIN TRY
    CREATE TABLE ga.f_document_type
        (
            dt_sequence_number              SMALLINT                        NOT NULL,
            dt_document_type                CHAR(3)                         NOT NULL,
            dt_title                        VARCHAR(35)                     NOT NULL,
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
        CREATE INDEX INDX_DOCUMENT_TYP2 ON ga.f_document_type(dt_document_type);
        CREATE UNIQUE INDEX SQL130510203817060 ON ga.f_document_type(dt_sequence_number);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_dt_sequence_number'
BEGIN TRY
    CREATE TABLE ga.idx_dt_sequence_number
        (
            dt_sequence_number              SMALLINT                        NOT NULL,
            dt_sequence_number_name         VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_dt_sequence_number                    PRIMARY KEY CLUSTERED(dt_sequence_number)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_dt_sequence_number (default data)'
/*Same as idx_if_id but uses SMALLINT rather than CHAR(4) as PK*/
BEGIN TRY
    INSERT INTO ga.idx_dt_sequence_number
        (
            dt_sequence_number,
            dt_sequence_number_name
        )
        VALUES
        (1,'Agreements'),
        (2,'Bids'),
        (3,'Invoices'),
        (4,'Purchase Oders'),
        (5,'Requests'),
        (6,'Encumbrances'),
        (7,'Journal Vouchers'),
        (8,'Check Disbursements'),
        (9,'Check Cancellation'),
        (10,'Reestablish Checks'),
        (11,'Credit Memo'),
        (12,'Auto Journals'),
        (13,'Trip'),
        (14,'Reconciliation'),
        (15,'Advance'),
        (16,'Expense'),
        (17,'Travel Invoice'),
        (18,'Commonity'),
        (19,'Returns'),
        (20,'Travel Event'),
        (21,'Budget/Current Transfer Of Funds'),
        (22,'Budget/Permanent Transfer Of Funds'),
        (23,'Automated Clearing House Credit'),
        (24,'Automated Clearing House Cr-Cancel'),
        (25,'Fax')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_index'
BEGIN TRY
    CREATE TABLE ga.f_period_index
        (
            pi_account_index                CHAR(10)                        NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pi_effective_date               DATE                            NOT NULL,
            pi_title                        CHAR(35)                        NOT NULL,
            pf_fund                         CHAR(6)                         NOT NULL,
            po_organization                 CHAR(6)                         NOT NULL,
            pa_account                      CHAR(6)                         NOT NULL,
            pp_program                      CHAR(6)                         NOT NULL,
            pl_location                     CHAR(6)                         NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX F_PERIOD_INDEX_FACC_PI_ACC ON ga.f_period_index(full_accounting_period, pi_account_index);
        CREATE INDEX I_ACCT_INDEX_TITLE ON ga.f_period_index(pi_title);
        CREATE INDEX I_FULL_ACCTG ON ga.f_period_index(full_accounting_period,pi_title,pi_account_index);
        CREATE INDEX I_INDEX_ACCT ON ga.f_period_index(pa_account);
        CREATE INDEX I_INDEX_FUND ON ga.f_period_index(pf_fund);
        CREATE INDEX I_INDEX_LOC ON ga.f_period_index(pl_location);
        CREATE INDEX I_INDEX_ORG ON ga.f_period_index(po_organization);
        CREATE INDEX I_INDEX_PROG ON ga.f_period_index(pp_program);
        CREATE UNIQUE INDEX SQL130510172337480 ON ga.f_period_index(pi_account_index, full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_fund'
BEGIN TRY
    CREATE TABLE ga.f_period_fund
        (
            pf_fund                         CHAR(6)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pft_fund_type                   CHAR(2)                         NOT NULL,
            pf_effective_date               DATE                            NOT NULL,
            pf_predecessor                  CHAR(6)                         NOT NULL,
            pf_title                        CHAR(35)                        NOT NULL,
            pf_grant_contract               CHAR(35)                        NOT NULL,
            pf_indirect_cost_code           CHAR(6)                         NOT NULL,
            pf_standard_percent             DECIMAL(7,4)                    NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_FUND_PRED ON ga.f_period_fund(pf_predecessor);
        CREATE INDEX I_FUND_TITLE ON ga.f_period_fund(pf_title);
        CREATE INDEX I_FUND_TYPE ON ga.f_period_fund(pft_fund_type);
        CREATE UNIQUE INDEX I_PERIOD_FUND_IX1 ON ga.f_period_fund(pf_fund,full_accounting_period,pf_title);
        CREATE UNIQUE INDEX SQL130510172403820 ON ga.f_period_fund(pf_fund,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_fund_type'
BEGIN TRY
    CREATE TABLE ga.f_period_fund_type
        (
            pft_fund_type                   CHAR(2)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pft_effective_date              DATE                            NOT NULL,
            pft_predecessor                 CHAR(6)                         NOT NULL,
            pft_title                       CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_FUND_TYPE_PRED ON ga.f_period_fund_type(pft_predecessor);
        CREATE INDEX I_FUND_TYPE_TITLE ON ga.f_period_fund_type(pft_title);
        CREATE UNIQUE INDEX SQL130510172332450 ON ga.f_period_fund_type(pft_fund_type,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_pft_predecessor'
BEGIN TRY
    CREATE TABLE ga.idx_pft_predecessor
        (
            pft_predecessor_code            CHAR(2)                         NOT NULL,
            pft_predecessor_name            VARCHAR(35)                         NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_idx_pft_predecessor             PRIMARY KEY CLUSTERED(pft_predecessor_code)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.idx_pft_predecessor (default data)'
/*Same as idx_if_id but uses SMALLINT rather than CHAR(4) as PK*/
BEGIN TRY
    INSERT INTO ga.idx_pft_predecessor
        (
            pft_predecessor_code,
            pft_predecessor_name
        )
        VALUES
        ('01','Agency Predecessor Fund Type'),
        ('02','Current Funds Predecessor Fund Type'),
        ('03','Plant Funds Predecessor Fund Type'),
        ('04','Loan Funds Predecessor Fund Type'),
        ('1A','Agency Funds'),
        ('1B','Ofc o/the President Funds (Loc O)'),
        ('2A','Current Unrestricted Funds'),
        ('2B','Current Restricted Funds'),
        ('3A','Unexpended Plant Funds'),
        ('3B','Retirement of Indebtedness'),
        ('3C','Investment in Plant'),
        ('3D','Renewals & Replacement'),
        ('4A','University Loan Funds'),
        ('4B','Univ Matching Loan Fds-Fed Progrs')
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_organization'
BEGIN TRY
    CREATE TABLE ga.f_period_organization
        (
            po_organization                 CHAR(6)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            po_effective_date               DATE                            NOT NULL,
            po_finance_manager              CHAR(35)                        NOT NULL,
            po_predecessor                  CHAR(6)                         NOT NULL,
            po_title                        CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_ORG_PRED ON ga.f_period_organization(po_predecessor);
        CREATE INDEX I_ORG_TITLE ON ga.f_period_organization(po_title);
        CREATE UNIQUE INDEX I_PERIOD_ORG_IX1 ON ga.f_period_organization(po_organization,full_accounting_period,po_title);
        CREATE UNIQUE INDEX SQL130510172346560 ON ga.f_period_organization(po_organization,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO


PRINT '--ga.f_period_location'
BEGIN TRY
    CREATE TABLE ga.f_period_location
        (
            pl_location                     CHAR(6)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pl_effective_date               DATE                            NOT NULL,
            pl_predecessor                  CHAR(6)                         NOT NULL,
            pl_title                        CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_LOCATION_PRED ON ga.f_period_location(pl_predecessor);
        CREATE INDEX I_LOCATION_TITLE ON ga.f_period_location(pl_title);
        CREATE UNIQUE INDEX SQL130510172342210 ON ga.f_period_location(pl_location,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_account'
BEGIN TRY
    CREATE TABLE ga.f_period_account
        (
            pa_account                      CHAR(6)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pat_account_type                CHAR(2)                         NOT NULL,
            pa_effective_date               DATE                            NOT NULL,
            pa_normal_balance_indicator     CHAR(1)                         NOT NULL,
            pa_predecessor                  CHAR(6)                         NOT NULL,
            pa_title                        CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_ACCOUNT_PRED ON ga.f_period_account(pa_predecessor);
        CREATE INDEX I_ACCOUNT_TITLE ON ga.f_period_account(pa_title);
        CREATE INDEX I_ACCOUNT_TYPE ON ga.f_period_account(pat_account_type);
        CREATE UNIQUE INDEX I_PERIOD_ACCT_IX1 ON ga.f_period_account(pa_account,full_accounting_period,pa_title);
        CREATE UNIQUE INDEX SQL130510172322720 ON ga.f_period_account(pa_account,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_account_type'
BEGIN TRY
    CREATE TABLE ga.f_period_account_type
        (
            pat_account_type                CHAR(2)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pat_effective_date              DATE                            NOT NULL,
            pat_predecessor                 CHAR(6)                         NOT NULL,
            pat_title                       CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_ACCOUNT_TYPE_PR1 ON ga.f_period_account_type(pat_predecessor);
        CREATE INDEX I_ACCOUNT_TYPE_TI1 ON ga.f_period_account_type(pat_title);
        CREATE UNIQUE INDEX SQL130510172327370 ON ga.f_period_account_type(pat_account_type,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_period_program'
BEGIN TRY
    CREATE TABLE ga.f_period_program
        (
            pp_program                      CHAR(6)                         NOT NULL,
            accounting_period               SMALLINT                        NOT NULL,
            pp_effective_date               DATE                            NOT NULL,
            pp_predecessor                  CHAR(6)                         NOT NULL,
            pp_title                        CHAR(35)                        NOT NULL,
            refresh_date                    DATETIME2(7)                    NOT NULL,
            full_accounting_period          INT                             NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                   DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
        )
        CREATE INDEX I_PROGRAM_PRED ON ga.f_period_program(pp_predecessor);
        CREATE INDEX I_PROGRAM_TITLE ON ga.f_period_program(pp_title);
        CREATE UNIQUE INDEX SQL130510172350510 ON ga.f_period_program(pp_program,full_accounting_period);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--ga.f_ifoapal'
BEGIN TRY
    IF OBJECT_ID('ga.f_ifoapal','U') IS NOT NULL DROP TABLE ga.f_ifoapal
    EXEC PrintNow '-- ga.f_ifoapal'
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
            full_accounting_period          INTEGER                         NOT NULL,
            end_full_accounting_period      INTEGER                         NOT NULL,
            ledger_date                     DATE                            NOT NULL,
            end_ledger_date                 DATE                            NOT NULL,
            account_type                    CHAR(2)                         NOT NULL,
            fund_type                       CHAR(2)                         NOT NULL,
            current_mo_budget_amount        NUMERIC(19,4)                   NOT NULL,
            current_mo_financial_amount     NUMERIC(19,4)                   NOT NULL,
            current_mo_encumbrance_amount   NUMERIC(19,4)                   NOT NULL,
            prior_yrs_budget_amount         NUMERIC(19,4)                   NOT NULL,
            prior_yrs_financial_amount      NUMERIC(19,4)                   NOT NULL,
            prior_mos_budget_amount         NUMERIC(19,4)                   NOT NULL,
            prior_mos_financial_amount      NUMERIC(19,4)                   NOT NULL,
            prior_mos_encumbrance_amount    NUMERIC(19,4)                   NOT NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
            version_number                  ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                   DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2))
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
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

GO