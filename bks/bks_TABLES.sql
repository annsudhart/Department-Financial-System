/***************************************************************************************
Name      : BSO Financial Management Interface - IFOAPAL
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates IFOAPAL index tables 
****************************************************************************************
PREREQUISITES:
- ERROR HANDLING
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

/*  CREATE SCHEMA IF REQUIRED *********************************************************/
PRINT '** Create Schema if Non-Existent';
GO
IF SCHEMA_ID('bks') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA [bks]');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'UCSD Bookstore Data.', 
            @level0type=N'SCHEMA',
            @level0name=N'bks';
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

        SET @schemaName = 'bks'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='purchase_line_item'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='purchase'
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

PRINT '--bks.purchase'
BEGIN TRY
    CREATE TABLE bks.purchase
        (
            purchase_id		        INT								NOT NULL	IDENTITY(1,1),
            modification_indicator  VARCHAR(3)                          NULL,
            purchase_date           DATE                                NULL,
            purchase_invoice_number VARCHAR(15)                         NULL,
            discount_amount         DECIMAL(19,4)                       NULL    DEFAULT 0,
            freight_amount          DECIMAL(19,4)                       NULL    DEFAULT 0,
            duty_amount             DECIMAL(19,4)                       NULL    DEFAULT 0,
            order_date              DATE                                NULL,
            purchase_amount         DECIMAL(19,4)                       NULL    DEFAULT 0,
            use_tax_flag            CHAR(1)                             NULL,
            use_tax_amount          DECIMAL(19,4)                       NULL,
            employee_id             VARCHAR(9)                          NULL,
            employee_name           VARCHAR(35)                         NULL,
            document_number         CHAR(8)                             NULL,
            comment                 VARCHAR(MAX)                        NULL,
            createdby               NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate             DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby           NVARCHAR(255)                       NULL,
            lastupdated             DATETIME2(2)                        NULL,
            rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber           ROWVERSION						NOT	NULL,
            validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT              PK_bks_purchase                 PRIMARY KEY CLUSTERED(purchase_id)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--bks.purchase'
BEGIN TRY       
    CREATE TABLE bks.purchase_line_item
        (
            bks_line_item_id        INT								NOT NULL	IDENTITY(1,1), 
            purchase_id             INT									NULL,
            modification_indicator  VARCHAR(3)                          NULL,
            upc                     NVARCHAR(20)                        NULL,
            product_code            VARCHAR(25)                         NULL,
            line_item_description   VARCHAR(255)                        NULL,
            serial_number           VARCHAR(25)                         NULL,
            quantity_val            DECIMAL(19,4)                       NULL    DEFAULT 1,
            unit_of_measure         VARCHAR(10)                         NULL,
            unit_cost_val			DECIMAL(19,4)						NULL	DEFAULT 0,
            purchase_invoice_number VARCHAR(15)                         NULL,
            discount_amount         DECIMAL(19,4)                       NULL    DEFAULT 0,
            freight_amount          DECIMAL(19,4)                       NULL    DEFAULT 0,
            duty_amount             DECIMAL(19,4)                       NULL    DEFAULT 0,
            order_date              DATE                                NULL,
            index_code              VARCHAR(10)                         NULL,
            fund_code               VARCHAR(6)                          NULL,
            organization_code       VARCHAR(6)                          NULL,
            program_code            VARCHAR(6)                          NULL,
            account_code            VARCHAR(6)                          NULL,
            location_code           VARCHAR(6)                          NULL,
            transaction_amount      DECIMAL(19,4)                       NULL    DEFAULT 0,
            transaction_description VARCHAR(35)                         NULL,
            equipment_flag          CHAR(1)                             NULL,
            use_tax_flag            CHAR(1)                             NULL,
            use_tax_amount          DECIMAL(19,4)                       NULL,
            comment                 VARCHAR(MAX)                        NULL,
            createdby               NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby           NVARCHAR(255)                       NULL,
            lastupdated             DATETIME2(2)                        NULL,
            rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber           ROWVERSION						NOT NULL,
            validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT              PK_bks_purchase_line_item       PRIMARY KEY CLUSTERED(bks_line_item_id)
        )
        CREATE INDEX BKS_INDEX_CODE1    ON  bks.purchase_line_item(index_code)
        CREATE INDEX BKS_ACCT_CODE1     ON  bks.purchase_line_item(account_code)
        CREATE INDEX BKS_ORGN_CODE1     ON  bks.purchase_line_item(organization_code)
        CREATE INDEX BKS_LI_TX_ID       ON  bks.purchase_line_item(bks_transaction_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH

PRINT '--bks.purchase_'

GO
