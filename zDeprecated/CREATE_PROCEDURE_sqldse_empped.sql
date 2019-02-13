/***************************************************************************************
Name      : BSO Financial Management Interface - empped_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for sqldse.empped
****************************************************************************************
PREREQUISITES:
- error handling
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

IF OBJECT_ID('sqldse.empped_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE sqldse.empped_UPD
END

EXEC PrintNow '** CREATE sqldse.empped';
GO
CREATE PROCEDURE    sqldse.empped_UPD
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
                            DECLARE @process_yrmo CHAR(4)='';
                            DECLARE @process_prd NUMERIC(4,0) = 0;
                            DECLARE @stopdateval NUMERIC(4,0) = 0;

                            EXEC PrintNow '-- Find sqldse.empped'
                            IF OBJECT_ID('sqldse.empped','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('sqldse.empped','U') IS NOT NULL DROP TABLE sqldse.empped
                                    EXEC PrintNow '-- sqldse.empped'
                                    CREATE TABLE sqldse.empped
                                    (
                                        emp_id              CHAR(9)                     NOT NULL,
                                        [name]              CHAR(26)                    NOT NULL,
                                        home_dept           CHAR(6)                     NOT NULL,
                                        retr_pln            CHAR(1)                     NOT NULL,
                                        fica_elig           CHAR(1)                     NOT NULL,
                                        leave_elig          CHAR(1)                     NOT NULL,
                                        erng_end_dt         CHAR(6)                     NOT NULL,
                                        pay_cycle           CHAR(1)                     NOT NULL,
                                        key_ad_loc          CHAR(2)                     NOT NULL,
                                        sub                 CHAR(1)                     NOT NULL,
                                        obj_code            CHAR(4)                     NOT NULL,
                                        ifis_indx           CHAR(7)                     NOT NULL,
                                        ifis_orgn           CHAR(6)                     NOT NULL,
                                        ifis_fund           CHAR(6)                     NOT NULL,
                                        ifis_prgm           CHAR(6)                     NOT NULL,
                                        trans_end_dt        CHAR(6)                     NOT NULL,
                                        adj_code            CHAR(1)                     NOT NULL,
                                        dos                 CHAR(3)                     NOT NULL,
                                        title               CHAR(4)                     NOT NULL,
                                        time_hours          NUMERIC(7, 2)               NOT NULL,
                                        time_percent        NUMERIC(7, 4)               NOT NULL,
                                        rate_type           CHAR(1)                     NOT NULL,
                                        rate                NUMERIC(11, 4)              NOT NULL,
                                        grs_amt             NUMERIC(9, 2)               NOT NULL,
                                        earn_rel_cd         CHAR(1)                     NOT NULL,
                                        earn_appt_tp        CHAR(1)                     NOT NULL,
                                        bargaining_unit     CHAR(2)                     NOT NULL,
                                        retr_mtch           NUMERIC(9, 2)               NOT NULL,
                                        fica                NUMERIC(9, 2)               NOT NULL,
                                        medicr              NUMERIC(9, 2)               NOT NULL,
                                        health              NUMERIC(9, 2)               NOT NULL,
                                        ann_health          NUMERIC(9, 2)               NOT NULL,
                                        li                  NUMERIC(9, 2)               NOT NULL,
                                        ndi                 NUMERIC(9, 2)               NOT NULL,
                                        wc                  NUMERIC(9, 2)               NOT NULL,
                                        ui                  NUMERIC(9, 2)               NOT NULL,
                                        dental              NUMERIC(9, 2)               NOT NULL,
                                        vision              NUMERIC(9, 2)               NOT NULL,
                                        legal               NUMERIC(9, 2)               NOT NULL,
                                        esp                 NUMERIC(9, 2)               NOT NULL,
                                        core_medical        NUMERIC(9, 2)               NOT NULL,
                                        core_life           NUMERIC(9, 2)               NOT NULL,
                                        dntl_alt            NUMERIC(9, 2)               NOT NULL,
                                        visn_alt            NUMERIC(9, 2)               NOT NULL,
                                        ucrs_plan7          NUMERIC(9, 2)               NOT NULL,
                                        psbp_disab          NUMERIC(9, 2)               NOT NULL,
                                        psbp_life_add       NUMERIC(9, 2)               NOT NULL,
                                        psbp_brkr_adm       NUMERIC(9, 2)               NOT NULL,
                                        psbp_wc             NUMERIC(9, 2)               NOT NULL,
                                        ucrs_benefit_admin  NUMERIC(9, 2)               NOT NULL,
                                        sr_mgmt_bene        NUMERIC(9, 2)               NOT NULL,
                                        ucrp_supplement     NUMERIC(9, 2)               NOT NULL,
                                        iap                 NUMERIC(9, 2)               NOT NULL,
                                        tier_2016_suppl     NUMERIC(9, 2)                   NULL,
                                        tier_2016_dc        NUMERIC(9, 2)                   NULL,
                                        ben_expansion_1     NUMERIC(9, 2)                   NULL,
                                        ben_expansion_2     NUMERIC(9, 2)                   NULL,
                                        total_bene          NUMERIC(9, 2)               NOT NULL,
                                        process_yrmo        CHAR(4)                     NOT NULL,
                                        page_count          CHAR(5)                     NOT NULL,
                                        line_no             CHAR(2)                     NOT NULL,
                                        index_title         VARCHAR(30)                 NOT NULL,
                                        fund_title          VARCHAR(30)                 NOT NULL,
                                        refresh_date        DATETIME2(7)                NOT NULL,
                                        empped_id           NUMERIC(10, 0)              NOT NULL,
                                        emp_name            AS [name],
                                        prd_end_date        AS CAST(SUBSTRING(erng_end_dt,3,2) + '/' + SUBSTRING(erng_end_dt,5,2) + '/' + SUBSTRING(erng_end_dt,1,2) AS DATETIME2)      PERSISTED,
                                        rowguid             UNIQUEIDENTIFIER ROWGUIDCOL     NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number      ROWVERSION
                                    )
                                    CREATE CLUSTERED INDEX C_EMPPED     ON sqldse.empped(emp_id)
                                    CREATE           INDEX NC_EMPPED    ON sqldse.empped(ifis_index, ifis_fund, ifis_orgn, ifis_prgm)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.prd_end_date) FROM sqldse.empped AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/2016' AS DATETIME2);
                            SET @process_prd = CAST(SUBSTRING(CONVERT(VARCHAR, @last_last_activity_date,112),3,4) AS NUMERIC(4,0));
                            EXEC PrintNow @process_prd

                            EXEC PrintNow '-- Specify maximum ledger date to pull'
                            IF @StopDateString <> '' SET @StopDate = CAST(@StopDateString AS DATE);
                            IF @StopDate IS NULL SELECT @StopDate = CAST('01 '+ RIGHT(CONVERT(CHAR(11),GETDATE(),113),8) AS DATE)-1;
                            SET @stopdateval = 0;
                            EXEC PRINTNOW @stopdateval

                            EXEC PrintNow '-- Creating Import SQL'
                            WHILE @process_prd <= @stopdateval
                                BEGIN
                                    SET @SQL = 'INSERT INTO sqldse.empped (
                                                                emp_id,
                                                                [name],
                                                                home_dept,
                                                                retr_pln,
                                                                fica_elig,
                                                                leave_elig,
                                                                erng_end_dt,
                                                                pay_cycle,
                                                                key_ad_loc,
                                                                sub,
                                                                obj_code,
                                                                ifis_indx,
                                                                ifis_orgn,
                                                                ifis_fund,
                                                                ifis_prgm,
                                                                trans_end_dt,
                                                                adj_code,
                                                                dos,
                                                                title,
                                                                time_hours,
                                                                time_percent,
                                                                rate_type,
                                                                rate,
                                                                grs_amt,
                                                                earn_rel_cd,
                                                                earn_appt_tp,
                                                                bargaining_unit,
                                                                retr_mtch,
                                                                fica,
                                                                medicr,
                                                                health,
                                                                ann_health,
                                                                li,
                                                                ndi,
                                                                wc,
                                                                ui,
                                                                dental,
                                                                vision,
                                                                legal,
                                                                esp,
                                                                core_medical,
                                                                core_life,
                                                                dntl_alt,
                                                                visn_alt,
                                                                ucrs_plan7,
                                                                psbp_disab,
                                                                psbp_life_add,
                                                                psbp_brkr_adm,
                                                                psbp_wc,
                                                                ucrs_benefit_admin,
                                                                sr_mgmt_bene,
                                                                ucrp_supplement,
                                                                iap,';

                                        IF @last_last_activity_date>1606 SET @SQL = @SQL + '
                                                                tier_2016_suppl,
                                                                tier_2016_dc,';

                                        SET @SQL = @SQL + '
                                                                ben_expansion_1,
                                                                ben_expansion_2,
                                                                total_bene,
                                                                process_yrmo,
                                                                page_count,
                                                                line_no,
                                                                index_title,
                                                                fund_title,
                                                                refresh_date,
                                                                empped_id
                                                            )
                                                            SELECT  s.emp_id,
                                                                    s.[name],
                                                                    s.home_dept,
                                                                    s.retr_pln,
                                                                    s.fica_elig,
                                                                    s.leave_elig,
                                                                    s.erng_end_dt,
                                                                    s.pay_cycle,
                                                                    s.key_ad_loc,
                                                                    s.sub,
                                                                    s.obj_code,
                                                                    s.ifis_indx,
                                                                    s.ifis_orgn,
                                                                    s.ifis_fund,
                                                                    s.ifis_prgm,
                                                                    s.trans_end_dt,
                                                                    s.adj_code,
                                                                    s.dos,
                                                                    s.title,
                                                                    s.time_hours,
                                                                    s.time_percent,
                                                                    s.rate_type,
                                                                    s.rate,
                                                                    s.grs_amt,
                                                                    s.earn_rel_cd,
                                                                    s.earn_appt_tp,
                                                                    s.bargaining_unit,
                                                                    s.retr_mtch,
                                                                    s.fica,
                                                                    s.medicr,
                                                                    s.health,
                                                                    s.ann_health,
                                                                    s.li,
                                                                    s.ndi,
                                                                    s.wc,
                                                                    s.ui,
                                                                    s.dental,
                                                                    s.vision,
                                                                    s.legal,
                                                                    s.esp,
                                                                    s.core_medical,
                                                                    s.core_life,
                                                                    s.dntl_alt,
                                                                    s.visn_alt,
                                                                    s.ucrs_plan7,
                                                                    s.psbp_disab,
                                                                    s.psbp_life_add,
                                                                    s.psbp_brkr_adm,
                                                                    s.psbp_wc,
                                                                    s.ucrs_benefit_admin,
                                                                    s.sr_mgmt_bene,
                                                                    s.ucrp_supplement,
                                                                    s.iap,'

                                        IF @last_last_activity_date>1606 SET @SQL = @SQL + '
                                                                    s.tier_2016_suppl,
                                                                    s.tier_2016_dc,
                                                                    s.ben_expansion_1,
                                                                    s.ben_expansion_2,
                                                                    s.total_bene,
                                                                    s.process_yrmo,
                                                                    s.page_count,
                                                                    s.line_no,
                                                                    s.index_title,
                                                                    s.fund_title,
                                                                    s.refresh_date,
                                                                    s.empped_id
                                                            FROM    DW_DB..sqldse.empped AS s
                                                                    LEFT JOIN sqldse.empped AS d 
                                                                        ON  d.role_key = s.role_key 
                                                                            AND d.person_key = s.person_key 
                                                                            AND d.workgroup_key = s.workgroup_key 
                                                            WHERE   s.last_activity_date > @last_last_activity_date 
                                                                    AND s.last_activity_date <= @StopDate
                                                                    AND d.person_key IS NULL;';
                                END
                            
                            EXEC PrintNow '-- Inserting New Records'
                            EXEC (@SQL);

                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO