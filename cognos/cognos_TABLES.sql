/***************************************************************************************
Name      : BSO Financial Management Interface - COGNOS
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates COGNOS tables - does not create import/update procedures
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

USE [dw_db];
GO

PRINT '-- Delete Existing Objects';
GO

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @schemaName NVARCHAR(128) = '';
DECLARE @objectName NVARCHAR(128) = '';
DECLARE @objectType NVARCHAR(1) = '';
DECLARE @localCounter INTEGER = 0;
DECLARE @loopMe BIT = 1;

WHILE @loopMe = 1
BEGIN

    SET @schemaName = 'cognos'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName = 'pl_type_multiplier'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName = 'cost_element'
        SET @objectType = 'U'
    END
	ELSE IF @localCounter = 3
	BEGIN
		SET @objectName = 'division'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 4
	BEGIN
		SET @objectName = 'project_type'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 5
	BEGIN
		SET @objectName = 'major_group'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 6
	BEGIN
		SET @objectName = 'mission'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 7
	BEGIN
		SET @objectName = 'pl_type'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 8
	BEGIN
		SET @objectName = 'pl_category'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 9
	BEGIN
		SET @objectName = 'pl_line_item'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 10
	BEGIN
		SET @objectName = 'pl_data_detail'
		SET @objectType = 'U'
	END
	ELSE IF @localCounter = 11
	BEGIN
		SET @objectName = 'get_pl_data_detail'
		SET @objectType = 'P'
	END
	ELSE IF @localCounter = 12
	BEGIN
		SET @objectName = 'get_pl_data_summary'
		SET @objectType = 'P'
	END
	ELSE IF @localCounter = 13
	BEGIN
		SET @objectName = 'dbo.get_core_operations_index'
		SET @objectType = 'P'
	END
	ELSE IF @localCounter = 14
	BEGIN
		SET @objectName = 'dbo.get_mission'
		SET @objectType = 'P'
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


PRINT '-- Create Schema';
GO
CREATE SCHEMA cognos;
GO
EXEC sys.sp_addextendedproperty	@name=N'MS_Description',
	@value=N'UC San Diego Cognos DB Schema',
	@level0type=N'SCHEMA',
	@level0name=N'cognos';
GO

PRINT '-- cognos.pl_type_multiplier'
BEGIN TRY
    CREATE TABLE cognos.pl_type_multiplier
    (
        pl_type_id                  INTEGER							NOT	NULL,
		multiplier_gaap				INTEGER							NOT	NULL	DEFAULT	1,
		multiplier_report			INTEGER							NOT	NULL	DEFAULT	1,
		notes						VARCHAR(MAX)						NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_pltypemultiplier PRIMARY KEY (pl_type_id)
    )

	INSERT INTO cognos.pl_type_multiplier
		(
			pl_type_id,
			multiplier_gaap,
			multiplier_report
		)
		VALUES
			(1,-1, 1),
			(2, 1,-1),
			(3,-1, 1),
			(4,-1, 1)

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.cost_element'
BEGIN TRY
    CREATE TABLE cognos.cost_element
    (
        pl_type_id                  INTEGER							NOT	NULL,
		pl_line_item_id				INTEGER							NOT	NULL,
		account						CHAR(6)							NOT NULL,
		cost_element_name			VARCHAR(50)						NOT	NULL,
		customized					BIT								NOT	NULL	DEFAULT	CAST(0 AS BIT),
		notes						VARCHAR(MAX)						NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_costelement PRIMARY KEY (pl_type_id, pl_line_item_id, account)
    )
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.division'
BEGIN TRY
    CREATE TABLE cognos.division
    (
        division_id					INTEGER							NOT	NULL,
		division_name				VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_division PRIMARY KEY (division_id)
    )

	INSERT INTO cognos.division
		(
			division_id,
			division_name
		)
		VALUES
			(3,		'Administration'),
			(83,	'Allergy'),
			(104,	'Biomedical Infomatics'),
			(73,	'Bone Marrow Transplant'),
			(5,		'Cardiology'),
			(4,		'CRC'),
			(7,		'Endocrinology/Metabolism'),
			(8,		'Gastroenterology'),
			(9,		'General Internal Medicine'),
			(10,	'Genetics'),
			(105,	'Geriatrics'),
			(106,	'Global Public Health'),
			(11,	'Hematology/Oncology'),
			(74,	'Hepatology'),
			(82,	'Hospitalist'),
			(12,	'Infectious Diseases'),
			(13,	'Nephrology'),
			(75,	'Owen'),
			(14,	'Physiology'),
			(15,	'Pulmonary'),
			(189,	'Regenerative Medicine'),
			(16,	'Rheumatology')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.project_type'
BEGIN TRY
    CREATE TABLE cognos.project_type
    (
        project_type_id				INTEGER							NOT	NULL,
		project_type_short			VARCHAR(3)						    NULL,
		project_type_name			VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_projecttype PRIMARY KEY (project_type_id)
    )

	INSERT INTO cognos.project_type
		(
			project_type_id,
			project_type_short,
			project_type_name
		)
		VALUES
			(0,	'DO',	'Department Other'),
			(1,	'CDO',	'Central Department Operations')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.major_group'
BEGIN TRY
    CREATE TABLE cognos.major_group
    (
        major_group_code			INTEGER							NOT	NULL,
		major_group_name			VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_majorgroup PRIMARY KEY (major_group_code)
    )

	INSERT INTO cognos.major_group
		(
			major_group_code,
			major_group_name
		)
		VALUES
			(3,	'Medicine')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.mission'
BEGIN TRY
    CREATE TABLE cognos.mission
    (
        mission_id					INTEGER							NOT	NULL,
		mission_name				VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_mission PRIMARY KEY (mission_id)
    )

	INSERT INTO cognos.mission
		(
			mission_id,
			mission_name
		)
		VALUES
			(1,	'Academic'),
			(2,	'Clinical'),
			(3,	'Research')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.pl_type'
BEGIN TRY
    CREATE TABLE cognos.pl_type
    (
        pl_type_id					INTEGER							NOT	NULL,
		pl_type_name				VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_pltype PRIMARY KEY (pl_type_id)
    )

	INSERT INTO cognos.pl_type
		(
			pl_type_id,
			pl_type_name
		)
		VALUES
			(1,	'Revenue'),
			(2,	'Expense'),
			(3,	'Transfer'),
			(4, 'Reserve Spending Add-Back')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.pl_category'
BEGIN TRY
    CREATE TABLE cognos.pl_category
    (
        pl_category_id				INTEGER							NOT	NULL,
		pl_category_name			VARCHAR(50)						NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_plcategory PRIMARY KEY (pl_category_id)
    )

	INSERT INTO cognos.pl_category
		(
			pl_category_id,
			pl_category_name
		)
		VALUES
			(1,	'Reserve Spending Add-Back'),
			(2,	'Revenue'),
			(3,	'Salaries & Benefits Expense'),
			(4, 'Non-Payroll Expense'),
			(5,	'Transfers / Funding Activity')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.pl_line_item'
BEGIN TRY
    CREATE TABLE cognos.pl_line_item
    (
        pl_line_item_id				INTEGER							NOT	NULL,
		pl_line_item_description	VARCHAR(50)						NOT	NULL,
		pl_line_item_sort			INTEGER							NOT	NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_pllineitem PRIMARY KEY (pl_line_item_id)
    )

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- cognos.pl_data_detail'
BEGIN TRY
    CREATE TABLE cognos.pl_data_detail
    (
		record_id					INTEGER							IDENTITY(1,1),
		accounting_period			INTEGER 						NOT	NULL,
		base_group					VARCHAR(25)							NULL,
		major_group_code			INTEGER							NOT	NULL,
		division_id					INTEGER							NOT	NULL,
		organization				CHAR(6)								NULL,
		project_type_id				INTEGER							NOT	NULL,
		index_code					CHAR(10)							NULL,
		fund_category				VARCHAR(35)							NULL,
		fund						CHAR(6)								NULL,
		program						CHAR(6)								NULL,
		account						CHAR(6)								NULL,
		rule_class_code				CHAR(4)								NULL,
		mission_id					INTEGER							NOT	NULL,
		pl_line_item_id				INTEGER							NOT	NULL,
		pl_type_id					INTEGER							NOT	NULL,
		pl_category_id				INTEGER							NOT	NULL,
		budget_value				DECIMAL(19,4)					NOT	NULL	DEFAULT	CAST(0 AS DECIMAL(19,4)),
		financial_value				DECIMAL(19,4)					NOT	NULL	DEFAULT	CAST(0 AS DECIMAL(19,4)),
		transaction_value			AS								(budget_value + financial_value)	PERSISTED,
		rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_cognos_pldatadetail PRIMARY KEY (record_id)
    )

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH




EXEC PrintNow '** CREATE cognos.get_pl_data_detail';
GO
CREATE PROCEDURE    cognos.get_pl_data_detail
                    (
                        @accounting_period_end INTEGER = 0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @accounting_period_start INTEGER = 0
							DECLARE @SQL NVARCHAR(MAX) = '';

							EXEC PrintNow '-- Populate Variables'
							IF @accounting_period_end = 0 SET @accounting_period_end = CAST(LEFT(CONVERT(VARCHAR, EOMONTH(GETDATE(),5), 112),6) AS INTEGER);
							SET @accounting_period_start = CAST(LEFT(CAST(@accounting_period_end AS CHAR(6)),4) AS INTEGER)*100;

							SELECT  TOP (100) PERCENT
									d.accounting_period, 
									d.base_group, 
									d.major_group_code, 
									d.division_id, 
									d.organization, 
									d.project_type_id, 
									d.index_code, 
									d.fund_category, 
									d.fund, 
									d.program, 
									d.account,
									d.rule_class_code, 
									d.mission_id, 
									d.pl_line_item_id, 
									d.pl_type_id, 
									d.pl_category_id, 
									ISNULL(c.cost_element_name, ISNULL(p.pl_line_item_description,'Uncategorized')) AS costelement,
									d.budget_value,
									d.financial_value, 
									d.transaction_value,
									CAST(d.transaction_value * ISNULL(x.multiplier_gaap,0) AS MONEY) AS amount,
									(d.transaction_value * ISNULL(x.multiplier_report,0)) AS report_value
							FROM    cognos.pl_data_detail AS d
									LEFT OUTER JOIN cognos.cost_element AS c
									ON d.account = c.account 
									AND d.pl_line_item_id = c.pl_line_item_id 
									AND d.pl_type_id = c.pl_type_id 
									LEFT OUTER JOIN cognos.pl_type_multiplier AS x
									ON d.pl_type_id = x.pl_type_id
									LEFT OUTER JOIN cognos.pl_line_item AS p
									ON d.pl_line_item_id = p.pl_line_item_id
							WHERE		d.accounting_period > @accounting_period_start
										AND d.accounting_period <= @accounting_period_end
							ORDER BY    d.accounting_period, 
										d.division_id, 
										d.organization, 
										d.mission_id, 
										d.fund_category, 
										d.fund, 
										d.index_code, 
										d.account, 
										d.rule_class_code,
										costelement;
                            
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO

EXEC PrintNow '** CREATE cognos.get_pl_data_summary';
GO
CREATE PROCEDURE    cognos.get_pl_data_summary
                    (
                        @accounting_period_end INTEGER = 0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @accounting_period_start INTEGER = 0
							DECLARE @SQL NVARCHAR(MAX) = '';

							EXEC PrintNow '-- Populate Variables'
							IF @accounting_period_end = 0 SET @accounting_period_end = CAST(LEFT(CONVERT(VARCHAR, EOMONTH(GETDATE(),5), 112),6) AS INTEGER);
							SET @accounting_period_start = CAST(LEFT(CAST(@accounting_period_end AS CHAR(6)),4) AS INTEGER)*100;

							SELECT  TOP (100) PERCENT 
									d.accounting_period, 
									d.major_group_code, 
									CAST(d.division_id AS VARCHAR(3)) AS division_id, 
									d.organization,
									d.project_type_id, 
									d.program, 
									d.account, 
									d.rule_class_code, 
									d.mission_id, 
									d.pl_line_item_id, 
									d.pl_type_id, d.pl_category_id, 
									t.team_id,
									ISNULL(c.cost_element_name, ISNULL(p.pl_line_item_description, 'Uncategorized')) AS costelement, 
									ISNULL(o.core_ops_group, 'Non-Core') AS core_ops, 
									SUM(d.transaction_value) AS [transaction], 
									SUM(CAST(d.transaction_value * ISNULL(x.multiplier_gaap, 0) AS MONEY)) AS amount, 
									SUM(d.transaction_value * ISNULL(x.multiplier_report, 0)) AS report_value, 
                         			CASE	WHEN d.mission_id = 3 THEN (CASE WHEN d.budget_value <>0 THEN 'Research Budget'
									 										ELSE ISNULL(d.fund_category, 'Unspecified') END)
											WHEN d.mission_id <>3 THEN (CASE	WHEN d.budget_value <>0 THEN 'Non-Research Budget'
																			ELSE ISNULL(o.core_ops_group, ISNULL(d.fund_category, 'Unspecified')) END)
									END AS fund_group
							FROM    cognos.pl_data_detail AS d 
									LEFT OUTER JOIN dbo.core_operations_index   AS o    ON  d.index_code = o.index_code 
									LEFT OUTER JOIN cognos.cost_element         AS c    ON  d.account = c.account 
																							AND d.pl_line_item_id = c.pl_line_item_id 
																							AND d.pl_type_id = c.pl_type_id 
									LEFT OUTER JOIN cognos.pl_type_multiplier   AS x    ON  d.pl_type_id = x.pl_type_id
									LEFT OUTER JOIN cognos.pl_line_item 		AS p	ON	d.pl_line_item_id = p.pl_line_item_id
									LEFT OUTER JOIN dbo.team_index				AS t	ON	d.index_code = t.index_code
							WHERE   d.accounting_period <= @accounting_period_end
									AND d.accounting_period > @accounting_period_start
									AND d.transaction_value <> 0 
							GROUP BY    d.accounting_period, 
										d.major_group_code, 
										division_id, 
										d.organization, 
										d.project_type_id, 
										d.program, 
										d.account, 
										d.rule_class_code, 
										d.mission_id, 
										d.pl_line_item_id, 
										d.pl_type_id, 
										d.pl_category_id, 
										t.team_id,
										ISNULL(c.cost_element_name, ISNULL(p.pl_line_item_description, 'Uncategorized')), 
										ISNULL(o.core_ops_group, 'Non-Core'), 
										CASE	WHEN d.budget_value<>0	THEN CASE	d.mission_id	WHEN 3 THEN 'Research Budget'
																									ELSE 'Non-Research Budget' END
												ELSE ISNULL(o.core_ops_group, ISNULL(d .fund_category, 'Unspecified'))  
												END
							HAVING		CASE	WHEN d.budget_value<>0	THEN CASE	d.mission_id	WHEN 3 THEN 'Research Budget'
																									ELSE 'Non-Research Budget' END
												ELSE ISNULL(o.core_ops_group, ISNULL(d .fund_category, 'Unspecified'))  
												END <> 'Research Budget'

							ORDER BY    d.accounting_period,
										division_id, 
										d.organization, 
										d.mission_id, 
										d.account, 
										d.rule_class_code, 
										costelement;
                            
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO


EXEC PrintNow '** CREATE dbo.get_core_operations_index';
GO
CREATE PROCEDURE    dbo.get_core_operations_index
                    (
                        @accounting_period_end INTEGER = 0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @accounting_period_start INTEGER = 0
							DECLARE @SQL NVARCHAR(MAX) = '';

							EXEC PrintNow '-- Populate Variables'
							IF @accounting_period_end = 0 SET @accounting_period_end = CAST(LEFT(CONVERT(VARCHAR, EOMONTH(GETDATE(),5), 112),6) AS INTEGER);
							SET @accounting_period_start = CAST(LEFT(CAST(@accounting_period_end AS CHAR(6)),4) AS INTEGER)*100;

							SET @SQL = 'SELECT	TOP (100) PERCENT '

							IF (@summary_only = 1)
								BEGIN
									SET @SQL = @SQL + '	d.core_ops_group
														FROM    dbo.core_operations_index AS d
														GROUP BY    d.core_ops_group;'
								END
							IF (@summary_only = 0)
								BEGIN
									SET @SQL = @SQL + '	d.index_code,
														d.core_ops_group 
														FROM	dbo.core_operations_index AS d 
														ORDER BY d.core_ops_group, d.index_code;'
								END
                            
							EXEC(@SQL);

                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO

EXEC PrintNow '** CREATE dbo.get_mission';
GO
CREATE PROCEDURE    dbo.get_mission
                    (
                        @accounting_period_end INTEGER = 0
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @accounting_period_start INTEGER = 0
							
							EXEC PrintNow '-- Populate Variables'
							IF @accounting_period_end = 0 SET @accounting_period_end = CAST(LEFT(CONVERT(VARCHAR, EOMONTH(GETDATE(),5), 112),6) AS INTEGER);
							SET @accounting_period_start = CAST(LEFT(CAST(@accounting_period_end AS CHAR(6)),4) AS INTEGER)*100;

							SELECT	d.mission_id,
									d.mission_name
							FROM	dw_db.cognos.mission AS d;

                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO