/***************************************************************************************
Name      : BSO Financial Management Interface - EMPLOYEE
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates EMPLOYEE index tables
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
IF SCHEMA_ID('employee') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA [employee]');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'Employee Population Data - Excludes Secure Fields.', 
            @level0type=N'SCHEMA',
            @level0name=N'employee';
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

        SET @schemaName = 'employee'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='p_employee'
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

PRINT '--employee.p_employee'
BEGIN TRY
    CREATE TABLE employee.p_employee
        (
            emb_id                          NUMERIC(18,0)                   NOT NULL,
            refresh_date		            DATE		                    NOT	NULL,
            red_refresh_type		        SMALLINT		                NOT	NULL,
            emp_record_code		            SMALLINT		                NOT	NULL,
            emb_person_id		            INT		                        NOT	NULL,
            emb_employee_number		        INT		                        NOT	NULL,
            emp_change_code		            CHAR(1)		                    NOT	NULL,
            emb_employee_name		        VARCHAR(26)		                    NULL,
            emp_employment_status_code	    CHAR(1)		                        NULL,
            emp_paf_gen_number		        VARCHAR(4)		                    NULL,
            emp_action_date		            DATE		                        NULL,
            emp_hire_date		            DATE		                        NULL,
            emp_home_department_code		VARCHAR(6)		                    NULL,
            emp_alternate_department_code	VARCHAR(6)		                    NULL,
            emp_timekeeper_code		        VARCHAR(8)		                    NULL,
            emp_college_code		        VARCHAR(3)		                    NULL,
            emp_mailcode		            VARCHAR(5)		                    NULL,
            emp_pay_distribution_code		CHAR(1)		                        NULL,
            emp_separation_date		        DATE		                        NULL,
            emp_loa_begin_date		        DATE		                        NULL,
            emp_loa_return_date		        DATE		                        NULL,
            emp_loa_status_code		        CHAR(1)		                        NULL,
            emp_employee_relation_code		CHAR(1)		                        NULL,
            emp_emp_relation_unit_code		VARCHAR(2)		                    NULL,
            emp_student_status_code		    CHAR(1)		                        NULL,
            emp_current_student_flag		CHAR(1)		                        NULL,
            emp_secured_student_flag		CHAR(1)		                        NULL,
            emp_next_salary_review_code		CHAR(1)		                        NULL,
            emp_next_salary_review_date		DATE		                        NULL,
            emp_oath_signature_date		    DATE		                        NULL,
            emp_retirement_elig_code		CHAR(1)		                        NULL,
            emp_fica_eligibility_code		CHAR(1)		                        NULL,
            emp_assigned_benefit_elig_code	CHAR(1)		                        NULL,
            emp_derived_benefit_elig_code	CHAR(1)		                        NULL,
            emp_citizenship_code		    CHAR(1)		                        NULL,
            emp_visa_type_code		        VARCHAR(2)		                    NULL,
            emp_visa_end_date		        DATE		                        NULL,
            emp_country_residency_code		VARCHAR(2)		                    NULL,
            emp_i9_date		                DATE		                        NULL,
            emp_deduct_pay_schedule_code	VARCHAR(2)		                    NULL,
            emp_emp_home_department_name	VARCHAR(30)		                    NULL,
            emb_employee_id		            VARCHAR(9)		                    NULL,
            emp_alt_department_2_code		VARCHAR(6)		                    NULL,
            emp_alt_department_3_code		VARCHAR(6)		                    NULL,
            emp_all_departments		        VARCHAR(62)		                    NULL,
            emp_name_suffix		            VARCHAR(4)		                    NULL,
            emp_prior_name		            VARCHAR(26)		                    NULL,
            emp_original_hire_date		    DATE		                        NULL,
            emp_probation_end_date		    DATE		                        NULL,
            emp_benefit_elig_eff_date		DATE		                        NULL,
            emp_first_name		            VARCHAR(30)		                    NULL,
            emp_middle_name		            VARCHAR(30)		                    NULL,
            emp_last_name		            VARCHAR(30)		                    NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_employee_p_employee PRIMARY KEY CLUSTERED(emb_id)
        )
        CREATE INDEX IDX1405011731200   ON  employee.p_employee(emb_employee_id, emp_citizenship_code)
        CREATE INDEX I_EMPLOYEE2        ON  employee.p_employee(emb_id, emp_record_code)
        CREATE INDEX I_EMPLOYEE_DEPART1 ON  employee.p_employee(emp_home_department_code)
        CREATE INDEX I_EMPLOYEE_ID3     ON  employee.p_employee(emb_person_id)
        CREATE INDEX I_EMPLOYEE_IX1     ON  employee.p_employee(emb_employee_id, 
                                                                emp_alt_department_3_code, 
                                                                emp_alt_department_2_code,
                                                                emp_alternate_department_code, 
                                                                emp_home_department_code, 
                                                                emp_employment_status_code, 
                                                                emb_employee_number)
        CREATE INDEX I_EMPLOYEE_IX2     ON  employee.p_employee(emb_employee_number, emp_employment_status_code)
        CREATE INDEX I_EMPLOYEE_NAME1   ON  employee.p_employee(emb_employee_name)
        CREATE INDEX I_EMPLOYEE_TKP1    ON  employee.p_employee(emp_timekeeper_code)
        CREATE INDEX I_EMP_ID6          ON  employee.p_employee(emb_employee_id)
        ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH

PRINT '--bks.purchase_'

GO