/***************************************************************************************
Name      : Medicine Financial System - QueryLink Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Mimics QueryLink - Operating Ledger Detail for MEDICINE
****************************************************************************************
PREREQUISITES:
- ga Schema Creation & Update
- qlink_db Schema Creation & Update
- coa_db Schema Creation & Update
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
IF SCHEMA_ID('ql') IS NULL
	BEGIN TRY
        EXEC('CREATE SCHEMA ql');
        EXEC sys.sp_addextendedproperty 
            @name=N'MS_Description', 
            @value=N'QueryLink Queries', 
            @level0type=N'SCHEMA',
            @level0name=N'ql';
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
        IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
    END CATCH
GO

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('ql.index_balance','V') IS NOT NULL DROP VIEW ql.index_balance;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE VIEW';
GO
CREATE VIEW ql.index_balance
            AS
            SELECT  bal.full_accounting_period,
                    oh3.orghier_level3,
                    oh3.orghier_level3_title, 
                    oh4.orghier_level4,
                    oh4.orghier_level4_title, 
                    fh.fundhier_level1, 
                    fh1.fundhier_level1_title, 
                    fh.fundhier_level2,
                    fh2.fundhier_level2_title, 
                    fh.fundhier_level3,
                    fh3.fundhier_level3_title,
                    i.[status],
                    i.indx,
                    i.fund,
                    i.organization,
                    i.program,
                    (CASE WHEN msn.mission_id IS NULL THEN 3
                          ELSE msn.mission_id
                    END) AS 'Mission',
                    i.indx_title,
                    i.fund_title,
                    i.organization_title,
                    i.program_title,
                    i.location_title,
                    (CASE WHEN msn.mission_id IS NULL THEN 'Research'
                          ELSE msn.mission_name
                    END) AS 'Mission_Title',
                    tm.team_id,
                    tm.team_name,
                    bal.overall_overdraft AS "Overall_Balance",
                    bal.exp_trans_overdraft AS "ExpTransIDC_Balance",
                    bal.fiscal_ytd_revenue AS "fYTD_Revenue_Balance",
                    bal.fiscal_ytd_expenditures AS "fYTD_Expenditure_Balance",
                    bal.fiscal_ytd_transfers AS "fYTD_Transfer_Balance",
                    bal.fiscal_ytd_indirect_cost AS "fYTD_IDC_Balance",
                    bal.fiscal_ytd_encumbrance AS "fYTD_Encumbrance_Balance",
                    (CASE WHEN dfct.org_fund_overall_overdraft < 0 THEN 1 ELSE 0 END) AS 'Deficit_OrgFund',
                    (CASE SUBSTRING(CAST(bal.full_accounting_period AS CHAR(6)),5,2)
                          WHEN '00' THEN NULL
                          WHEN '12' THEN NULL
                          WHEN '13' THEN NULL
                          WHEN '14' THEN DATEADD(dd,-1,DATEADD(mm,-5,CAST(SUBSTRING(CAST(bal.full_accounting_period AS VARCHAR(8)),1,4) + '12' +'01' AS DATETIME2)))
                          ELSE DATEADD(dd,-1,DATEADD(mm,-5,CAST(CAST(bal.full_accounting_period AS VARCHAR(8))+'01' AS DATETIME2)))
                    END) AS 'Month_End'
            FROM    ga_fact.overdraft_by_index AS bal
                    INNER JOIN      coa_db.indx                 AS i    ON i.indx_key = bal.indx_key
                                                                        AND i.most_recent_lfag = 'Y'
                    INNER JOIN      coa_db.orgnhier_table       AS oh   ON oh.orgn_code = i.organization 
                    INNER JOIN      coa_db.fundhier_table       AS fh   ON i.fund = fh.fund_code
                    LEFT OUTER JOIN qlink_db.orghier_level3     AS oh3  ON oh.orgnhier_level3 = oh3.orghier_level3
                    LEFT OUTER JOIN qlink_db.orghier_level4     AS oh4  ON oh.orgnhier_level4 = oh4.orghier_level4
                    LEFT OUTER JOIN qlink_db.fundhier_level1    AS fh1  ON fh.fundhier_level1 = fh1.fundhier_level1
                    LEFT OUTER JOIN qlink_db.fundhier_level2    AS fh2  ON fh.fundhier_level2 = fh2.fundhier_level2
                    LEFT OUTER JOIN qlink_db.fundhier_level3    AS fh3  ON fh.fundhier_level3 = fh3.fundhier_level3
                    LEFT OUTER JOIN fin.xref_mission            AS xref ON i.fund = xref.pf_fund
                                                                        AND i.program = xref.pp_program 
                    LEFT OUTER JOIN cognos.mission              AS msn  ON xref.mission_id = msn.mission_id
                    LEFT OUTER JOIN dbo.team_index              AS tmi  ON  i.indx = tmi.index_code
                    LEFT OUTER JOIN dbo.team                    AS tm   ON  tmi.team_id = tm.team_id
                    INNER JOIN (SELECT  bal.month_key,
                                        i.organization,
                                        i.fund,
                                        SUM(bal.overall_overdraft) AS 'org_fund_overall_overdraft'
                                FROM    ga_fact.overdraft_by_index AS bal
                                        INNER JOIN coa_db.indx AS i ON i.indx_key = bal.indx_key
                                GROUP BY bal.month_key,
                                         i.organization,
                                         i.fund
                               ) AS dfct ON bal.month_key = dfct.month_key AND i.fund = dfct.fund AND i.organization = dfct.organization
            WHERE   oh.orgnhier_level3 IN('JBAA03')
                    AND i.indx NOT IN('MEDBD65');