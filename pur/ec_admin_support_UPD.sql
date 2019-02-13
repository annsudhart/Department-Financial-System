/***************************************************************************************
Name      : BSO Financial Management Interface - ec_admin_support_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for pur.ec_admin_support
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

IF OBJECT_ID('pur.ec_admin_support_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.ec_admin_support_UPD
END

EXEC PrintNow '** CREATE pur.ec_admin_support';
GO
CREATE PROCEDURE    pur.ec_admin_support_UPD
                    (
                        @ResetMe INT = 0,
                        @StopDateString NVARCHAR(10) = ''
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE @last_last_activity_date DATETIME2;
                            DECLARE @last_id DECIMAL(10,0);
                            DECLARE @SQL NVARCHAR(MAX) = '';
                            DECLARE @StopDate DATE = NULL;

                            EXEC PrintNow '-- Find pur.ec_admin_support'
                            IF OBJECT_ID('pur.ec_admin_support','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('pur.ec_admin_support','U') IS NOT NULL DROP TABLE pur.ec_admin_support
                                    EXEC PrintNow '-- pur.ec_admin_support'
                                    CREATE TABLE pur.ec_admin_support
                                    (
                                        role_key                        DECIMAL(18,0)                   NOT NULL,
                                        person_key                      DECIMAL(18,0)                   NOT NULL,
                                        workgroup_key                   DECIMAL(18,0)                   NOT NULL,
                                        description                     VARCHAR(35)                     NOT NULL,
                                        campus_id                       VARCHAR(9)                          NULL,
                                        affiliate_id                    DECIMAL(18,0)                       NULL,
                                        card_name                       VARCHAR(24)                         NULL,
                                        name_comp                       VARCHAR(26)                     NOT NULL,
                                        home_department_code            VARCHAR(6)                          NULL,
                                        name_salutary                   VARCHAR(60)                     NOT NULL,
                                        email_address                   VARCHAR(40)                     NOT NULL,
                                        phone_number                    VARCHAR(20)                         NULL,
                                        mail_drop                       VARCHAR(6)                          NULL,
                                        employee_id                     VARCHAR(9)                      NOT NULL,
                                        emp_status_cd                   VARCHAR(1)                          NULL,
                                        user_id                         VARCHAR(8)                      NOT NULL,
                                        last_activity_date              DATETIME2                       NOT NULL,
                                        refresh_date                    DATETIME2                       NOT NULL,
                                        rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number                  ROWVERSION
                                    )
                                    CREATE INDEX I_CARD_NAME ON pur.ec_admin_support(card_name)
                                    CREATE INDEX I_EMPLOYEE_ID ON pur.ec_admin_support(employee_id)
                                    CREATE INDEX I_NAME_COMP ON pur.ec_admin_support(name_comp)
                                    CREATE INDEX I_WORKGROUP_KEY ON pur.ec_admin_support(workgroup_key)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.last_activity_date) FROM pur.ec_admin_support AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);

                            EXEC PrintNow '-- Specify maximum ledger date to pull'
                            IF @StopDateString <> '' SET @StopDate = CAST(@StopDateString AS DATE);
                            IF @StopDate IS NULL SELECT @StopDate = MAX(d.last_activity_date) FROM DW_DB..PUR.EC_ADMIN_SUPPORT AS d;

                            EXEC PrintNow '-- Updating Existing Records'
                            UPDATE  pur.ec_admin_support
                            SET     role_key = s.role_key,
                                    person_key = s.person_key,
                                    workgroup_key = s.workgroup_key,
                                    description = s.description,
                                    campus_id = s.campus_id,
                                    affiliate_id = s.affiliate_id,
                                    card_name = s.card_name,
                                    name_comp = s.name_comp,
                                    home_department_code = s.home_department_code,
                                    name_salutary = s.name_salutary,
                                    email_address = s.email_address,
                                    phone_number = s.phone_number,
                                    mail_drop = s.mail_drop,
                                    employee_id = s.employee_id,
                                    emp_status_cd = s.emp_status_cd,
                                    user_id = s.user_id,
                                    last_activity_date = s.last_activity_date,
                                    refresh_date = s.refresh_date
                            FROM    pur.ec_admin_support AS d
                                    INNER JOIN DW_DB..PUR.EC_ADMIN_SUPPORT AS s ON (
                                        d.role_key = s.role_key AND
                                        d.person_key = s.person_key AND
                                        d.workgroup_key = s.workgroup_key)
                            WHERE   s.last_activity_date > @last_last_activity_date;

                            EXEC PrintNow '-- Inserting New Records'
                            INSERT INTO pur.ec_admin_support (
										role_key,
                                        person_key,
                                        workgroup_key,
                                        description,
                                        campus_id,
                                        affiliate_id,
                                        card_name,
                                        name_comp,
                                        home_department_code,
                                        name_salutary,
                                        email_address,
                                        phone_number,
                                        mail_drop,
                                        employee_id,
                                        emp_status_cd,
                                        user_id,
                                        last_activity_date,
                                        refresh_date)
                                        SELECT  s.role_key,
                                                s.person_key,
                                                s.workgroup_key,
                                                s.description,
                                                s.campus_id,
                                                s.affiliate_id,
                                                s.card_name,
                                                s.name_comp,
                                                s.home_department_code,
                                                s.name_salutary,
                                                s.email_address,
                                                s.phone_number,
                                                s.mail_drop,
                                                s.employee_id,
                                                s.emp_status_cd,
                                                s.user_id,
                                                s.last_activity_date,
                                                s.refresh_date
                                        FROM    DW_DB..PUR.EC_ADMIN_SUPPORT AS s
                                                LEFT JOIN pur.ec_admin_support AS d 
                                                    ON  d.role_key = s.role_key 
                                                        AND d.person_key = s.person_key 
                                                        AND d.workgroup_key = s.workgroup_key 
                                        WHERE   s.last_activity_date > @last_last_activity_date 
                                                AND s.last_activity_date <= @StopDate
                                                AND d.person_key IS NULL;
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO