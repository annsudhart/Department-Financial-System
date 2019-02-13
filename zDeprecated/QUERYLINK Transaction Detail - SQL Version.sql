/* QUERY FOR PULLING TRANSACTION DETAILS */
SELECT  ga.f_ifoapal.full_accounting_period AS 'Full Accounting Period',
        ga.f_accounting_period.calENDar_year_month AS 'CalENDar Year and Month',
        SUBSTRINGING(CHAR(ga.f_accounting_period.full_accounting_period),1,4) AS 'Fiscal Year',
        ga.f_ifoapal.pi_account_index AS 'Index',
        coa_db.indx.[status] AS 'Current Index Status',
        ga.f_ifoapal.pf_fund AS 'Fund',
        ga.f_ifoapal.po_organization AS 'Organization',
        ga.f_ifoapal.pa_account AS 'Account',
        CASE    WHEN  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 ) = '5' THEN '5x'
                WHEN  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 ) = '7' THEN '7x'
                ELSE  SUBSTRING( ga.f_ifoapal.pa_account, 1, 2 ) 
                END
        AS 'Sub Account',
        ga.f_ifoapal.pp_program AS 'Program',
        ga.f_period_index.pi_title AS 'Index Title',
        ga.f_period_fund.pf_title AS 'Fund Title',
        ga.f_period_organization.po_title AS 'Organization Title',
        ga.f_period_account.pa_title AS 'Account Title',
        qlink_db.subaccount_title.subaccount_title AS 'Subaccount Title',
        ga.f_period_program.pp_title AS 'Program Title',
        ga.f_ifoapal.account_type AS 'Account Type',
        ga.f_ifoapal.fund_type AS 'Fund Type',
        coa_db.fund.fund_group_code AS 'Fund Group Code',
        coalesce(CASE   WHEN    ga.f_ledger_activity.la_field_indicator = '02'
                                AND SUBSTRING(ga.f_ifoapal.pa_account,1,1) = '5' THEN ( ga.f_ledger_activity.la_amount * -1 )
            WHEN ga.f_ledger_activity.la_field_indicator = '02'
            and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
        END , 0.00 ) AS 'Budget',
  coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) AS 'Financial',
  ( coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '02'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '02'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) -
    coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) ) AS 'Balance w/o Encumbrance',
  coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '04'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '04'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) AS 'Encumbrance',
  ( coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '02'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '02'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) -
    coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '03'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) -
    coalesce( cASe 
    WHEN ga.f_ledger_activity.la_field_indicator = '04'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  = '5' THEN ( ga.f_ledger_activity.la_amount *
    -1 )
    WHEN ga.f_ledger_activity.la_field_indicator = '04'
    and  SUBSTRING( ga.f_ifoapal.pa_account, 1, 1 )  <> '5' THEN ga.f_ledger_activity.la_amount
  END , 0.00 ) ) AS 'Balance',
  ga.f_ledger_activity.la_field_indicator AS 'Ledger Type',
   SUBSTRING( replace( char( ga.f_ledger_transaction.lt_transaction_date, iso),'-','/'), 1, 10)  AS 'Transaction Date',
  ga.f_ledger_transaction.dt_sequence_number AS 'Transaction Type',
  ga.f_document_type.dt_title AS 'Transaction Type Description',
  ga.f_ledger_transaction.LT_ACTIVITY_DATE AS 'Activity Date',
  ga.f_ledger_transaction.lt_document_number AS 'Document Number',
  ga.f_ledger_transaction.lt_document_reference_number AS 'Document Reference Number',
  ga.f_ledger_transaction.lt_sequence_number AS 'Sequence Number',
  ga.f_ledger_transaction.lt_description AS 'Transaction Description',
  ga.f_ledger_transaction.lt_rule_clASs_code AS 'Rule ClASs Code',
  qlink_db.rule_clASs_desc.rule_clASs_desc AS 'Rule ClASs Description',
  cASe 
    WHEN gp.ssn_xref.xref_type = '1' THEN 'Individual Taxpayer ID'
    WHEN gp.ssn_xref.xref_type = '2' THEN 'FEIN'
    WHEN gp.ssn_xref.xref_type = '3' THEN 'Financial Id Number'
    WHEN gp.ssn_xref.xref_type = '4' THEN 'Employee Number'
  END  AS 'VENDor Code Type',
  gp.ssn_xref.ifis_pid AS 'VENDor Code'
from
  ga.f_ifoapal
  inner join ga.f_accounting_period
    on ga.f_ifoapal.full_accounting_period = ga.f_accounting_period.full_accounting_period 
  inner join ga.f_ledger_activity
    on ga.f_ifoapal.if_id = ga.f_ledger_activity.if_id 
    and ga.f_ifoapal.full_accounting_period = ga.f_ledger_activity.full_accounting_period 
  inner join ga.f_ledger_transaction
    on ga.f_ledger_transaction.lt_id = ga.f_ledger_activity.lt_id 
    and ga.f_ledger_transaction.full_accounting_period = ga.f_ledger_activity.full_accounting_period 
  inner join ga.f_document_type
    on ga.f_ledger_transaction.dt_sequence_number = ga.f_document_type.dt_sequence_number 
  left outer join ga.f_period_index
    on ga.f_ifoapal.full_accounting_period = ga.f_period_index.full_accounting_period 
    and ga.f_ifoapal.pi_account_index = ga.f_period_index.pi_account_index 
  left outer join ga.f_period_fund
    on ga.f_ifoapal.full_accounting_period = ga.f_period_fund.full_accounting_period 
    and ga.f_ifoapal.pf_fund = ga.f_period_fund.pf_fund 
  left outer join ga.f_period_organization
    on ga.f_ifoapal.full_accounting_period = ga.f_period_organization.full_accounting_period 
    and ga.f_ifoapal.po_organization = ga.f_period_organization.po_organization 
  left outer join ga.f_period_account
    on ga.f_ifoapal.full_accounting_period = ga.f_period_account.full_accounting_period 
    and ga.f_ifoapal.pa_account = ga.f_period_account.pa_account 
  left outer join ga.f_period_program
    on ga.f_ifoapal.full_accounting_period = ga.f_period_program.full_accounting_period 
    and ga.f_ifoapal.pp_program = ga.f_period_program.pp_program 
  left outer join gp.ssn_xref
    on  SUBSTRING( ga.f_ledger_transaction.v_vENDor_code, 2, 9 )  = gp.ssn_xref.ifis_pid 
  inner join qlink_db.rule_clASs_desc
    on qlink_db.rule_clASs_desc.rule_clASs_code = ga.f_ledger_transaction.lt_rule_clASs_code 
  inner join qlink_db.subaccount_title
    on  SUBSTRING( ga.f_ifoapal.pa_account, 1, 2 )  = qlink_db.subaccount_title.subaccount 
  inner join coa_db.fund
    on ga.f_ifoapal.pf_fund = coa_db.fund.fund 
    and coa_db.fund.most_recent_flag = 'Y' 
  left outer join coa_db.indx
    on ga.f_ifoapal.pi_account_index = coa_db.indx.indx 
    and coa_db.indx.fund = coa_db.fund.fund 
    and coa_db.indx.most_recent_flag = 'Y'  
where
  ga.f_ifoapal.full_accounting_period in ( 201902, 201901, 201900, 201814, 201812, 201811, 201810, 201809, 201808, 201807, 201806, 201805, 201804, 201803, 201802, 201801, 201800, 201714, 201712, 201711, 201710, 201709, 201708, 201707, 201706, 201705, 201704, 201703, 201702, 201701, 201700, 201614, 201612, 201611, 201610, 201609, 201608, 201607, 201606 ) 
    and ga.f_ifoapal.pi_account_index in ( 'MEDD048', 'MEDDCNB', 'MEDACNB', 'MESHB1', 'MEDD068' ) 
    and ga.f_ledger_activity.la_ledger_indicator = 'O'
    and coa_db.fund.most_recent_flag = 'Y'