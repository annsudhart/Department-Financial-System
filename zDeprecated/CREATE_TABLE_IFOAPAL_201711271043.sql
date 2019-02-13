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

        INSERT [dbo].[ErrorLog] 
            (
            [UserName], 
            [ErrorNumber], 
            [ErrorSeverity], 
            [ErrorState], 
            [ErrorProcedure], 
            [ErrorLine], 
            [ErrorMessag3e]
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
IF OBJECT_ID('ifoapal.GetOrganizations','P') IS NOT NULL
    DROP PROCEDURE ifoapal.GetOrganizations;
GO

PRINT '-- Delete Views';
GO
IF OBJECT_ID('dbo.ifoapal_ifopindex','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_ifopindex;
GO
IF OBJECT_ID('dbo.ifoapal_locations','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_locations;
GO
IF OBJECT_ID('dbo.ifoapal_programs','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_programs;
GO
IF OBJECT_ID('dbo.ifoapal_accounts','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_accounts;
GO
IF OBJECT_ID('dbo.ifoapal_organizations','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_organizations;
GO
IF OBJECT_ID('dbo.ifoapal_funds','V') IS NOT NULL
    DROP VIEW dbo.ifoapal_funds;
GO

PRINT '-- Delete Tables';
GO
IF OBJECT_ID('ifoapal.ifopindex','U') IS NOT NULL
    DROP TABLE ifoapal.ifopindex;
GO
IF OBJECT_ID('ifoapal.ifopindex_group','U') IS NOT NULL
    DROP TABLE ifoapal.ifopindex_group;
GO
IF OBJECT_ID ('ifoapal.location','U') IS NOT NULL
    DROP TABLE ifoapal.location;
GO
IF OBJECT_ID ('ifoapal.location_type','U') IS NOT NULL
    DROP TABLE ifoapal.location_type;
GO
IF OBJECT_ID('ifoapal.activity','U') IS NOT NULL
    DROP TABLE ifoapal.activity;
GO
IF OBJECT_ID('ifoapal.program','U') IS NOT NULL
    DROP TABLE ifoapal.program;
GO
IF OBJECT_ID('ifoapal.program_function','U') IS NOT NULL    
    DROP TABLE ifoapal.program_function;
GO
IF OBJECT_ID('ifoapal.account','U') IS NOT NULL
    DROP TABLE ifoapal.account;
GO
IF OBJECT_ID('ifoapal.account_group','U') IS NOT NULL    
    DROP TABLE ifoapal.account_group;
GO
IF OBJECT_ID('ifoapal.account_category','U') IS NOT NULL    
    DROP TABLE ifoapal.account_category;
GO
IF OBJECT_ID('ifoapal.organization','U') IS NOT NULL
    DROP TABLE ifoapal.organization;
GO
IF OBJECT_ID('ifoapal.organization_unit','U') IS NOT NULL
    DROP TABLE ifoapal.organization_unit;
GO
IF OBJECT_ID('ifoapal.organization_group','U') IS NOT NULL
    DROP TABLE ifoapal.organization_group;
GO
IF OBJECT_ID('ifoapal.fund','U') IS NOT NULL
    DROP TABLE ifoapal.fund;
GO
IF OBJECT_ID('ifoapal.fund_range','U') IS NOT NULL
    DROP TABLE ifoapal.fund_range;
GO
IF OBJECT_ID('ifoapal.fund_type','U') IS NOT NULL
    DROP TABLE ifoapal.fund_type;
GO
IF OBJECT_ID('ifoapal.fund_type_class','U') IS NOT NULL
    DROP TABLE ifoapal.fund_type_class;
GO
IF OBJECT_ID('ifoapal.operation','U') IS NOT NULL 
    DROP TABLE ifoapal.operation;
GO
IF OBJECT_ID('ifoapal.category','U') IS NOT NULL    
    DROP TABLE ifoapal.category;
GO
IF OBJECT_ID('ifoapal.mission','U') IS NOT NULL
    DROP TABLE ifoapal.mission;
GO


PRINT '-- Delete Schemas';
GO
PRINT '-- -- ifoapal';
IF SCHEMA_ID('ifoapal') IS NOT NULL
	DROP SCHEMA ifoapal;
GO

/*  CREATE SCHEMAS ********************************************************************/
PRINT '** Create Schemas';
GO
CREATE SCHEMA ifoapal;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'Contains IFOAPAL (Index, Fund, Organization, Account, Program, Activity, Location) objects by multiple datasets.', 
	 @level0type=N'SCHEMA',
	 @level0name=N'ifoapal';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

/*  -- GENERAL                                                                        */
PRINT '-- ifoapal.mission';
CREATE TABLE ifoapal.mission
(
    mission_id              NCHAR(1)                        NOT NULL,
    mission_name            NVARCHAR(25)                       NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_mission PRIMARY KEY CLUSTERED (mission_id)
);
GO
INSERT INTO ifoapal.mission(mission_id,mission_name) VALUES
    (N'A',N'Academic'),
    (N'C',N'Clinical'),
    (N'R',N'Research'),
    (N'Z',N'--EMPTY--');
GO

PRINT '-- ifoapal.category';
CREATE TABLE ifoapal.category
(
    category_id     NCHAR(1)                        NOT NULL,
    category_name   NVARCHAR(25)                       NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_category PRIMARY KEY CLUSTERED (category_id)
);
GO
INSERT INTO ifoapal.category(category_id,category_name) VALUES
    (N'C',N'Core'),
    (N'N',N'Non-Core'),
    (N'O',N'Other'),
    (N'Z',N'--EMPTY--');
GO

PRINT '-- ifoapal.operation';
CREATE TABLE ifoapal.operation
(
    operation_id            NCHAR(3)                        NOT NULL,
    operation_name          NVARCHAR(50)                       NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_operation PRIMARY KEY CLUSTERED (operation_id)
);
GO
INSERT INTO ifoapal.operation(operation_id,operation_name) VALUES
    (N'CDO',N'Central Department Operations'),
    (N'DOT',N'Department Other'),
    (N'ZZZ',N'--EMPTY--');
GO

/*  -- LOCATION                                                                       */
PRINT '-- ifoapal.location_type';
CREATE TABLE ifoapal.location_type
(
    location_type_id   NCHAR(2)                        NOT NULL,
    location_type_name NVARCHAR(25)                        NULL,
    createdby       NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate     DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby   NVARCHAR(50)                        NULL,
    lastupdated     DATETIME2(2)                        NULL,
    rowguid         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber   ROWVERSION,
    validfrom       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_dbo_locationtype PRIMARY KEY CLUSTERED (location_type_id)
);
GO
INSERT INTO ifoapal.location_type(location_type_id,location_type_name) VALUES
    (N'ZZ',N'--Empty--'),
    (N'RE',N'Real Estate'),
    (N'BD',N'Buildings & Structures'),
    (N'GI',N'General Improvements'),
    (N'LH',N'Leashold Improvements'),
    (N'PR',N'Assets to be Prorated');
GO


PRINT '-- ifoapal.location';
CREATE TABLE ifoapal.location
(
    location_id     NCHAR(6)                        NOT NULL,
    location_name   NVARCHAR(50)                        NULL,
    location_type_id   AS CONVERT(NCHAR(2),SUBSTRING(location_id,1,2)),
    createdby       NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate     DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby   NVARCHAR(50)                        NULL,
    lastupdated     DATETIME2(2)                        NULL,
    rowguid         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber   ROWVERSION,
    validfrom       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_location PRIMARY KEY CLUSTERED (location_id)
);
GO
INSERT INTO ifoapal.location (location_id,location_name) VALUES(N'ZZZZZZ',N'--Empty--');
GO

PRINT '-- dbo.ifoapal_locations';
GO
CREATE VIEW dbo.ifoapal_locations AS
    SELECT  ifoapal.location.location_id, 
            ifoapal.location.location_name, 
            ifoapal.location.location_type_id, 
            ifoapal.location_type.location_type_name, 
            ifoapal.location.createdby, 
            ifoapal.location.createddate, 
            ifoapal.location.lastupdatedby,
            ifoapal.location.lastupdated, 
            ifoapal.location.rowguid, 
            ifoapal.location.versionnumber, 
            ifoapal.location.validfrom, 
            ifoapal.location.validto
    FROM    ifoapal.location 
            INNER JOIN ifoapal.location_type 
            ON ifoapal.location.location_type_id = ifoapal.location_type.location_type_id;
GO

/*  -- ACTIVITY                                                                       */
PRINT '-- ifoapal.activity';
CREATE TABLE ifoapal.activity
(
    activity_id     NCHAR(6)                        NOT NULL,
    activity_name   NVARCHAR(50)                        NULL,
    createdby       NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate     DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby   NVARCHAR(50)                        NULL,
    lastupdated     DATETIME2(2)                        NULL,
    rowguid         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber   ROWVERSION,
    validfrom       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_activity PRIMARY KEY CLUSTERED (activity_id)
);
GO
INSERT INTO ifoapal.activity(activity_id,activity_name) VALUES(N'ZZZZZZ',N'--EMPTY--');

/*  -- PROGRAM                                                                        */
PRINT '-- ifoapal.program_function';
CREATE TABLE ifoapal.program_function
(
    program_function_id     NCHAR(2)                        NOT NULL,
    program_function_name   NVARCHAR(50)                        NULL,
    category_id     NCHAR(1)                        NOT NULL    CONSTRAINT FK_ifoapal_programcode_programfunction_programfunctionid
                                                                        FOREIGN KEY (category_id)
                                                                        REFERENCES ifoapal.category(category_id)
                                                                        DEFAULT 'Z',
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_programfunction PRIMARY KEY CLUSTERED (program_function_id)
);
GO
INSERT INTO ifoapal.program_function(program_function_id,program_function_name,category_id) VALUES
    (N'ZZ',N'--EMPTY--',N'Z'),
    (N'40',N'Instruction',N'C'),
    (N'44',N'Research',N'C'),
    (N'62',N'Public Service',N'C'),
    (N'42',N'Teaching Hospital',N'O'),
    (N'43',N'Academic Support / Administration',N'O'),
    (N'60',N'Library',N'O'),
    (N'61',N'Instruction, Extension',N'O'),
    (N'64',N'Operation & Maintenance of Plant (OMP)',N'O'),
    (N'66',N'Institutional Support / Administration',N'O'),
    (N'68',N'Student Services',N'O'),
    (N'72',N'Institutional Support / Administration',N'O'),
    (N'77',N'Financial Aid, Undergraduate',N'O'),
    (N'78',N'Financial Aid, Graduate',N'O'),
    (N'79',N'Financial Aid',N'O'),
    (N'80',N'Budget Provision',N'O');
GO

PRINT '-- ifoapal.program';
CREATE TABLE ifoapal.program
(
    program_id              NCHAR(6)                        NOT NULL,
    program_name            NVARCHAR(50)                        NULL,
    program_function_id     AS CONVERT(NCHAR(2),SUBSTRING(program_id,1,2))    PERSISTED   
                                                                        CONSTRAINT FK_ifoapal_programfunction_program_programfunctionid
                                                                        FOREIGN KEY (program_function_id)
                                                                        REFERENCES ifoapal.program_function(program_function_id),
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_program PRIMARY KEY CLUSTERED (program_id)
);
GO
INSERT INTO ifoapal.program(program_id,program_name) VALUES(N'ZZZZZZ',N'--EMPTY--');
GO

PRINT '-- dbo.ifoapal_programs';
GO
CREATE VIEW dbo.ifoapal_programs AS
    SELECT  ifoapal.program.program_id, 
            ifoapal.program.program_name, 
            ifoapal.program.program_function_id, 
            ifoapal.program_function.program_function_name, 
            ifoapal.program_function.category_id,
            ifoapal.category.category_name, 
            ifoapal.program.createdby, 
            ifoapal.program.createddate, 
            ifoapal.program.lastupdatedby, 
            ifoapal.program.lastupdated, 
            ifoapal.program.rowguid,
            ifoapal.program.versionnumber, 
            ifoapal.program.validfrom, 
            ifoapal.program.validto
    FROM    ifoapal.program 
            INNER JOIN ifoapal.program_function 
            ON ifoapal.program.program_function_id = ifoapal.program_function.program_function_id 
            INNER JOIN ifoapal.category 
            ON ifoapal.program_function.category_id = ifoapal.category.category_id;
GO

/*  -- ACCOUNT                                                                        */
PRINT '-- ifoapal.account_category';
CREATE TABLE ifoapal.account_category
(
    account_category_id     INT                             NOT NULL,
    account_category_name   NVARCHAR(50)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_accountcategory PRIMARY KEY CLUSTERED (account_category_id)
);
GO
INSERT INTO ifoapal.account_category(account_category_id,account_category_name) VALUES
    (0,N'Empty'),
    (1,N'Salaries & Benefits'),
    (2,N'Expenditures'),
    (3,N'Transfers'),
    (4,N'Revenue'),
    (5,N'Overhead');
GO

PRINT '--ifoapal.account_group';
CREATE TABLE ifoapal.account_group
(
    account_group_id        NCHAR(2)                        NOT NULL,
    account_group_name      NVARCHAR(25)                        NULL,
    account_category_id     INT                                         CONSTRAINT FK_ifoapal_accountgroup_account_accountcaegoryid
                                                                        FOREIGN KEY (account_category_id)
                                                                        REFERENCES ifoapal.account_category(account_category_id)
                                                                        DEFAULT 0,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_accountgroup PRIMARY KEY CLUSTERED (account_group_id)
);
GO
INSERT INTO ifoapal.account_group(account_group_id,account_group_name,account_category_id) VALUES
    (N'ZZ',N'--EMPTY--',0),
    (N'5x',N'REVENUE',4),
    (N'60',N'ACADEMIC SALARIES',1),
    (N'61',N'STAFF SALARIES',1),
    (N'62',N'GENERAL ASSISTANCE',2),
    (N'63',N'SUPPLIES & EXPENSE',2),
    (N'64',N'EQUIPMENT',2),
    (N'65',N'TRAVEL',2),
    (N'66',N'BENEFITS',1),
    (N'68',N'UNALLOCATED',2),
    (N'69',N'RECHARGES',2),
    (N'7x',N'TRANSFERS',3),
    (N'82',N'OVERHEAD',5);
GO

PRINT '--ifoapal.account';
CREATE TABLE ifoapal.account
(
    account_id              NCHAR(6)                        NOT NULL,
    account_name            NVARCHAR(50)                        NULL,
    account_level           INT                             NOT NULL    DEFAULT 5,
    account_parent_id       NVARCHAR(6)                         NULL,
    account_parent_lvl      AS CONVERT(INT,account_level-1),
    account_class_id        NCHAR(1)                        NOT NULL    DEFAULT 'Z',
    account_group_id        NCHAR(2)                        NOT NULL    CONSTRAINT FK_ifoapal_account_accountgroup_accountgroupid
                                                                        FOREIGN KEY (account_group_id)
                                                                        REFERENCES ifoapal.account_group(account_group_id)
                                                                        DEFAULT 'ZZ',
    account_type_id         NCHAR(2)                        NOT NULL    DEFAULT 'ZZ',    
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_account PRIMARY KEY CLUSTERED (account_id,account_level)
);
GO
INSERT INTO ifoapal.account(account_id,account_name,account_level,account_parent_id,account_class_id,account_group_id) VALUES
    (N'ZZZZZZ',N'--EMPTY--',1,NULL,N'Z',N'ZZ'),
    (N'ZZZZZZ',N'--EMPTY--',2,N'ZZZZZZ',N'Z',N'ZZ'),
    (N'ZZZZZZ',N'--EMPTY--',3,N'ZZZZZZ',N'Z',N'ZZ'),
    (N'ZZZZZZ',N'--EMPTY--',4,N'ZZZZZZ',N'Z',N'ZZ'),
    (N'ZZZZZZ',N'--EMPTY--',5,N'ZZZZZZ',N'Z',N'ZZ');
GO

PRINT '--dbo.ifoapal_accounts';
GO
CREATE VIEW dbo.ifoapal_accounts AS
    SELECT  ifoapal.account.account_id, 
            ifoapal.account.account_name,
            ifoapal.account.account_level,
            ifoapal.account.account_parent_id,
            ifoapal.account.account_parent_lvl, 
            ifoapal.account.account_class_id,
            ifoapal.account.account_group_id, 
            ifoapal.account_group.account_group_name, 
            ifoapal.account_group.account_category_id,
            ifoapal.account_category.account_category_name, 
            ifoapal.account.createdby, 
            ifoapal.account.createddate, 
            ifoapal.account.lastupdatedby, 
            ifoapal.account.lastupdated, 
            ifoapal.account.rowguid, 
            ifoapal.account.versionnumber,
            ifoapal.account.validfrom, 
            ifoapal.account.validto
    FROM    ifoapal.account 
            INNER JOIN ifoapal.account_group 
            ON ifoapal.account.account_group_id = ifoapal.account_group.account_group_id 
            INNER JOIN ifoapal.account_category 
            ON ifoapal.account_group.account_category_id = ifoapal.account_category.account_category_id;
GO

/*  -- ORGANIZATION                                                                   */
PRINT '--ifoapal.organization_group';
CREATE TABLE ifoapal.organization_group
(
    organization_group_id   NCHAR(2)                        NOT NULL,
    organization_group_name NVARCHAR(50)                        NULL,
    organization_group_note NVARCHAR(100)                       NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_organizationgroup PRIMARY KEY CLUSTERED (organization_group_id)
);
GO
INSERT INTO ifoapal.organization_group(organization_group_id,organization_group_name,organization_group_note) VALUES
    (N'ZZ',N'--EMPTY',N'Unavailable or Not Applicable'),
    (N'41',N'Core',N'Instruction, Research, Public Service'),
    (N'42',N'Teaching Hospital',NULL),
    (N'43',N'Academic Support',N'Academic Department Administration'),
    (N'60',N'Library',NULL),
    (N'61',N'Instruction, Extension',NULL),
    (N'64',N'Operation & Maintenance of Plant',NULL),
    (N'66',N'Institutional Support',N'Campus-Wide Administration & Support'),
    (N'68',N'Student Services',NULL),
    (N'72',N'Institutional Support',N'Campus-Wide Administration & Support'),
    (N'77',N'Financial Aid, Undergraduate',NULL),
    (N'78',N'Financial Aid, Graduate',NULL),
    (N'79',N'Financial Aid',NULL),
    (N'80',N'Budget Provision',NULL);
GO

PRINT '--ifoapal.organization_unit';
CREATE TABLE ifoapal.organization_unit
(
    organization_unit_id    NCHAR(4)                        NOT NULL,
    organization_unit_name  NVARCHAR(50)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_organizationunit PRIMARY KEY CLUSTERED (organization_unit_id)
);
GO
INSERT INTO ifoapal.organization_unit(organization_unit_id,organization_unit_name) VALUES
    (N'4135',N'International Relations / Pacific Studies'),
    (N'4136',N'Area Health Education Center'),
    (N'4142',N'Medical Center Programs'),
    (N'4147',N'School of Medicine'),
    (N'4148',N'School of Medicine'),
    (N'4149',N'School of Medicine'),
    (N'4161',N'Centers'),
    (N'4162',N'Campus-Wide Departments'),
    (N'4163',N'Provosts Offices'),
    (N'4164',N'SIO - General'),
    (N'4165',N'SIO - Marine Facilities'),
    (N'4166',N'SIO - Marine Life Research'),
    (N'4167',N'SIO - CA Sea Grant Program'),
    (N'4174',N'Regents Faculty Fellowships'),
    (N'4175',N'Work Study Programs'),
    (N'4176',N'Other'),
    (N'4185',N'Institute for Cognitive Science'),
    (N'4186',N'Institute of Geophysics & Planetary Physics'),
    (N'4187',N'Research Institutes - Other'),
    (N'4188',N'Centers'),
    (N'4193',N'Institute of Marine Resoruces'),
    (N'4195',N'Grant Administration'),
    (N'4198',N'Other'),
    (N'4199',N'Summer Session'),
    (N'9999',N'Non-Core'),
    (N'ZZZZ',N'--EMPTY--');
GO

PRINT '--ifoapal.organization';
CREATE TABLE ifoapal.organization
(
    organization_id         NCHAR(6)                        NOT NULL,
    organization_name       NVARCHAR(50)                        NULL,
    organization_level      INT                             NOT NULL    DEFAULT 6,
    organization_parent_id  NCHAR(6)                            NULL,
    organization_parent_lvl AS CONVERT(INT,organization_level-1),
    organization_unit_id    NCHAR(4)                        NOT NULL    CONSTRAINT FK_ifoapal_organization_organizationunit_organizationunitid
                                                                        FOREIGN KEY (organization_unit_id)
                                                                        REFERENCES ifoapal.organization_unit(organization_unit_id)
                                                                        DEFAULT 'ZZZZ',
    organization_group_id   NCHAR(2)                        NOT NULL    CONSTRAINT FK_ifoapal_organization_organizationgroup_organizationgroupid
                                                                        FOREIGN KEY (organization_group_id)
                                                                        REFERENCES ifoapal.organization_group(organization_group_id)
                                                                        DEFAULT 'ZZ',
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_organization PRIMARY KEY CLUSTERED (organization_id,organization_level)
);
GO
INSERT INTO ifoapal.organization(organization_id,organization_name,organization_level,organization_parent_id) VALUES
    (N'ZZZZZZ',N'--EMPTY--',1,NULL),
    (N'ZZZZZZ',N'--EMPTY--',2,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY--',3,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY--',4,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY--',5,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY--',6,N'ZZZZZZ'),
    (N'JAAAAA',N'VICE CHANCELLOR HEALTH SCIENCE',1,NULL),
    (N'JD0000',N'CLINICAL DEPARTMENTS',2,N'JAAAAA'),
    (N'JD1400',N'MEDICINE',3,N'JD0000');
GO

PRINT '--dbo.ifoapal_organizations';
GO
CREATE VIEW dbo.ifoapal_organizations AS
    SELECT  ifoapal.organization.organization_id, 
            ifoapal.organization.organization_name, 
            ifoapal.organization.organization_level, 
            ifoapal.organization.organization_parent_id, 
            ifoapal.organization.organization_parent_lvl,
            ifoapal.organization.organization_unit_id,
            ifoapal.organization_unit.organization_unit_name,
            ifoapal.organization.createdby, 
            ifoapal.organization.createddate, 
            ifoapal.organization.lastupdatedby, 
            ifoapal.organization.lastupdated, 
            ifoapal.organization.rowguid, 
            ifoapal.organization.versionnumber,
            ifoapal.organization.validfrom, 
            ifoapal.organization.validto
    FROM    ifoapal.organization 
            INNER JOIN ifoapal.organization_unit 
            ON ifoapal.organization.organization_unit_id = ifoapal.organization_unit.organization_unit_id;
GO

PRINT '--ifoapal.GetOrganizations';
GO
CREATE PROCEDURE    ifoapal.GetOrganizations
                    (
                        @organization_level INT = 0,
                        @organization_id NCHAR(6) = NULL
                    )
                    AS
                    BEGIN
                        -- SET NOCOUNT ON added to prevent extra result sets from
                        -- interfering with SELECT statements.
                        SET NOCOUNT ON;

                        DECLARE @SQL NVARCHAR(MAX) = NULL;

                        SET @SQL = 'SELECT  ifoapal.organization.organization_id, 
                                            ifoapal.organization.organization_name, 
                                            ifoapal.organization.organization_level, 
                                            ifoapal.organization.organization_parent_id, 
                                            ifoapal.organization.organization_parent_lvl,
                                            ifoapal.organization.organization_unit_id,
                                            ifoapal.organization_unit.organization_unit_name,
                                            ifoapal.organization.organization_group_id,
                                            ifoapal.organization_group.organization_group_name,
                                            ifoapal.organization_group.organization_group_note,
                                            ifoapal.organization.createdby, 
                                            ifoapal.organization.createddate, 
                                            ifoapal.organization.lastupdatedby, 
                                            ifoapal.organization.lastupdated, 
                                            ifoapal.organization.rowguid, 
                                            ifoapal.organization.versionnumber,
                                            ifoapal.organization.validfrom, 
                                            ifoapal.organization.validto
                                    FROM    ifoapal.organization 
                                            INNER JOIN ifoapal.organization_unit 
                                            ON ifoapal.organization.organization_unit_id = ifoapal.organization_unit.organization_unit_id 
                                            INNER JOIN ifoapal.organization_group 
                                            ON ifoapal.organization.organization_group_id = ifoapal.organization_group.organization_group_id ';
                        IF (NOT(ISNULL(@organization_id,-1)=-1) OR @organization_level > 1)
                            BEGIN
                                SET @SQL = @SQL +  'INNER JOIN ifoapal.organization AS orghierarchy ON ifoapal.organization.organization_parent_id = orghierarchy.organization_id ' +
                                                   'AND ifoapal.organization.organization_parent_lvl = orghierarchy.organization_level ';
                                IF NOT(ISNULL(@organization_id,-1)=-1)
                                    BEGIN
                                        SET @SQL = @SQL + 'WHERE ifoapal.organization_id = ' + '''' + @organization_id + '''' +' ';
                                    END;
                                IF (ISNULL(@organization_id,-1)=-1 AND @organization_level > 1)
                                    BEGIN
                                        SET @SQL = @SQL + 'WHERE ifoapal.organization_id >=' + @organization_level + ' ';
                                    END;
                            END;
                        SET @SQL = @SQL + ';'
                        PRINT @SQL;
                        EXEC(@SQL);
                    END
GO

/*  -- FUND                                                                           */
PRINT '--ifoapal.fund_type_class';
CREATE TABLE ifoapal.fund_type_class
(
    fund_type_class_id      NCHAR(2)                        NOT NULL,
    fund_type_class_name    NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_fundtypeclass PRIMARY KEY CLUSTERED (fund_type_class_id)
);
GO
INSERT INTO ifoapal.fund_type_class (fund_type_class_id,fund_type_class_name) VALUES
    (N'ZZ',N'--EMPTY--'),
    (N'CT',N'Current'),
    (N'NC',N'Non-Current');
GO

PRINT '--ifoapal.fund_type';
CREATE TABLE ifoapal.fund_type
(
    fund_type_id            NCHAR(3)                        NOT NULL,
    fund_type_name          NVARCHAR(50)                        NULL,
    fund_type_class_id      NCHAR(2)                        NOT NULL    CONSTRAINT FK_ifoapal_fundtype_fundtypeclass_fundtypeclassid
                                                                        FOREIGN KEY (fund_type_class_id)
                                                                        REFERENCES ifoapal.fund_type_class(fund_type_class_id)
                                                                        DEFAULT 'ZZ',
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_fundtype PRIMARY KEY CLUSTERED (fund_type_id)
);
GO
INSERT INTO ifoapal.fund_type (fund_type_id,fund_type_name,fund_type_class_id) VALUES
    (N'ZZZ',N'--EMPTY--',N'ZZ'),
    (N'RSP',N'Restricted, Sponsored Project',N'CT'),
    (N'REI',N'Restricted, Endowment Income',N'CT'),
    (N'RZZ',N'Restricted, Other / Unknown',N'CT'),
    (N'UTF',N'Unrestricted, Tuition & Fees',N'CT'),
    (N'USS',N'Unrestricted, State Support',N'CT'),
    (N'UGS',N'Unrestricted, Sales of Goods & Services',N'CT'),
    (N'UAP',N'Unrestricted, Appropriation from University funds',N'CT'),
    (N'NEF',N'Endowment Funds',N'NC'),
    (N'CAP',N'Plant Funds',N'NC');
GO

PRINT '--ifoapal.fund_range';
CREATE TABLE ifoapal.fund_range
(
    fund_range_id           NCHAR(6)                        NOT NULL,
    fund_range_end_id       NCHAR(6)                        NOT NULL,
    fund_range_description  NVARCHAR(50)                        NULL,
    fund_range_department   NVARCHAR(25)                        NULL,
    fund_range_min          AS CONVERT(INT,SUBSTRING(fund_range_id,1,5)),
    fund_range_max          AS CONVERT(INT,SUBSTRING(fund_range_end_id,1,5)),
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_fundrange PRIMARY KEY CLUSTERED (fund_range_id)
);
GO
INSERT INTO ifoapal.fund_range(fund_range_id,fund_range_end_id,fund_range_description,fund_range_department) VALUES
    (N'00001A',N'00250A',N'Agency',N'General Accounting'),
    (N'00270A',N'00299A',N'Agency Loans & Scholarships',N'General Accounting'),
    (N'00300A',N'01999A',N'Plant',N'General Accounting'),
    (N'02200A',N'03999A',N'Loan Funds',N'General Accounting'),
    (N'04000A',N'09599A',N'Principal Appropriated',N'General Accounting'),
    (N'13000A',N'13999A',N'Endowments',N'General Accounting'),
    (N'16000A',N'16199A',N'Federal Contracts',N'OPAFS'),
    (N'16200A',N'16999Z',N'Endowments',N'General Accounting'),
    (N'18000A',N'18199A',N'Specific State Appropriations',N'Disbursements'),
    (N'18200A',N'18999A',N'State Agency',N'OPAFS'),
    (N'19900A',N'19900Z',N'General',N'General Accounting'),
    (N'19901A',N'19932A',N'State Appropriations',N'Disbursements'),
    (N'19933A',N'19933A',N'Misc UC General Funds',N'General Accounting'),
    (N'19934A',N'19939A',N'State Appropriations',N'Disbursements'),
    (N'19940A',N'19943A',N'Misc UC General Funds',N'General Accounting'),
    (N'19944A',N'19953A',N'State Appropriations',N'Disbursements'),
    (N'19954A',N'19958A',N'One Time State Appropriations',N'General Accounting'),
    (N'19959A',N'19999Z',N'State Appropriations',N'Disbursements'),
    (N'20000A',N'20299A',N'Student Fees',N'General Accounting'),
    (N'20300A',N'20399A',N'Student Fees - Other',N'General Accounting'),
    (N'20500A',N'20599A',N'Specific State Appropriations',N'Disbursements'),
    (N'20600A',N'20999A',N'Local Agency',N'OPAFS'),
    (N'21000A',N'33999A',N'Federal Grants',N'OPAFS'),
    (N'34100A',N'39799A',N'Endowment',N'General Accounting'),
    (N'39999A',N'59996A',N'Private Contracts, Grants, & Gifts',N'OPAFS'),
    (N'59997A',N'59997A',N'SOM Clinical Trials',N'SOM Clinical Trials'),
    (N'59998A',N'59999A',N'Private Contracts, Grants, & Gifts',N'OPAFS'),
    (N'60000A',N'62999A',N'Various Income-Producing Activities',N'General Accounting'),
    (N'63000A',N'63999A',N'Medical Center',N'General Accounting'),
    (N'64000A',N'65999A',N'Income-Producing Activities',N'General Accounting'),
    (N'66000A',N'66099A',N'Service Enterprises',N'General Accounting'),
    (N'66100A',N'68800A',N'Income-Producing Activities',N'General Accounting'),
    (N'68801A',N'68849A',N'Work-Study Off Campus',N'General Accounting'),
    (N'68851A',N'68899A',N'Work-Study Off Campus',N'General Accounting'),
    (N'68850A',N'68850A',N'Income-Producing Activities',N'General Accounting'),
    (N'69000A',N'69000A',N'Tuition Remission',N'General Accounting'),
    (N'69060A',N'69899A',N'Systemwide Assessment Funds',N'General Accounting'),
    (N'69990A',N'69999A',N'STIP',N'General Accounting'),
    (N'70000A',N'74999A',N'Auxiliary Enterprises',N'General Accounting'),
    (N'75000A',N'75999A',N'Reserves',N'General Accounting'),
    (N'76000A',N'76999A',N'Reserves for Renewal & Replacement',N'General Accounting'),
    (N'78000A',N'79599A',N'Private Contracts (incl Fed Flow Thru)',N'OPAFS'),
    (N'79600A',N'79600A',N'SOM Clinical Trials',N'SOM Clinical Trials'),
    (N'79601A',N'85499A',N'Private Contracts (incl Fed Flow Thru)',N'OPAFS'),
    (N'85500A',N'85999A',N'Private Grants',N'OPAFS'),
    (N'86000A',N'86999A',N'Gifts',N'Gift Processing'),
    (N'87000A',N'87099A',N'Local',N'OPAFS'),
    (N'87100A',N'89499A',N'Private Contracts (incl Fed Flow Thru)',N'OPAFS'),
    (N'89500A',N'89999A',N'Private Grants',N'OPAFS'),
    (N'91005A',N'91005A',N'Plant',N'General Accounting'),
    (N'93000A',N'94500A',N'Federal Contracts & Grants',N'OPAFS'),
    (N'99100A',N'99200A',N'General',N'General Accounting'),
    (N'000000',N'000000',N'--EMPTY--',N'--EMPTY--');
GO

PRINT '--ifoapal.fund';
CREATE TABLE ifoapal.fund
(
    fund_id                 NCHAR(6)                        NOT NULL,
    fund_name               NVARCHAR(50)                        NULL,
    fund_level              INT                             NOT NULL    DEFAULT 5,
    fund_parent_id          NCHAR(6)                            NULL,
    fund_parent_lvl         AS CONVERT(INT,fund_level-1),
    fund_type_id            NCHAR(3)                        NOT NULL    CONSTRAINT FK_ifoapal_fund_fundtype_fundtypeid
                                                                        FOREIGN KEY (fund_type_id)
                                                                        REFERENCES ifoapal.fund_type(fund_type_id)
                                                                        DEFAULT 'ZZZ',
    fund_range_id           NCHAR(6)                        NOT NULL    CONSTRAINT FK_ifoapal_fund_fundrange_fundrangeid
                                                                        FOREIGN KEY (fund_range_id)
                                                                        REFERENCES ifoapal.fund_range(fund_range_id)
                                                                        DEFAULT '000000',
    fund_code_id            NCHAR(2)                        NOT NULL    DEFAULT 'ZZ',
    fund_group_code_id      NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    fund_sponsor_cat_id     INT                             NOT NULL    DEFAULT -1,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_fund PRIMARY KEY CLUSTERED (fund_id,fund_level)
);
GO
INSERT INTO ifoapal.fund(fund_id,fund_name,fund_level,fund_parent_id) VALUES 
    (N'ZZZZZZ',N'--EMPTY',1,NULL),
    (N'ZZZZZZ',N'--EMPTY',2,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY',3,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY',4,N'ZZZZZZ'),
    (N'ZZZZZZ',N'--EMPTY',5,N'ZZZZZZ'),
    (N'B10000',N'DESIGNATED',1,NULL),
    (N'C10000',N'GENERAL',1,NULL),
    (N'E10000',N'STATE OF CALIFORNIA',1,NULL),
    (N'G10000',N'UNITED STATES GOVERNMENT',1,NULL),
    (N'H10000',N'ENDOWMENT INCOME',1,NULL),
    (N'J10000',N'PRIVATE GIFTS, GRANTS & CONTRACTS',1,NULL),
    (N'X10000',N'RESERVES FOR RENEWALS & REPLACEMENT',1,NULL);
GO

PRINT '--dbo.ifoapal_funds';
GO
CREATE VIEW dbo.ifoapal_funds AS
    SELECT  ifoapal.fund.fund_id, 
            ifoapal.fund.fund_name,
            ifoapal.fund.fund_level,
            ifoapal.fund.fund_parent_id,
            ifoapal.fund.fund_parent_lvl, 
            ifoapal.fund.fund_type_id, 
            ifoapal.fund_type.fund_type_name, 
            ifoapal.fund_type.fund_type_class_id, 
            ifoapal.fund_type_class.fund_type_class_name, 
            ifoapal.fund.fund_range_id,
            ifoapal.fund_range.fund_range_description, 
            ifoapal.fund_range.fund_range_department, 
            ifoapal.fund.fund_code_id,
            ifoapal.fund.fund_group_code_id,
            ifoapal.fund.fund_sponsor_cat_id,
            ifoapal.fund.createdby, 
            ifoapal.fund.createddate, 
            ifoapal.fund.lastupdatedby, 
            ifoapal.fund.lastupdated, 
            ifoapal.fund.rowguid,
            ifoapal.fund.versionnumber, 
            ifoapal.fund.validfrom, 
            ifoapal.fund.validto
    FROM    ifoapal.fund 
            INNER JOIN ifoapal.fund_range 
            ON ifoapal.fund.fund_range_id = ifoapal.fund_range.fund_range_id 
            INNER JOIN ifoapal.fund_type 
            ON ifoapal.fund.fund_type_id = ifoapal.fund_type.fund_type_id 
            INNER JOIN ifoapal.fund_type_class 
            ON ifoapal.fund_type.fund_type_class_id = ifoapal.fund_type_class.fund_type_class_id;
GO

PRINT '--ifoapal.ifopindex_group';
CREATE TABLE ifoapal.ifopindex_group
(
    ifopindex_group_id      INT                             NOT NULL IDENTITY(1,1),
    ifopindex_group_name    NVARCHAR(50)                        NULL,
    ifopindex_group_note    NVARCHAR(MAX)                       NULL,
    ifopindex_group_sort    INT                                 NULL    DEFAULT 98,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_ifopindexgroup PRIMARY KEY CLUSTERED (ifopindex_group_id)        
);
GO
INSERT INTO ifoapal.ifopindex_group (ifopindex_group_name,ifopindex_group_sort) VALUES
    (N'Other / Miscellaneous',99),
    (N'Shortfall',1),
    (N'Unfunded (Clinical)',2),
    (N'UCOP Tax',3),
    (N'Transitional Support',4),
    (N'Prior Fiscal Year',5),
    (N'Unfunded (Academic)',6),
    (N'Division Budget',7),
    (N'Clinical Support',8),
    (N'Dean',9),
    (N'Residency Program',10),
    (N'Fellow Clinical Program',11),
    (N'CARE Payment',12),
    (N'FTE',13),
    (N'MSCCP / Clinical',14),
    (N'CEDF Funds',15),
    (N'AHP (DO NOT USE)',16),
    (N'Consulting & Witness',17),
    (N'ASC - Coverage',18),
    (N'ASC - AHP',19),
    (N'ASC - Fellows',20),
    (N'ASC - Medical Directors',21),
    (N'ASC - Other',22),
    (N'ASC - Residency Director',23);
GO

PRINT '--ifoapal.ifopindex';
CREATE TABLE ifoapal.ifopindex
(
    ifopindex_id            NCHAR(6)                        NOT NULL,
    ifopindex_name          NVARCHAR(50)                        NULL,
    fund_id                 NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    fund_level              AS CONVERT(INT,5)   PERSISTED,
    organization_id         NCHAR(6)                        NOT NULL    DEFAULT 'ZZZZZZ',
    organization_level      AS CONVERT(INT,6)   PERSISTED,
    program_id              NCHAR(6)                        NOT NULL    CONSTRAINT FK_ifoapal_ifopindex_program_programid
                                                                        FOREIGN KEY (program_id)
                                                                        REFERENCES ifoapal.program(program_id)
                                                                        DEFAULT 'ZZZZZZ',
    ifopindex_group_id      INT                             NOT NULL    CONSTRAINT FK_ifoapal_ifopindex_ifopindexgroup_ifopindexgroupid
                                                                        FOREIGN KEY (ifopindex_group_id)
                                                                        REFERENCES ifoapal.ifopindex_group(ifopindex_group_id)
                                                                        DEFAULT 1,
    operation_id            NCHAR(3)                        NOT NULL    CONSTRAINT FK_ifoapal_ifopindex_operation_operationid
                                                                        FOREIGN KEY (operation_id)
                                                                        REFERENCES ifoapal.operation(operation_id)
                                                                        DEFAULT 'ZZZ',
    category_id             NCHAR(1)                        NOT NULL    CONSTRAINT FK_ifoapal_ifopindex_category_categoryid
                                                                        FOREIGN KEY (category_id)
                                                                        REFERENCES ifoapal.category(category_id)
                                                                        DEFAULT 'Z',
    mission_id              NCHAR(1)                        NOT NULL    CONSTRAINT FK_ifoapal_ifopindex_mission_missionid
                                                                        FOREIGN KEY (mission_id)
                                                                        REFERENCES ifoapal.mission(mission_id)
                                                                        DEFAULT 'Z',
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_ifopindex PRIMARY KEY CLUSTERED (ifopindex_id)  
);
GO
ALTER TABLE ifoapal.ifopindex ADD
    CONSTRAINT FK_ifoapal_ifopindex_fund_fund_id
    FOREIGN KEY (fund_id,fund_level)
    REFERENCES ifoapal.fund(fund_id,fund_level);
GO
ALTER TABLE ifoapal.ifopindex ADD
    CONSTRAINT FK_ifoapal_ifopindex_organization_organizationid
    FOREIGN KEY (organization_id,organization_level)
    REFERENCES ifoapal.organization(organization_id,organization_level);
GO
INSERT INTO ifoapal.ifopindex(ifopindex_id,ifopindex_name) VALUES (N'ZZZZZZ',N'--EMPTY');
GO

PRINT '--dbo.ifoapal_ifopindex';
GO
CREATE VIEW dbo.ifoapal_ifopindex AS
    SELECT  ifoapal.ifopindex.ifopindex_id, 
            ifoapal.ifopindex.ifopindex_name, 
            ifoapal.ifopindex.fund_id,
            ifoapal.ifopindex.fund_level, 
            dbo.ifoapal_funds.fund_name,
            dbo.ifoapal_funds.fund_parent_id,
            dbo.ifoapal_funds.fund_parent_lvl, 
            dbo.ifoapal_funds.fund_type_id, 
            dbo.ifoapal_funds.fund_type_name,
            dbo.ifoapal_funds.fund_type_class_id, 
            dbo.ifoapal_funds.fund_type_class_name, 
            dbo.ifoapal_funds.fund_range_id, 
            dbo.ifoapal_funds.fund_range_description, 
            dbo.ifoapal_funds.fund_range_department,
            dbo.ifoapal_funds.fund_code_id,
            dbo.ifoapal_funds.fund_group_code_id,
            dbo.ifoapal_funds.fund_sponsor_cat_id,
            ifoapal.ifopindex.organization_id, 
            ifoapal.ifopindex.organization_level, 
            dbo.ifoapal_organizations.organization_name, 
            dbo.ifoapal_organizations.organization_parent_id, 
            dbo.ifoapal_organizations.organization_unit_id,
            dbo.ifoapal_organizations.organization_unit_name, 
            ifoapal.ifopindex.program_id, 
            dbo.ifoapal_programs.program_name, 
            dbo.ifoapal_programs.program_function_id, 
            dbo.ifoapal_programs.program_function_name,
            ifoapal.ifopindex.ifopindex_group_id, 
            ifoapal.ifopindex_group.ifopindex_group_name, 
            ifoapal.ifopindex_group.ifopindex_group_note, 
            ifoapal.ifopindex_group.ifopindex_group_sort, 
            ifoapal.ifopindex.operation_id,
            ifoapal.operation.operation_name, 
            ifoapal.ifopindex.category_id, 
            ifoapal.category.category_name, 
            ifoapal.ifopindex.mission_id, 
            ifoapal.mission.mission_name, 
            ifoapal.ifopindex.createdby, 
            ifoapal.ifopindex.createddate,
            ifoapal.ifopindex.lastupdatedby, 
            ifoapal.ifopindex.lastupdated, 
            ifoapal.ifopindex.rowguid, 
            ifoapal.ifopindex.versionnumber, 
            ifoapal.ifopindex.validfrom, 
            ifoapal.ifopindex.validto
    FROM    ifoapal.ifopindex 
            INNER JOIN ifoapal.ifopindex_group 
            ON ifoapal.ifopindex.ifopindex_group_id = ifoapal.ifopindex_group.ifopindex_group_id 
            INNER JOIN dbo.ifoapal_funds 
            ON ifoapal.ifopindex.fund_id = dbo.ifoapal_funds.fund_id 
                AND ifoapal.ifopindex.fund_level = dbo.ifoapal_funds.fund_level 
            INNER JOIN dbo.ifoapal_organizations 
            ON ifoapal.ifopindex.organization_id = dbo.ifoapal_organizations.organization_id 
                AND ifoapal.ifopindex.organization_level = dbo.ifoapal_organizations.organization_level 
            INNER JOIN dbo.ifoapal_programs 
            ON ifoapal.ifopindex.program_id = dbo.ifoapal_programs.program_id 
            INNER JOIN ifoapal.operation 
            ON ifoapal.ifopindex.operation_id = ifoapal.operation.operation_id 
                AND ifoapal.ifopindex.operation_id = ifoapal.operation.operation_id 
                AND ifoapal.ifopindex.operation_id = ifoapal.operation.operation_id 
                AND ifoapal.ifopindex.operation_id = ifoapal.operation.operation_id 
            INNER JOIN ifoapal.category 
            ON ifoapal.ifopindex.category_id = ifoapal.category.category_id 
                AND ifoapal.ifopindex.category_id = ifoapal.category.category_id 
                AND ifoapal.ifopindex.category_id = ifoapal.category.category_id 
                AND ifoapal.ifopindex.category_id = ifoapal.category.category_id 
            INNER JOIN ifoapal.mission 
            ON ifoapal.ifopindex.mission_id = ifoapal.mission.mission_id 
                AND ifoapal.ifopindex.mission_id = ifoapal.mission.mission_id 
                AND ifoapal.ifopindex.mission_id = ifoapal.mission.mission_id 
                AND ifoapal.ifopindex.mission_id = ifoapal.mission.mission_id;
GO