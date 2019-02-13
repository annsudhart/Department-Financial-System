USE [dw_db]
GO

SELECT	i.pi_account_index,
		coaIndex.indx_title,
		i.pf_fund,
		coaFund.fund_title,
		i.fund_type,
		coaFundType.fund_type_title,
		i.po_organization,
		coaOrganization.organization_title,
		coa_db_orgnhier_table.code_3,
		coa_db_orgnhier_table.code_4,
		coaOrganizationC4.organization_title AS code_4_title,
		i.pa_account,
		coaAccount.account_title,
		i.account_type,
		coaAccountType.acct_type_title,
		i.pp_program,
		coaProgram.program_title,
		i.pl_location,
		i.refresh_date,
		i.full_accounting_period,
		i.end_full_accounting_period,
		i.current_mo_budget_amount,
		i.current_mo_financial_amount,
		i.current_mo_encumbrance_amount,
		i.prior_yrs_budget_amount,
		i.prior_yrs_financial_amount,
		i.prior_mos_budget_amount,
		i.prior_mos_financial_amount,
		i.prior_mos_encumbrance_amount
FROM	DW_DB..GA.F_IFOAPAL AS i
		LEFT JOIN (SELECT fund_type_code, fund_type_title FROM DW_DB..COA_DB.FUNDTYPE_TABLE) AS coaFundType ON i.fund_type = coaFundType.fund_type_code
		LEFT JOIN (SELECT acct_type_code, acct_type_title FROM DW_DB..COA_DB.ACCTTYPE_TABLE) AS coaAccountType ON i.account_type = coaAccountType.acct_type_code
		LEFT JOIN (SELECT fund, fund_title, most_recent_flag FROM DW_DB..COA_DB.FUND WHERE most_recent_flag='Y') AS coaFund ON i.pf_fund = coaFund.fund
		LEFT JOIN (SELECT account, account_title, most_recent_flag FROM DW_DB..COA_DB.ACCOUNT WHERE most_recent_flag='Y') AS coaAccount ON i.pa_account = coaAccount.account
		LEFT JOIN (SELECT indx, indx_title, most_recent_flag FROM DW_DB..COA_DB.INDX WHERE most_recent_flag='Y') AS coaIndex ON i.pi_account_index = coaIndex.indx
		LEFT JOIN DW_DB..COA_DB.ORGNHIER_TABLE AS coa_db_orgnhier_table ON i.po_organization = coa_db_orgnhier_table.orgn_code
		LEFT JOIN (SELECT organization, organization_title FROM DW_DB..COA_DB.ORGANIZATION WHERE most_recent_flag='Y') AS coaOrganization ON i.po_organization = coaOrganization.organization
		LEFT JOIN (SELECT organization, organization_title FROM DW_DB..COA_DB.ORGANIZATION WHERE most_recent_flag='Y') AS coaOrganizationC4 ON coa_db_orgnhier_table.code_4 = coaOrganizationC4.organization
		LEFT JOIN (SELECT program, program_title, most_recent_flag FROM DW_DB..COA_DB.PROGRAM) AS coaProgram ON i.pp_program = coaProgram.program
WHERE	i.full_accounting_period=201901
		AND coa_db_orgnhier_table.code_3 = 'JBAA03'

