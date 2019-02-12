/***************************************************************************************
Name      : Medicine Financial System - QL Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates financial-statement indexing tables
****************************************************************************************
PREREQUISITES:
- ERROR HANDLING
- COGNOS SCHEMA
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
IF SCHEMA_ID('fin') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA fin');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'fin', 
            @level0type=N'SCHEMA',
            @level0name=N'fin';
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

        SET @schemaName = 'fin'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='account_to_coa'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='coa'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 3
        BEGIN
            SET @objectName ='coa_type'
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

PRINT '--fin.coa_type'
BEGIN TRY
    CREATE TABLE fin.coa_type
        (
            account_type               NVARCHAR(1)                     NOT NULL,
            account_type_label         NVARCHAR(35)                    NOT NULL,
            account_type_description   NVARCHAR(MAX)                       NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_fin_coa_type            PRIMARY KEY CLUSTERED(account_type)
        )
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--fin.coa_type DEFAULT DATA'
BEGIN TRY
    INSERT INTO fin.coa_type
                (
                    account_type,
                    account_type_label,
                    account_type_description
                )
                VALUES
                ('B','Balance Sheet',NULL),
                ('I','Income Statement','The Income Statement is used to summarize results of business operations for a period of time, not longer than one year, to determine if the organization is operating efficiently.  It is a measure of the results of operations representing the difference between revenue and expense for the reported period.')
                ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--fin.coa'
BEGIN TRY
    CREATE TABLE fin.coa
        (
            account                         CHAR(5)                         NOT NULL,
            account_label                   NVARCHAR(255)                       NULL,
            account_definition              NVARCHAR(MAX)                       NULL,
            account_type                    NVARCHAR(1)                     NOT NULL                                                    DEFAULT 'I',
            mgma_account                    BIT                             NOT NULL                                                    DEFAULT 0,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_fin_coa                      PRIMARY KEY CLUSTERED(account)
        )
        CREATE INDEX FK_account_type ON fin.coa(account_type);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--fin.coa DEFAULT DATA';
BEGIN TRY
    INSERT INTO fin.coa
                (
                    account,
                    account_label,
                    account_type,
                    mgma_account
                )
                VALUES
                ('40000','Sources of Funds','I',0),                                                     --
                    ('44000','Operating Revenue','I',0),                                                --
                        ('44100','Health System / Physician Group','I',0),                              --
                            ('44110','CARE Payment','I',0),                                             --
                            ('44120','Professional Services (ASC)','I',0),                              --
                            ('44130','Government Agreements','I',0),                                    --
                            ('44140','Clinical Benefits','I',0),                                        --
                            ('44150','Health System Support','I',0),                                    --
                                ('44151','Transitional Support','I',0),                                 --
                                ('44152','Strategic Support','I',0),                                    --
                                ('44153','Start-Up Support','I',0),                                     --
                                ('44159','Other','I',0),                                                --
                        ('44200','Permanent Budget & IDCR','I',0),                                      --
                            ('44210','Permanent Budget','I',0),                                         --
                            ('44220','Indirect Cost Recovery','I',0),                                   --
                        ('44300','Other Revenues','I',0),                                               --
                            ('44310','Gifts, Grants, & Clinical Trials','I',0),                         --
                            ('44320','Teaching & Conferences','I',0),                                   --
                            ('44330','Faculty Activities','I',0),                                       --
                            ('44340','Self-Sustaining Services','I',0),                                 --
                            ('44350','Material Transfer Agreements & Sales','I',0),                     --
                            ('44390','Other Income','I',0),                                             --
                        ('44900','Other Transfers','I',0),                                              --
                ('50000','Uses of Funds','I',0),                                                        --
                    ('55000','Labour & Benefits','I',0),                                                --
                        ('55100','Academic Wages & Benefits','I',0),                                    --
                            ('55110','Academic Salaries','I',0),                                        --
                            ('55120','General Assistance - Academic','I',0),                            --
                            ('55130','Net Labour Accruals','I',0),                                      --
                            ('55140','Adjustments','I',0),                                              --
                        ('55200','Staff Wages & Benefits','I',0),                                       --
                            ('55210','Academic Salaries','I',0),                                        --
                            ('55220','General Assistance - Academic','I',0),                            --
                            ('55230','Net Labour Accruals','I',0),                                      --
                            ('55240','Adjustments','I',0),                                              --
                        ('55300','General Wage & Other Accruals','I',0),                                --
                            ('55310','Mid-Level Z-Payment / Bonus Accruals','I',0),                     --
                            ('55320','Staff Bonus Accruals','I',0),                                     --
                            ('55330','Other Bonus Accruals','I',0),                                     --
                            ('55340','Other Accruals','I',0),                                           --
                        ('55400','Employee Benefits','I',0),                                            --
                            ('55410','Mandatory Programs','I',0),                                       --
                            ('55420','Health Programs','I',0),                                          --
                            ('55430','Retirement','I',0),                                               --
                            ('55440','Other Insurance','I',0),                                          --
                            ('55450','Net Benefits Accruals','I',0),                                    --
                            ('55460','Involuntary Separation Benefits','I',0),                          --
                        ('55500','Temporary / Contract Labour','I',0),                                  --
                            ('55510','Temporary Employment Services','I',0),                            --
                            ('55520','Other Temporary Labour','I',0),                                   --
                    ('56000','Administrative & General Expenses','I',1),                                --
                        ('56100','Building and Occupancy Expenses','I',1),                              --
                            ('56110','Building and Facilities','I',1),                                  --
                                ('56111','Building and Facilities','I',1),
                                ('56112','Building and Facilities-Leasehold Improvements','I',1),       --
                                ('56113','Building and Facilities-Land Improvements','I',1),
                            ('56120','Building and Facilities Rent/Lease','I',1),                       --
                            ('56130','Condominium Assessments/Monthly Maintenance Fees','I',1),
                            ('56140','General Maintenance','I',1),                                      --
                            ('56150','Utilities','I',1),
                                ('56151','Utilities-Water','I',1),
                                ('56152','Utilities-Electricity','I',1),
                                ('56153','Utilities-Waste Disposal','I',1),                             --
                                ('56155','Other Utilities','I',1),                                      --
                            ('56160','Property Taxes','I',1),
                            ('56170','Housekeeping/Maintenance','I',1),                                 --
                                ('56171','Housekeeping/Maintenance Services','I',1),                    --
                                ('56172','Housekeeping/Maintenance Supplies','I',1),                    --
                            ('56180','Safety & Security','I',0),                                        --
                            ('56190','Other Occupancy Expense','I',1),                                  --
                        ('56200','Furniture, Fixtures, and Equipment','I',1),                           --
                            ('56210','Furniture, Fixtures, and Equipment','I',1),                       --
                            ('56220','Furniture, Fixtures, and Equipment Lease/Rental Expense','I',1),  --
                            ('56230','Furniture, Fixtures, and Equipment Maintenance','I',1),
                        ('56300','Administrative Supplies and Services','I',1),                          --
                            ('56310','Postage, Shipping and Courier Services','I',1),                    --
                                ('56311','Postage','I',1),                                               --
                                ('56312','Shipping','I',1),                                              --
                                ('56313','Courier','I',1),                                               --
                            ('56320','Printing and Copying','I',1),
                                ('56321','Printing','I',1),
                                ('56322','Copying','I',1),
                            ('56330','Administrative Consumable Supplies and Nondepreciable Resources','I',1),
                                ('56331','Office Supplies','I',1),
                                ('56332','Preprinted Forms','I',1),
                                ('56333','Medical Record Supplies','I',1),
                                ('56334','Library/Books and Subscriptions','I',1),
                                ('56335','Minor Administrative Equipment','I',1),
                                ('56336','Other Administrative Consumable Supplies','I',1),
                            ('56340','Purchased Professional Services','I',1),
                                ('56341','Accounting Services','I',1),
                                ('56342','Legal Services','I',1),
                                ('56343','Actuarial Services','I',1),
                                ('56344','Pension Administration','I',1),
                                ('56345','Consulting Services','I',1),
                                ('56346','Other Professional Services','I',1),
                            ('56350','Purchased Services','I',1),
                                ('56351','Answering Services','I',1),
                                ('56352','Medical Transcription Services','I',1),
                                ('56353','Biohazardous Waste Removal','I',1),
                                ('56354','Payment Card Processing','I',1),
                                ('56355','Bank Processing','I',1),
                                ('56356','Payroll Services','I',1),
                                ('56357','Patient billing services','I',1),
                                ('56358','Other General and Administrative Purchased Services','I',1),
                            ('56360','Management Services','I',1),
                                ('56361','Medical Directorships','I',1),
                                ('56362','MSO/PPMC Management Services','I',1),
                                ('56363','Management Company Incentive','I',1),
                                ('56364','Other Management Services','I',1),
                            ('56370','Recruiting','I',1),
                                ('56371','Physician Recruitment','I',1),
                                ('56372','Nonphysician Provider Recruitment','I',1),
                                ('56373','Support Staff Recruitment','I',1),
                            ('56380','Practice Regulatory, Licensure, and Accreditation Expenses','I',1),
                                ('56381','Regulatory Fees','I',1),
                                ('56382','Medical Practice Licenses and Permits','I',1),
                                ('56383','Accreditation Expenses','I',1),
                                ('56384','Other Practice Regulatory, Licensure, and Accreditation Expenses','I',1),
                            ('56390','Other Administrative Supplies and Services','I',1),
                        ('56400','Employee Related Expenses','I',1),
                            ('56410','Employee relations meals and functions','I',1),
                            ('56420','Cafeteria','I',1),
                            ('56430','Employee Relations','I',1),
                            ('56440','Employee Uniforms','I',1),
                            ('56450','Other Employee Related Expense','I',1),
                        ('56500','Vehicles and Travel','I',1),                                           --
                            ('56510','Motor Vehicles','I',1),                                            --
                                ('56511','Motor Vehicles-Depreciation','I',1),                           --
                                ('56512','Motor Vehicles-Lease/Rental','I',1),
                                ('56513','Motor Vehicles-Maintenance','I',1),                            --
                                ('56514','Motor Vehicles-Gas','I',1),
                                ('56515','Motor Vehicles-Parking','I',1),
                            ('56520','Business Travel','I',1),
                                ('56521','Business Travel-Transportation','I',1),
                                ('56522','Business Travel-Lodging','I',1),
                                ('56523','Business Travel-Meals','I',1),
                                ('56524','Business Travel-Other','I',1),
                        ('56600','Promotion and Marketing','I',1),                                       --
                            ('56610','Advertising','I',0),                                               --
                            ('56620','Personnel Recruitment','I',0),                                     --
                            ('56630','Events & Promotional Materials','I',0),                            --
                            ('56640','Gifts - Flowers, Tickets, & Contributions','I',0),                 --
                        ('56700','Insurance','I',1),
                            ('56710','Business and Casualty Insurance','I',1),
                                ('56711','Officers and Directors Liability','I',1),
                                ('56712','Other Liability','I',1),
                                ('56713','Reinsurance for At-Risk Global / Capitation Contracts','I',1),
                                ('56714','Officers and Overhead Insurance','I',1),
                                ('56715','Business Continuation Insurance','I',1),
                                ('56716','Fire, Theft, and Other Casualty Insurance','I',1),
                                ('56717','Automobile Insurance','I',1),
                                ('56718','Other Insurance','I',1),
                            ('56720','Professional Liability Insurance','I',1),
                                ('56721','Physicians','I',1),
                                ('56722','Nonphysician Providers','I',1),
                                ('56723','Clinical, Ancillary, and Research Staff','I',1),
                                ('56724','Administrative Staff','I',1),
                                ('56725','Global Coverage','I',1),
                                ('56726','Other Professional Liability','I',1),

                        ('56900','Assessments & Shared Services','I',0),                                 --
                            ('56910','Campus Administration & Assessments','I',0),                       --
                            ('56920','Shared Services / SOFI','I',0),                                    --
                            ('56930','General Liability Insurance','I',0),                               --
                            ('56940','Information Technology Equipment','I',1),
                                ('56941','Information Technology Depreciation','I',1),
                                ('56942','Information Technology Lease/Rental','I',1),
                                ('56943','Information Technology Maintenance','I',1),                    --
                                ('56944','Other Information Technology Equipment Expense','I',1),
                            ('56950','Information Technology Software','I',1),
                                ('56951','Software Purchase/License','I',1),
                                ('56952','Software Amortization','I',1),
                                ('56953','Software Maintenance','I',1),
                                ('56954','Software-Other','I',1),
                            ('56960','Information Technology Supplies and Minor Equipment','I',1),       --
                            ('56970','Information Technology Purchased Services','I',1),                 --
                                ('56971','Internet Access/ISP','I',1),                                   --
                                ('56972','Cable/Satellite Service','I',1),
                                ('56973','Telecommunications (T1/DSL) Lines','I',1),
                                ('56974','Web Hosting','I',1),
                                ('56975','Purchased Information Technology services','I',1),
                                ('56976','Information Technology Consulting Services','I',1),
                                ('56977','Clinical Services Billing Service Bureau','I',1),
                                ('56978','Back up and archival storage','I',1),
                                ('56979','Other Purchased Information Technology Services','I',1),       --
                            ('56980','Telecommunications Purchased Services','I',0),
                                ('56981','Telephone Landline Service','I',0),                            --
                                ('56982','Telephone Long Distance Service','I',0),                       --
                                ('56983','Cell Phone Service','I',0),                                    --
                                ('56984','Pager Service','I',0),                                         --
                                ('56985','Videoconference service','I',0),
                                ('56986','Other telecommunications expense','I',0),                      --
                                ('56987','Internet Access/ISP','I',0),
                                ('56989','Other Telecom Expense','I',0),                                 --
                            ('56990','Other Information Technology Expense','I',1),
                    ('57000','Elective Costs','I',0),                                                    --
                        ('57100','Meals, Meetings, & Events','I',0),                                     --
                            ('57110','Meetings & Conferences','I',0),                                    --
                                ('57111','Facility Fees','I',0),                                         --
                                ('57112','Business Technology Services','I',0),                          --
                                ('57113','Event Services','I',0),                                        --
                            ('57120','Meals & Catering','I',0),                                          --
                                ('57121','Catering Services','I',0),                                     --
                                ('57122','UCSD Faculty Club','I',0),                                     --
                                ('57123','Other Meals & Beverages','I',0),                              --
                                ('57124','Alcoholic Beverages','I',0),                                   --
                            ('57130','Transportation','I',0),                                            --
                                ('57131','Local / Non-Travel','I',0),                                    --
                            ('57140','Employee Gifts & Awards (Non-Cash)','I',0),                        --
                        ('57200','Computer Equipment, Services, & Supplies','I',0),                      --
                            ('57210','Computer Hardware & Equipment','I',0),                             --
                            ('57220','Computer Software & Services','I',0),                              --
                                ('57221','Cloud Computing & Hosting','I',0),                             --
                                ('57222','Programming & Other Services','I',0),                          --
                                ('57223','Software & Licenses','I',0),                                   --
                            ('57230','Computer Supplies','I',0),                                         --
                        ('57300','Purchased Services','I',0),                                            --
                            ('57310','Audio/Visual Services','I',0),                                     --
                        ('57400','Professional Development','I',0),                                     --
                            ('57410','Membership Dues & Subscriptions','I',0),                      --
                            ('57420','Professional Development Conference and Meeting attendance','I',0),
                            ('57430','Professional Development Audio conference participation','I',0),
                            ('57440','Professional Development Tuition & Online Education','I',0),
                            ('57450','Professional Development Travel','I',0),
                            ('57460','Professional Development Lodging and Meals','I',0),
                            ('57470','Professional Development Dues and Memberships','I',0),
                            ('57480','Professional Development Licenses','I',0),
                            ('57490','Professional Development - Other','I',0),
                        ('57500','Other Equipment, Services, & Supplies','I',0),
                            ('57510','Express Card - Uncategorized','I',0),
                            ('57520','Other Tools & Equipment','I',0),
                                ('57521','Other Non-Inventorial Equipment','I',0),
                                ('57522','Minor Equipment ($200 - $4,999)','I',0),
                                ('57523','Minor Tools ($200 - $4,999)','I',0),

                    ('58000','Research Support, Medical, Labs','I',0),                                   --
                        ('58100','Environmental Health & Safety','I',0),                                 --
                        ('58200','Lab & Field Supplies & Services','I',0),                               --
                        ('58300','UCSD Support Services','I',0),                                         --
                        ('58400','Medical Supplies','I',0),                                              --
                        ('58500','Clinical Trials','I',0),                                               --
                            ('58510','Clinical Trials Management (SOM)','I',0),                          --
                            ('58520','Human Subjects Costs','I',0),                                      --
                            ('58530','Patient Care','I',0),                                              --
                            ('58540','Participant Costs','I',0),                                         --
                            ('58550','Study Supplies','I',0),                                            --
                            ('58560','Travel','I',0),                                                    --
                        ('58600','Subcontracted Awards','I',0),                                          --
                    ('59000','Health System & Associated Transactions','I',0),                           --
                        ('59100','HS Intercompany Transactions','I',0),                                  --
                        ('59200','Hospital Equipment','I',0),                                            --
                        ('59300','Clinical Tax','I',0),                                                  --
                            ('59310','SOM/Dean Clinical Tax','I',0),                                     --
                            ('59320','Department Clinical Tax','I',0),                                   --
                        ('59400','Travel','I',0)                                                         --
                ;
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--fin.account_to_coa'
BEGIN TRY
    CREATE TABLE fin.account_to_coa
        (
            pa_account                      CHAR(6)                         NOT NULL,
            coa_account                     CHAR(5)                         NOT NULL,
            mgma_account                    CHAR(4)                             NULL,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_fin_account_to_coa           PRIMARY KEY CLUSTERED(pa_account)
        )
        CREATE INDEX FK_account_to_coa_coa_account ON fin.account_to_coa(coa_account);
        CREATE INDEX FK_account_to_coa_mgma_account ON fin.account_to_coa(mgma_account);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO

PRINT '--fin.xref_mission'
BEGIN TRY
    CREATE TABLE fin.xref_mission
        (
            pf_fund                         CHAR(6)                         NOT NULL,
            pp_program                      CHAR(6)                         NOT NULL,
            mission_id                      INT                                 NULL                                                    DEFAULT 3,
            createdby                       NVARCHAR(255)                   NOT NULL                                                    DEFAULT USER_NAME(),
            createddate                     DATETIME2	                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            lastupdatedby                   NVARCHAR(255)                       NULL,
            lastupdated                     DATETIME2(2)                        NULL,
            rowguid                         UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
            versionnumber                   ROWVERSION						NOT	NULL,
            validfrom                       DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
            validto                         DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
            CONSTRAINT                      PK_fin_xref_mission             PRIMARY KEY CLUSTERED(pf_fund,pp_program)
        )
        CREATE INDEX FK_fin_xref_mission_fund_id ON fin.xref_mission(pf_fund);
        CREATE INDEX FK_fin_xref_mission_program_id ON fin.xref_mission(pp_program);
        CREATE INDEX FK_fin_xref_mission_mission_id ON fin.xref_missioN(mission_id);
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH
GO