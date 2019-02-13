USE [dw_db]
GO

/****** Object:  StoredProcedure [pur].[ec_UPD]    Script Date: 07/18/2018 10:26:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dw_coa_db.searchFundIndex','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dw_coa_db.searchFundIndex
END
GO

-- =============================================
-- Author:		Vanderbilt, Matthew C.
-- Create date: 25 July 2018
-- Description:	dw_coa_db.searchFundIndex
-- =============================================
CREATE PROCEDURE    dw_coa_db.searchFundIndex
                    (
                        @searchString NVARCHAR(60) = ''
                    )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRY
        SET @searchString = '%' + UPPER(@searchString) + '%';

        SELECT  f.unvrs_code,
                f.coa_code,
                f.fund_code,
                f.fund_title,
                f.fdrl_flow_thru_ind,
                f.rvnu_acct,
                f.acrl_acct,
                f.cptlzn_acct_code,
                f.grant_cntrct_nmbr,
                f.pms_code,
                f.grant_cost_share_code,
                f.fund_type_code,
                f.base_ucsd_award_number,
                f.agency_code,
                f.agency_name,
                f.manager_employee_id,
                f.manager_name,
                f.investigator_employee_id,
                f.investigator_name,
                f.co_investigator_id,
                f.co_investigator_name,
                f.sponsor_award_number,
                f.grant_contract_number, 
                i.index_code,
                i.index_code_title,
                i.orgn_code,
                i.acct_code,
                i.prog_code
        FROM    (
                    SELECT  DISTINCT
                            f.unvrs_code,
                            f.coa_code,
                            f.fund_code,
                            f.fund_title,
                            f.fdrl_flow_thru_ind,
                            f.rvnu_acct,
                            f.acrl_acct,
                            f.cptlzn_acct_code,
                            f.grant_cntrct_nmbr,
                            f.pms_code,
                            f.grant_cost_share_code,
                            f.fund_type_code,
                            f.base_ucsd_award_number,
                            f.agency_code,
                            f.agency_name,
                            f.manager_employee_id,
                            f.manager_name,
                            f.investigator_employee_id,
                            f.investigator_name,
                            f.co_investigator_id,
                            f.co_investigator_name,
                            f.sponsor_award_number,
                            f.grant_contract_number,
                            i.index_code,
                            i.index_code_title,
                            i.orgn_code,
                            i.acct_code,
                            i.prog_code
                    FROM    DW_DB..COA_DB.INDEX_TABLE AS i
                            LEFT OUTER JOIN DW_DB..COA_DB.FUND_TABLE AS f ON i.fund_code = f.fund_code
                    WHERE   i.index_code_title LIKE @searchString
                ) AS i
                RIGHT OUTER JOIN
                (
                    SELECT  DISTINCT
                            f.unvrs_code,
                            f.coa_code,
                            f.fund_code,
                            f.fund_title,
                            f.fdrl_flow_thru_ind,
                            f.rvnu_acct,
                            f.acrl_acct,
                            f.cptlzn_acct_code,
                            f.grant_cntrct_nmbr,
                            f.pms_code,
                            f.grant_cost_share_code,
                            f.fund_type_code,
                            f.base_ucsd_award_number,
                            f.agency_code,
                            f.agency_name,
                            f.manager_employee_id,
                            f.manager_name,
                            f.investigator_employee_id,
                            f.investigator_name,
                            f.co_investigator_id,
                            f.co_investigator_name,
                            f.sponsor_award_number,
                            f.grant_contract_number
                    FROM    DW_DB..COA_DB.FUND_TABLE AS f
                    WHERE   f.fund_title LIKE @searchString
                            OR f.agency_name LIKE @searchString
                            OR f.manager_name LIKE @searchString
                            OR f.investigator_name LIKE @searchString
                            OR f.co_investigator_name LIKE @searchString
                ) AS f
                ON i.fund_code = f.fund_code
        GROUP BY    f.unvrs_code,
                    f.coa_code,
                    f.fund_code,
                    f.fund_title,
                    f.fdrl_flow_thru_ind,
                    f.rvnu_acct,
                    f.acrl_acct,
                    f.cptlzn_acct_code,
                    f.grant_cntrct_nmbr,
                    f.pms_code,
                    f.grant_cost_share_code,
                    f.fund_type_code,
                    f.base_ucsd_award_number,
                    f.agency_code,
                    f.agency_name,
                    f.manager_employee_id,
                    f.manager_name,
                    f.investigator_employee_id,
                    f.investigator_name,
                    f.co_investigator_id,
                    f.co_investigator_name,
                    f.sponsor_award_number,
                    f.grant_contract_number, 
                    i.index_code,
                    i.index_code_title,
                    i.orgn_code,
                    i.acct_code,
                    i.prog_code
        ORDER BY    f.fund_code,
                    i.index_code;

	END TRY
    BEGIN CATCH
        EXEC dbo.PrintError
        EXEC dbo.LogError
    END CATCH
END
GO