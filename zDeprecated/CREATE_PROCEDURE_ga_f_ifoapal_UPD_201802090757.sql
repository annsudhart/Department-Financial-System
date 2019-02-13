/***************************************************************************************
Name      : BSO Financial Management Interface - ec_trans_detail_UPD
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates update procedure for ga.f_ifoapal
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

IF OBJECT_ID('ga.f_ifoapal_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE ga.f_ifoapal_UPD
END

EXEC PrintNow '** CREATE [ga].[f_ifoapal_UPD]';
GO
CREATE PROCEDURE    [ga].[f_ifoapal_UPD]
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

                            EXEC PrintNow '-- Find ga.f_ifoapal'
                            IF OBJECT_ID('ga.f_ifoapal','U') IS NULL OR @ResetMe = 9999
                                BEGIN
                                    IF OBJECT_ID('ga.f_ifoapal','U') IS NOT NULL DROP TABLE ga.f_ifoapal
                                    EXEC PrintNow '-- ga.f_ifoapal'
                                    CREATE TABLE ga.f_ifoapal
                                    (
                                        if_id                           CHAR(12)                        NOT NULL,
                                        pi_account_index                CHAR(10)                        NOT NULL,
                                        pf_fund                         CHAR(6)                         NOT NULL,
                                        po_organization                 CHAR(6)                         NOT NULL,
                                        pa_account                      CHAR(6)                         NOT NULL,
                                        pp_program                      CHAR(6)                         NOT NULL,
                                        pl_location                     CHAR(6)                         NOT NULL,
                                        accounting_period               SMALLINT                        NOT NULL,
                                        refresh_date                    DATETIME2                       NOT NULL,
                                        full_accounting_period          INTEGER                         NOT NULL,
                                        end_full_accounting_period      INTEGER                         NOT NULL,
                                        ledger_date                     DATE                            NOT NULL,
                                        end_ledger_date                 DATE                            NOT NULL,
                                        account_type                    CHAR(2)                         NOT NULL,
                                        fund_type                       CHAR(2)                         NOT NULL,
                                        current_mo_budget_amount        NUMERIC(19,4)                   NOT NULL,
                                        current_mo_financial_amount     NUMERIC(19,4)                   NOT NULL,
                                        current_mo_encumbrance_amount   NUMERIC(19,4)                   NOT NULL,
                                        prior_yrs_budget_amount         NUMERIC(19,4)                   NOT NULL,
                                        prior_yrs_financial_amount      NUMERIC(19,4)                   NOT NULL,
                                        prior_mos_budget_amount         NUMERIC(19,4)                   NOT NULL,
                                        prior_mos_financial_amount      NUMERIC(19,4)                   NOT NULL,
                                        prior_mos_encumbrance_amount    NUMERIC(19,4)                   NOT NULL,
                                        rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
                                        version_number                  ROWVERSION
                                    )
                                    CREATE UNIQUE INDEX IDX008130419170000 ON ga.f_ifoapal(if_id,pa_account,pf_fund,pp_program,po_organization,full_accounting_period)
                                    CREATE INDEX INDX_ACCOUNT ON ga.f_ifoapal(pa_account,full_accounting_period)
                                    CREATE INDEX INDX_IFOAPAL_PERI1 ON ga.f_ifoapal(full_accounting_period,pi_account_index,pf_fund,po_organization,pa_account,pp_program,if_id)
                                    CREATE INDEX I_IFOAPAL_FUND ON ga.f_ifoapal(pf_fund,po_organization,pp_program,full_accounting_period)
                                    CREATE INDEX I_IFOAPAL_FUND_IDX ON ga.f_ifoapal(pf_fund,pi_account_index)
                                    CREATE INDEX I_IFOAPAL_IDX ON ga.f_ifoapal(pi_account_index,full_accounting_period)
                                    CREATE INDEX I_IFOAPAL_IDX_FUND ON ga.f_ifoapal(pi_account_index,pf_fund)
                                    CREATE INDEX I_IFOAPAL_ORGANIZ1 ON ga.f_ifoapal(po_organization,pa_account,pf_fund,pp_program,pl_location,pi_account_index,full_accounting_period)
                                    CREATE INDEX I_IFOAPAL_PO_PROG ON ga.f_ifoapal(po_organization,pp_program,pa_account,pf_fund,pi_account_index,if_id,full_accounting_period)
                                    CREATE INDEX PI_ACC_IND_PFF_PPP_POO_PAA_PLL ON ga.f_ifoapal(pi_account_index,pf_fund,pp_program,po_organization,pa_account,pl_location)
                                    CREATE UNIQUE INDEX SQL130510172409260 ON ga.f_ifoapal(if_id)
                                END

                            EXEC PrintNow '-- Identifying last update and applicable indices'
                            SELECT @last_last_activity_date = MAX(d.ledger_date) FROM ga.f_ifoapal AS d;
                            IF @last_last_activity_date IS NULL SET @last_last_activity_date = CAST('01/01/1900' AS DATETIME2);

                            EXEC PrintNow '-- Specify maximum ledger date to pull'
                            IF @StopDateString <> '' SET @StopDate = CAST(@StopDateString AS DATE);
                            IF @StopDate IS NULL SELECT @StopDate = MAX(d.ledger_date) FROM DW_DB..GA.F_IFOAPAL AS d;

                            EXEC PrintNow '-- Inserting New Records'
                            INSERT INTO ga.f_ifoapal (
										if_id,
                                        pi_account_index,
                                        pf_fund,
                                        po_organization,
                                        pa_account,
                                        pp_program,
                                        pl_location,
                                        accounting_period,
                                        refresh_date,
                                        full_accounting_period,
                                        end_full_accounting_period,
                                        ledger_date,
                                        end_ledger_date,
                                        account_type,
                                        fund_type,
                                        current_mo_budget_amount,
                                        current_mo_financial_amount,
                                        current_mo_encumbrance_amount,
                                        prior_yrs_budget_amount,
                                        prior_yrs_financial_amount,
                                        prior_mos_budget_amount,
                                        prior_mos_financial_amount,
                                        prior_mos_encumbrance_amount)
                                        SELECT  s.if_id,
                                                s.pi_account_index,
                                                s.pf_fund,
                                                s.po_organization,
                                                s.pa_account,
                                                s.pp_program,
                                                s.pl_location,
                                                s.accounting_period,
                                                s.refresh_date,
                                                s.full_accounting_period,
                                                s.end_full_accounting_period,
                                                s.ledger_date,
                                                s.end_ledger_date,
                                                s.account_type,
                                                s.fund_type,
                                                s.current_mo_budget_amount,
                                                s.current_mo_financial_amount,
                                                s.current_mo_encumbrance_amount,
                                                s.prior_yrs_budget_amount,
                                                s.prior_yrs_financial_amount,
                                                s.prior_mos_budget_amount,
                                                s.prior_mos_financial_amount,
                                                s.prior_mos_encumbrance_amount
                                        FROM    DW_DB..GA.F_IFOAPAL AS s
                                                LEFT JOIN DW_DB..SQLDSE.EXPANDORG AS oh 
                                                    ON s.po_organization = oh.child_org
                                        WHERE   s.ledger_date BETWEEN @last_last_activity_date AND @StopDate
                                                AND (s.pi_account_index LIKE 'MED%'
                                                    OR (oh.org IS NULL OR oh.org='JBAA03'));
                            
                        END TRY
                        BEGIN CATCH
                            EXEC dbo.PrintError
                            EXEC dbo.LogError
                        END CATCH
                    END;
GO