/***************************************************************************************
Name      : Medicine Financial System - QueryLink Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Mimics QueryLink - Operating Ledger Detail for MEDICINE
- Based on ql_operating_ledger.sql
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
IF OBJECT_ID('ql.operating_ledger_pldetail','P') IS NOT NULL DROP PROCEDURE ql.operating_ledger_pldetail;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    ql.operating_ledger_pldetail
                    (
                        @selectFullAccountingPeriod INT = 0,
                        @pullDataPeriods VARCHAR(5) = 'FYTD',
                        @orghierLevel4 CHAR(6) = '',
                        @acctAdjBOY BIT = 1,
                        @acctAdjEOY BIT = 1,
                        @acctAdjAnl BIT = 1,
                        @teamID INT = 0,
                        @pi_account_index CHAR(10) = ''
                    )
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE     @SQL AS VARCHAR(MAX);
                            DECLARE     @startingFiscalPeriod AS INT;
                            DECLARE     @endingFiscalPeriod AS INT;
                            DECLARE     @startingFiscalPeriodTXT AS CHAR(6);
                            DECLARE     @endingFiscalPeriodTXT AS CHAR(6);

                            IF @selectFullAccountingPeriod = 0 SET @selectFullAccountingPeriod = CAST(FORMAT(DATEADD(month,6-1,GETDATE()),'yyyyMM') AS INT);
                            SET @endingFiscalPeriod = @selectFullAccountingPeriod;
                            
                            IF @pullDataPeriods = 'MTD' SET @startingFiscalPeriod = @selectFullAccountingPeriod;
                            ELSE IF @pullDataPeriods = 'FYTD' SET @startingFiscalPeriod = CAST(SUBSTRING(CAST(@selectFullAccountingPeriod AS CHAR(6)),1,4) + '00' AS INT);
                            ELSE IF @pullDataPeriods = '12MTD' SET @startingFiscalPeriod = CAST(FORMAT(DATEADD(month,-12+1,CAST(CAST(@selectFullAccountingPeriod AS VARCHAR(8)) + '01' AS DATETIME2)),'yyyyMM') AS INT);
                            ELSE SELECT @startingFiscalPeriod = MIN(d.full_accounting_period) FROM ga.f_ledger_activity AS d;

                            SET @startingFiscalPeriodTXT = CAST(@startingFiscalPeriod AS VARCHAR(6));
                            SET @endingFiscalPeriodTXT = CAST(@endingFiscalPeriod AS VARCHAR(6));

                             SET @SQL = 'SELECT  ifoapal.full_accounting_period, 
                                                la.la_ledger_indicator, 
                                                oh3.orghier_level3, 
                                                oh3.orghier_level3_title, 
                                                oh4.orghier_level4, 
                                                oh4.orghier_level4_title, 
                                                oh5.orghier_level5, 
                                                oh5.orghier_level5_title, 
                                                fh.fundhier_level1, 
                                                fh1.fundhier_level1_title, 
                                                fh.fundhier_level2, 
                                                fh2.fundhier_level2_title, 
                                                fh.fundhier_level3, 
                                                fh3.fundhier_level3_title, 
                                                ifoapal.pi_account_index, 
                                                i.status, 
                                                ifoapal.pf_fund, 
                                                ifoapal.po_organization, 
                                                ifoapal.pa_account, 
                                                CASE 
                                                        WHEN SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' THEN ''5x'' 
                                                        WHEN SUBSTRING(ifoapal.pa_account, 1, 1) = ''7'' THEN ''7x'' 
                                                        ELSE SUBSTRING(ifoapal.pa_account, 1, 2) 
                                                END AS ''Sub_Account'', 
                                                ifoapal.pp_program, 
                                                (CASE 
                                                        WHEN msn.mission_id IS NULL THEN 3 
                                                        ELSE msn.mission_id 
                                                END) AS ''Mission'', 
                                                fp.pi_title, 
                                                pf.pf_title, 
                                                po.po_title, 
                                                pa.pa_title, 
                                                sat.subaccount_title, 
                                                pp.pp_title, 
                                                pl.pl_title, 
                                                (CASE 
                                                        WHEN msn.mission_id IS NULL THEN ''Research'' 
                                                        ELSE msn.mission_name 
                                                END) AS ''Mission_Title'', 
                                                ah1.accthier_level1, 
                                                ah1.accthier_level1_title, 
                                                ah2.accthier_level2, 
                                                ah2.accthier_level2_title, 
                                                ah3.accthier_level3, 
                                                ah3.accthier_level3_title, 
                                                ah4.accthier_level4, 
                                                ah4.accthier_level4_title, 
                                                ifoapal.account_type, 
                                                ac.account_type AS ''Account_Type_Desc'', 
                                                tm.team_id, 
                                                tm.team_name, 
                                                SUM(CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount 
                                                        ELSE 0.00 
                                                END) AS Budget, 
                                                SUM(CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END) AS Financial, 
                                                SUM(
                                                (CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END) - 
                                                (CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END)) AS BalanceWoEncumbrance, 
                                                SUM(CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''04'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''04'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END) AS Encumbrance, 
                                                SUM((CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''02'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END) - 
                                                (CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''03'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END) - 
                                                (CASE 
                                                        WHEN la.la_amount IS NULL THEN 0.00 
                                                        WHEN la.la_field_indicator = ''04'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) = ''5'' 
                                                                THEN la.la_amount * - 1 
                                                        WHEN la.la_field_indicator = ''04'' 
                                                                AND SUBSTRING(ifoapal.pa_account, 1, 1) <> ''5'' 
                                                                THEN la.la_amount ELSE 0.00 
                                                END)) AS BalanceWEncumbrance, 
                                                CAST(FORMAT(lt.lt_transaction_date, ''yyyyMMdd'') AS INT) AS Transaction_Date, 
                                                lt.lt_document_number, 
                                                lt.lt_document_reference_number, 
                                                lt.lt_sequence_number, 
                                                dt.dt_document_type, 
                                                lt.lt_description, 
                                                lt.lt_rule_class_code, 
                                                rcd.rule_class_desc, 
                                                lt.lt_encumbrance_number, 
                                                CAST(CASE i.[status] 
                                                        WHEN ''Inactive'' THEN 0 
                                                        ELSE 1 
                                                END AS BIT) AS ''Active_Index'', 
                                                CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)), 5, 2) 
                                                        WHEN ''00'' THEN 1 
                                                        ELSE 0 
                                                END AS BIT) AS ''Acct_Adj_BOY'', 
                                                CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)), 5, 2) 
                                                        WHEN ''13'' THEN 1 
                                                        WHEN ''14'' THEN 1 
                                                        ELSE 0 
                                                END AS BIT) AS ''Acct_Adj_EOY'', 
                                                CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)), 5, 2) 
                                                        WHEN ''00'' THEN 1 
                                                        WHEN ''13'' THEN 1 
                                                        WHEN ''14'' THEN 1 
                                                        ELSE 0 
                                                END AS BIT) AS ''Acct_Adj_Anl'', 
                                                ctyp.account_type AS ''COA_Account_Type'', 
                                                ctyp.account_type_label, 
                                                SUBSTRING(coat.coa_account, 1, 1) AS ''COA_Account_L1'', 
                                                SUBSTRING(coat.coa_account, 1, 2) AS ''COA_Account_L2'', 
                                                SUBSTRING(coat.coa_account, 1, 3) AS ''COA_Account_L3'', 
                                                SUBSTRING(coat.coa_account, 1, 4) AS ''COA_Account_L4'', 
                                                coat.coa_account, 
                                                coa.account_label '

                            SET @SQL = @SQL + 'FROM    ga.f_ifoapal AS ifoapal 
                                                INNER JOIN ga.f_ledger_activity AS la 
                                                        ON ifoapal.if_id = la.if_id 
                                                        AND ifoapal.full_accounting_period = la.full_accounting_period 
                                                INNER JOIN ga.f_ledger_transaction AS lt 
                                                        ON lt.lt_id = la.lt_id 
                                                        AND lt.full_accounting_period = la.full_accounting_period 
                                                INNER JOIN ga.f_document_type AS dt ON lt.dt_sequence_number = dt.dt_sequence_number 
                                                LEFT OUTER JOIN ga.f_period_index AS fp 
                                                        ON ifoapal.full_accounting_period = fp.full_accounting_period 
                                                        AND ifoapal.pi_account_index = fp.pi_account_index 
                                                LEFT OUTER JOIN ga.f_period_fund AS pf 
                                                        ON ifoapal.full_accounting_period = pf.full_accounting_period 
                                                        AND ifoapal.pf_fund = pf.pf_fund 
                                                LEFT OUTER JOIN ga.f_period_fund_type AS pft 
                                                        ON pf.full_accounting_period = pft.full_accounting_period 
                                                        AND pf.pft_fund_type = pft.pft_fund_type 
                                                LEFT OUTER JOIN ga.f_period_organization AS po 
                                                        ON ifoapal.full_accounting_period = po.full_accounting_period 
                                                        AND ifoapal.po_organization = po.po_organization 
                                                LEFT OUTER JOIN ga.f_period_location AS pl 
                                                        ON ifoapal.full_accounting_period = pl.full_accounting_period 
                                                        AND ifoapal.pl_location = pl.pl_location 
                                                LEFT OUTER JOIN ga.f_period_account AS pa 
                                                        ON ifoapal.full_accounting_period = pa.full_accounting_period 
                                                        AND ifoapal.pa_account = pa.pa_account 
                                                LEFT OUTER JOIN ga.f_period_account_type AS pat 
                                                        ON pa.full_accounting_period = pat.full_accounting_period 
                                                        AND pa.pat_account_type = pat.pat_account_type 
                                                LEFT OUTER JOIN fin.account_to_coa AS coat ON ifoapal.pa_account = coat.pa_account 
                                                LEFT OUTER JOIN fin.coa AS coa ON coat.coa_account = coa.account 
                                                LEFT OUTER JOIN fin.coa_type AS ctyp ON coa.account_type = ctyp.account_type 
                                                LEFT OUTER JOIN ga.f_period_program AS pp 
                                                        ON ifoapal.full_accounting_period = pp.full_accounting_period AND 
                                                        ifoapal.pp_program = pp.pp_program 
                                                INNER JOIN coa_db.orgnhier_table AS oh ON ifoapal.po_organization = oh.orgn_code 
                                                INNER JOIN coa_db.fundhier_table AS fh ON ifoapal.pf_fund = fh.fund_code 
                                                LEFT OUTER JOIN qlink_db.orghier_level3 AS oh3 ON oh.orgnhier_level3 = oh3.orghier_level3 
                                                LEFT OUTER JOIN qlink_db.orghier_level4 AS oh4 ON oh.orgnhier_level4 = oh4.orghier_level4 
                                                LEFT OUTER JOIN qlink_db.orghier_level5 AS oh5 ON oh.orgnhier_level5 = oh5.orghier_level5 
                                                LEFT OUTER JOIN qlink_db.fundhier_level1 AS fh1 ON fh.fundhier_level1 = fh1.fundhier_level1 
                                                LEFT OUTER JOIN qlink_db.fundhier_level2 AS fh2 ON fh.fundhier_level2 = fh2.fundhier_level2 
                                                LEFT OUTER JOIN qlink_db.fundhier_level3 AS fh3 ON fh.fundhier_level3 = fh3.fundhier_level3 
                                                INNER JOIN qlink_db.rule_class_desc AS rcd ON rcd.rule_class_code = lt.lt_rule_class_code 
                                                INNER JOIN qlink_db.subaccount_title AS sat ON SUBSTRING(ifoapal.pa_account, 1, 2) = sat.subaccount 
                                                INNER JOIN coa_db.accthier_table AS ah ON ifoapal.pa_account = ah.acct_code 
                                                INNER JOIN coa_db.account AS ac 
                                                        ON ifoapal.pa_account = ac.account 
                                                        AND ah.acct_code = ac.account 
                                                        AND ac.most_recent_flag = ''Y'' 
                                                LEFT OUTER JOIN qlink_db.accthier_level1 AS ah1 ON ah.accthier_level1 = ah1.accthier_level1 
                                                LEFT OUTER JOIN qlink_db.accthier_level2 AS ah2 ON ah.accthier_level2 = ah2.accthier_level2 
                                                LEFT OUTER JOIN qlink_db.accthier_level3 AS ah3 ON ah.accthier_level3 = ah3.accthier_level3 
                                                LEFT OUTER JOIN qlink_db.accthier_level4 AS ah4 ON ah.accthier_level4 = ah4.accthier_level4 
                                                LEFT OUTER JOIN coa_db.indx AS i ON ifoapal.pi_account_index = i.indx AND i.most_recent_flag = ''Y'' 
                                                LEFT OUTER JOIN fin.xref_mission AS xref 
                                                        ON ifoapal.pf_fund = xref.pf_fund 
                                                        AND ifoapal.pp_program = xref.pp_program 
                                                LEFT OUTER JOIN cognos.mission AS msn ON xref.mission_id = msn.mission_id 
                                                LEFT OUTER JOIN dbo.team_index AS tmi ON ifoapal.pi_account_index = tmi.index_code 
                                                LEFT OUTER JOIN dbo.team AS tm ON tmi.team_id = tm.team_id '
                            
                            SET @SQL = @SQL + 'WHERE       1 = 1 
                                                    AND oh.orgnhier_level3 IN(''JBAA03'') 
                                                    AND la.la_ledger_indicator = ''O''
                                                    AND ifoapal.pi_account_index NOT IN(''MEDBD65'') '
                            
                            SET @SQL = @SQL + 'AND ifoapal.full_accounting_period BETWEEN ' + @startingFiscalPeriodTXT + ' AND ' + @endingFiscalPeriodTXT + ' ';

                            IF @orghierLevel4 <> '' SET @SQL = @SQL + 'AND oh4.orghier_level4 IN(''' + @orghierLevel4 + ''') ';

                            IF @acctAdjBOY = 0 SET @SQL = @SQL + 'AND CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)) , 5 , 2) WHEN ''00'' THEN 1 ELSE 0 END AS BIT) = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)) , 5 , 2) WHEN ''13'' THEN 1 WHEN ''14'' THEN 1 ELSE 0 END AS BIT) = 0 ';
                            IF @acctAdjEOY = 0 SET @SQL = @SQL + 'AND CAST(CASE SUBSTRING(CAST(ifoapal.full_accounting_period AS CHAR(6)) , 5 , 2) WHEN ''00'' THEN 1 WHEN ''13'' THEN 1 WHEN ''14'' THEN 1 ELSE 0 END AS BIT) = 0 ';

                            IF @teamID <> 0 SET @SQL = @SQL + 'AND tm.team_id = ' + CAST(@teamID AS VARCHAR(MAX)) + ' ';

                            IF @pi_account_index <>'' SET @SQL = @SQL + 'AND ifoapal.pi_account_index IN(''' + @pi_account_index + ''') ';

                            SET @SQL = @SQL + 'GROUP BY ifoapal.full_accounting_period, 
                                                        oh3.orghier_level3, 
                                                        oh3.orghier_level3_title, 
                                                        oh4.orghier_level4, 
                                                        oh4.orghier_level4_title, 
                                                        oh5.orghier_level5, 
                                                        oh5.orghier_level5_title, 
                                                        fh.fundhier_level1, 
                                                        fh1.fundhier_level1_title, 
                                                        fh.fundhier_level2, 
                                                        fh2.fundhier_level2_title, 
                                                        fh.fundhier_level3, 
                                                        fh3.fundhier_level3_title, 
                                                        ifoapal.pi_account_index, 
                                                        i.status, 
                                                        ifoapal.pf_fund, 
                                                        ifoapal.po_organization, 
                                                        ifoapal.pa_account, 
                                                        ifoapal.pp_program, 
                                                        fp.pi_title, 
                                                        pf.pf_title, 
                                                        po.po_title, 
                                                        pa.pa_title, 
                                                        sat.subaccount_title, 
                                                        pp.pp_title, 
                                                        pl.pl_title, 
                                                        ah1.accthier_level1, 
                                                        ah1.accthier_level1_title, 
                                                        ah2.accthier_level2, 
                                                        ah2.accthier_level2_title, 
                                                        ah3.accthier_level3, 
                                                        ah3.accthier_level3_title, 
                                                        ah4.accthier_level4, 
                                                        ah4.accthier_level4_title, 
                                                        ifoapal.account_type, 
                                                        ac.account_type, 
                                                        tm.team_id, 
                                                        tm.team_name, 
                                                        CAST(FORMAT(lt.lt_transaction_date, ''yyyyMMdd'') AS INT), 
                                                        lt.lt_document_number, 
                                                        lt.lt_document_reference_number, 
                                                        lt.lt_sequence_number, 
                                                        dt.dt_document_type, 
                                                        lt.lt_description, 
                                                        lt.lt_rule_class_code, 
                                                        rcd.rule_class_desc, 
                                                        lt.lt_encumbrance_number, 
                                                        ctyp.account_type, 
                                                        ctyp.account_type_label, 
                                                        SUBSTRING(coat.coa_account, 1, 1), 
                                                        SUBSTRING(coat.coa_account, 1, 2), 
                                                        SUBSTRING(coat.coa_account, 1, 3), 
                                                        SUBSTRING(coat.coa_account, 1, 4), 
                                                        coat.coa_account, 
                                                        coa.account_label, 
                                                        oh.orgnhier_level3, 
                                                        la.la_ledger_indicator, 
                                                        (CASE WHEN msn.mission_id IS NULL THEN 3 ELSE msn.mission_id END), 
                                                        (CASE WHEN msn.mission_id IS NULL THEN ''Research'' ELSE msn.mission_name END) '

                            EXEC(@SQL);

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                            PRINT @SQL
                        END CATCH
                    END;
GO