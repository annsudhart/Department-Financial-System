/***************************************************************************************
Name      : BSO Financial Management Interface - finlink_ledger_query
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates [finlink_ledger_query] table
****************************************************************************************
PREREQUISITES:
- CREATE_TABLE_ISOAPAL_*.sql
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

        INSERT [dbo].[ErrorLog] 
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

PRINT '-- Delete Procedures';
GO
/*IF OBJECT_ID('finlink.encumbrance_doctype','P') IS NOT NULL
    DROP PROCEDURE finlink.encumbrance_doctype;
GO*/

PRINT '-- Delete Views';
/*GO
IF OBJECT_ID('dbo.ifoapal_ifopindex','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_ifopindex;
GO*/

PRINT '-- Delete Tables';
GO
IF OBJECT_ID('finlink.operatingledger','U') IS NOT NULL
    DROP TABLE finlink.operatingledger;
GO
IF OBJECT_ID('finlink.encumbrance_doctype','U') IS NOT NULL
    DROP TABLE finlink.encumbrance_doctype;
GO
IF OBJECT_ID('finlink.encumbrance_type','U') IS NOT NULL
    DROP TABLE finlink.encumbrance_type;
GO
IF OBJECT_ID('finlink.encumbrance_action','U') IS NOT NULL
    DROP TABLE finlink.encumbrance_action;
GO
IF OBJECT_ID('finlink.rule_class','U') IS NOT NULL
    DROP TABLE finlink.rule_class;
GO
IF OBJECT_ID('finlink.transaction_type','U') IS NOT NULL
    DROP TABLE finlink.transaction_type;
GO
IF OBJECT_ID('finlink.ledger_type','U') IS NOT NULL
    DROP TABLE finlink.ledger_type;
GO
IF OBJECT_ID('finlink.deficit_code','U') IS NOT NULL
    DROP TABLE finlink.deficit_code;
GO

PRINT '-- Delete Schemas';
GO
PRINT '-- -- finlink';
IF SCHEMA_ID('finlink') IS NOT NULL
	DROP SCHEMA finlink;
GO

/*  CREATE SCHEMAS ********************************************************************/
PRINT '** Create Schemas';
GO
CREATE SCHEMA finlink;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'Contains FINLINK objects, extracts, and indexes not in other schemas.', 
	 @level0type=N'SCHEMA',
	 @level0name=N'finlink';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

PRINT '-- finlink.deficit_code';
CREATE TABLE finlink.deficit_code
(
    deficit_code_id         NCHAR(2)                        NOT NULL,
    deficit_code_name       NVARCHAR(50)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_deficitcode PRIMARY KEY CLUSTERED (deficit_code_id)
);
GO
INSERT INTO finlink.deficit_code (deficit_code_id,deficit_code_name) VALUES
    (N'AO',N'AUXILIARY/OTHER'),
    (N'GC',N'GENERAL CAMPUS'),
    (N'RF',N'RECHARGE FEDERAL FACILITIES'),
    (N'SP',N'SPONSORED PROJECTS'),
    (N'ZZ',N'--EMPTY--');
GO

PRINT '-- finlink.ledger_type';
CREATE TABLE finlink.ledger_type
(
    ledger_type_id          INT                             NOT NULL,
    ledger_type_name        NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_ledgertype PRIMARY KEY CLUSTERED (ledger_type_id)
);
GO
INSERT INTO finlink.ledger_type(ledger_type_id,ledger_type_name) VALUES
    (-1,N'--EMPTY--'),
    (2,N'Undefined'),
    (3,N'Undefined'),
    (4,N'Undefined');
GO

PRINT '-- finlink.transaction_type';
CREATE TABLE finlink.transaction_type
(
    transaction_type_id     INT                             NOT NULL,
    transaction_type_name   NVARCHAR(50)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_transactiontype PRIMARY KEY CLUSTERED (transaction_type_id)
);
GO
INSERT INTO finlink.transaction_type(transaction_type_id,transaction_type_name) VALUES
    (-1,N'--EMPTY--'),
    (3,N'INVOICES'),
    (4,N'PURCHASE ORDERS'),
    (7,N'JOURNAL VOUHCERS'),
    (13,N'TRIP'),
    (16,N'EXPENSE'),
    (21,N'BUDGET/CURRENT TRANSFER OF FUNDS');
GO

PRINT '-- finlink.rule_class';
CREATE TABLE finlink.rule_class
(
    rule_class_id           NCHAR(4)                        NOT NULL,
    rule_class_name         NVARCHAR(50)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_ruleclass PRIMARY KEY CLUSTERED (rule_class_id)
);
GO
INSERT INTO finlink.rule_class (rule_class_id,rule_class_name) VALUES (N'ZZZZ',N'--EMPTY--');

PRINT '-- finlink.encumbrance_action';
CREATE TABLE finlink.encumbrance_action
(
    encumbrance_action_id   NCHAR(1)                        NOT NULL,
    encumbrance_action_name NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_encubmranceaction PRIMARY KEY CLUSTERED (encumbrance_action_id)
);
GO
INSERT INTO finlink.encumbrance_action(encumbrance_action_id,encumbrance_action_name) VALUES
    (N'Z',N'--EMPTY'),
    (N'T',N'--UNKNOWN'),
    (N'P',N'--UNKNOWN');
GO

PRINT '-- finlink.encumbrance_type';
CREATE TABLE finlink.encumbrance_type
(
    encumbrance_type_id     NCHAR(1)                        NOT NULL,
    encumbrance_type_name   NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_encumbrancetype PRIMARY KEY CLUSTERED (encumbrance_type_id)
);
GO
INSERT INTO finlink.encumbrance_type(encumbrance_type_id,encumbrance_type_name) VALUES
    (N'Z',N'--EMPTY'),
    (N'T',N'--UNKNOWN'),
    (N'P',N'--UNKNOWN');
GO

PRINT '-- finlink.encumbrance_doctype';
CREATE TABLE finlink.encumbrance_doctype
(
    encumbrance_doctype_id  NCHAR(3)                        NOT NULL,
    encumbrance_doctype_name NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_encumbrancedoctype PRIMARY KEY CLUSTERED (encumbrance_doctype_id)
);
GO
INSERT INTO finlink.encumbrance_doctype(encumbrance_doctype_id,encumbrance_doctype_name) VALUES
    (N'ZZZ',N'--EMPTY'),
    (N'TRP',N'--UNKNOWN'),
    (N'PUR',N'--UNKNOWN');
GO

PRINT '-- finlink.operatingledger';
CREATE TABLE finlink.operatingledger
(
    id                      INT                             NOT NULL    IDENTITY(1,1),
    fiscal_period           NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    calendar_period         NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    ifopindex_id            NCHAR(6)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_ifoapalindex_ifopindex_id
                                                                        FOREIGN KEY (ifopindex_id)
                                                                        REFERENCES ifoapal.ifopindex(ifopindex_id)
                                                                        DEFAULT 'ZZZZZZ',
    fund_id                 NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    fund_level              AS CONVERT(INT,5)               PERSISTED,
    organization_id         NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    organization_level      AS CONVERT(INT,6)               PERSISTED,
    account_id              NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    account_level           AS CONVERT(INT,5)               PERSISTED,
    program_id              NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    location_id             NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    deficit_code_id         NCHAR(2)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_deficitcode_deficitcodeid
                                                                        FOREIGN KEY (deficit_code_id)
                                                                        REFERENCES finlink.deficit_code(deficit_code_id)
                                                                        DEFAULT 'ZZ',
    budget                  MONEY                           NOT NULL    DEFAULT 0,
    financial               MONEY                           NOT NULL    DEFAULT 0,
    encumbrance             MONEY                           NOT NULL    DEFAULT 0,
    balance_wo_encumbrance  AS CONVERT(MONEY,financial-budget),
    balance                 AS CONVERT(MONEY,financial-encumbrance-budget),
    ledger_type_id          INT                             NOT NULL    CONSTRAINT FK_finlinkoperatingledger_ledgertype_ledgertypeid
                                                                        FOREIGN KEY (ledger_type_id)
                                                                        REFERENCES finlink.ledger_type(ledger_type_id)
                                                                        DEFAULT -1,
    transaction_type_id     INT                             NOT NULL    CONSTRAINT FK_finlinkoperatingledger_transactiontype_transactiontypeid
                                                                        FOREIGN KEY (transaction_type_id)
                                                                        REFERENCES finlink.transaction_type(transaction_type_id)
                                                                        DEFAULT -1,
    transaction_date        DATETIME2                           NULL,
    activity_date           DATETIME2                           NULL,
    document_number         NVARCHAR(25)                        NULL,
    reference_number        NVARCHAR(25)                        NULL,
    sequence_number         INT                                 NULL    DEFAULT -1,
    encumbrance_number      NVARCHAR(25)                        NULL,
    encumbrance_action_id   NCHAR(1)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_encumbranceaction_encumbranceactionid
                                                                        FOREIGN KEY (encumbrance_action_id)
                                                                        REFERENCES finlink.encumbrance_action(encumbrance_action_id)
                                                                        DEFAULT 'Z',
    encumbrance_item_number INT                             NOT NULL    DEFAULT -1,
    encumbrance_sequence    INT                             NOT NULL    DEFAULT -1,
    encumbrance_type_id     NCHAR(1)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_encumbrancetype
                                                                        FOREIGN KEY (encumbrance_type_id)
                                                                        REFERENCES finlink.encumbrance_type(encumbrance_type_id)
                                                                        DEFAULT 'Z',
    encubmrance_doctype_id  NCHAR(3)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_encumbrancedoctype
                                                                        FOREIGN KEY (encubmrance_doctype_id)
                                                                        REFERENCES finlink.encumbrance_doctype(encumbrance_doctype_id)
                                                                        DEFAULT 'ZZZ',
    detail                  NVARCHAR(255)                       NULL,
    rule_class_id           NCHAR(4)                        NOT NULL    CONSTRAINT FK_finlinkoperatingledger_ruleclass_ruleclassid
                                                                        FOREIGN KEY (rule_class_id)
                                                                        REFERENCES finlink.rule_class(rule_class_id)
                                                                        DEFAULT 'ZZZZ',
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_finlink_operatingledger PRIMARY KEY CLUSTERED (id)
);
GO
ALTER TABLE finlink.operatingledger ADD
    CONSTRAINT FK_finlinkoperatingledger_ifoapalfund_fundid
    FOREIGN KEY (fund_id,fund_level)
    REFERENCES ifoapal.fund(fund_id,fund_level);
GO
ALTER TABLE finlink.operatingledger ADD
    CONSTRAINT FK_finlinkoperatingledger_ifoapalorganization_organizationid
    FOREIGN KEY (organization_id,organization_level)
    REFERENCES ifoapal.organization(organization_id,organization_level);
GO
ALTER TABLE finlink.operatingledger ADD
    CONSTRAINT FK_finlinkoperatingledger_ifoapalaccount_account_id
    FOREIGN KEY (account_id,account_level)
    REFERENCES ifoapal.account(account_id,account_level);
GO