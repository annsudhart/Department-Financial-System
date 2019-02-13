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

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @schemaName NVARCHAR(128) = '';
DECLARE @objectName NVARCHAR(128) = '';
DECLARE @objectType NVARCHAR(1) = '';
DECLARE @localCounter INTEGER = 1;
DECLARE @loopMe BIT = 1;

WHILE @loopMe = 1
BEGIN

    SET @schemaName = 'coa_db'

    IF @localCounter = 1
    BEGIN
        SET @objectName ='index_table'
        SET @objectType = 'U'
    END
    ELSE SET @loopMe = 0

    IF @objectType = 'U' SET @SQL = 'TABLE'
    ELSE IF @objectType = 'P' SET @SQL = 'PROCEDURE'
    ELSE IF @objectType = 'V' SET @SQL = 'VIEW'
    ELSE SET @loopMe = 0

    SET @SQL = 'DROP ' + @SQL + ' ' + @schemaName + '.' + @objectName

    IF @loopMe = 1 AND OBJECT_ID(@objectName,@objectType) IS NOT NULL
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

    SET @localCounter = @localCounter + 1 
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
CREATE SCHEMA coa_db;
GO
EXEC sys.sp_addextendedproperty 
	 @name=N'MS_Description', 
	 @value=N'UC San Diego Chart of Accounts database', 
	 @level0type=N'SCHEMA',
	 @level0name=N'coa_db';
GO

/*  CREATE TABLES *********************************************************************/
PRINT '** Create Tables';
GO

BEGIN TRY
    CREATE TABLE coa_db.index_table
    (
        unvrs_code          CHAR(2)                         NULL,
        coa_code            CHAR(1)                         NULL,
        index_code          CHAR(10)                        NULL,
        [start_date]        TIMESTAMP                       NULL,
        end_date            DATE                            NULL,
        last_actvy_date     DATE                            NULL,
        [status]            CHAR(1)                         NULL,
        user_code           VARCHAR(8)                      NULL,
        index_code_title    VARCHAR(35)                     NULL,
        fund_ovrde          CHAR(1)                         NULL,
        orgn_ovrde          CHAR(1)                         NULL,
        acct_ovrde          CHAR(1)                         NULL,
        prog_ovrde          CHAR(1)                         NULL,
        actv_ovrde          CHAR(1)                         NULL,
        lctn_ovrde          CHAR(1)                         NULL,
        fund_code           VARCHAR(6)                      NULL,
        orgn_code           VARCHAR(6)                      NULL,
        acct_code           VARCHAR(6)                      NULL,
        prog_code           VARCHAR(6)                      NULL,
        actv_code           VARCHAR(6)                      NULL,
        lctn_code           VARCHAR(6)                      NULL,
        early_inactive_date DATE                            NULL,
        refresh_date        DATE                            NULL,
        index_table_id      DECIMAL(10,0)                   NULL
    )
    EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Chart of Accounts table that represents a combination of fund, organization, program, and location. The combination of Index code and Account code is used on expenditure, revenue and transfer transactions.',
    @level0type=N'SCHEMA', @level0name=N'coa_db',
    @level1type=N'TABLE',  @level1name=N'index_table';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate the University Code. The default value is 01 for ISIS & IFIS. ESPP is univeristy code 02.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'unvrs_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'Code to distinguish between different Charts of Accounts. The value of the current coa_code is A.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'coa_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A Chart of Accounts code that represents a combination of fund, organization, program (activity and location). The first three characters form an alphabetic prefix representing the department name. Same as IFIS_INDX in SQL-DSE EMPPED.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'index_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'The beginning date associated with a unique code.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'start_date';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'The end date associated with a unique code.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'end_date';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'The date the record was last modified.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'last_actvy_date';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate the status of a record. The values are I - Inactive and A - Active.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'status';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'Mainframe login id of the person who added or modified the record.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'user_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'The textual description of an account index code.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'index_code_title';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the fund code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'fund_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the orgn code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'orgn_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the account code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'acct_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the program code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'prog_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the activity code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'actv_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A code to indicate whether the account code value can be replaced or overridden. The values are Y - Yes, N - No.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'lctn_ovrde';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A Chart of Accounts code that describe the source of funding for an activity.  Same as IFIS_FUND in SQL-DSE EMPPED.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'fund_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'	A Chart of Account code that describe departments or offices of the University.  Same as IFIS_ORGN in SQL-DSE EMPPED.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'orgn_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A Chart of Accounts code that describe the basic accounting classification. There are seven account types: assets, liabilities, system control, fund balance, revenue, expenditures and transfer.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'acct_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'Chart of Accounts code that represents the function of the activity. Programs include instruction, research, teaching hospitals, etc.  Same as IFIS_PRGM in SQL-DSE EMPPED.  Note: Program codes that begin with alpha characters are used for reporting purposes only.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'prog_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A Chart of Accounts code reserved for future use.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'actv_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A Chart of Accounts code used to identify individual plant assets of the University.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'lctn_code';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A date value to indicate when a transaction against an index code is invalid for certain rule class codes.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'early_inactive_date';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'The date the record is extracted from its source (usually the mainframe) This may not be the date the record was loaded to the Data Warehouse, although under normal circumstances it should be the same.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'refresh_date';
    EXEC sys.sp_addextendedproperty
        @name=N'MS_Description',
        @value=N'A unique identification number assigned by the computer used to define record.',
        @level0type=N'SCHEMA', @level0name=N'coa_db',
        @level1type=N'TABLE',  @level1name=N'index_table',
        @level2type=N'COLUMN', @level2name=N'index_table_id';
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH