/*Organization Query*/

BEGIN TRY
    SELECT      o.unvrs_code, 
                o.coa_code, 
                o.orgn_code, 
                o.start_date, 
                o.end_date, 
                o.last_actvy_date, 
                o.status, 
                o.user_code,
                o.orgn_code_title,
                o.pred_orgn_code,
                o.data_entry_ind,
                o.dflt_fund_code,
                o.dflt_prog_code,
                o.dftl_actv_code,
                o.dflt_lctn_code,
                o.cmbnd_cntrl_ind,
                o.bdgt_cntrl_orgn,
                o.encmbr_plcy_ind,
                o.mgr_intrl_ref_id,
                o.encmbr_ldgr_ind,
                o.encmbr_ldgr_user,
                o.oper_ldgr_ind,
                o.oper_ldgr_user,
                o.dept_lvl_ind,
                o.refresh_date,
                o.orgn_table_id,
                h.[top],
                h.bottom,
                h.code_level,
                h.code_1,
                h.code_2,
                h.code_3,
                h.code_4,
                h.code_5,
                h.code_6,
                h.code_7,
                h.code_8,
                h.orgnhier_table_id
    FROM        coa_db.orgn_table AS o INNER JOIN
                coa_db.orgnhier_table AS h ON o.orgn_code = h.orgn_code
    WHERE       h.code_3 = 'JD1400';
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

/*dw_db.ga.f_ledger_detail_v Query*/
BEGIN TRY
    SELECT      d.accounting_period,
                d.account_index,
                d.fund,
                d.organization,
                d.account,
                d.program,
                d.location,
                d.rule_class_code,
                d.document_number,
                d.sequence_number,
                d.activity_date,
                d.document_reference_number,
                d.transaction_date,
                d.amount,
                d.description,
                d.debit_credit_indicator,
                d.debit_credit,
                d.encumbrance_number,
                d.encumbrance_action,
                d.encumbrance_type,
                d.vendor_code,
                d.item_number,
                d.encumbrance_item,
                d.encumbrance_sequence,
                d.budget_period,
                d.document_type_sequence_number,
                d.ledger_indicator,
                d.field_indicator,
                d.process_code,
                d.rule_sequence,
                d.ledger_activity_id,
                d.refresh_date,
                d.transaction_amount,
                d.ledger_transaction_id,
                d.ifoapal_id,
                d.operating_ledger_id,
                d.general_ledger_id
    FROM        ga.f_ledger_detail_v AS d INNER JOIN 
                coa_db.orgnhier_table AS h ON d.organization = h.orgn_code
    WHERE       h.code_3 = 'JD1400' AND
                d.accounting_period >= 201601
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

/*dw_db.ga.f_ifoapal*/
BEGIN TRY
    SELECT          a.if_id, 
                    a.pi_account_index, 
                    a.pf_fund, 
                    a.po_organization, 
                    a.pa_account, 
                    (CASE
                        WHEN SUBSTR(a.pa_account,1,1) = '5' THEN 'R' -- Revenue Accounts
                        WHEN SUBSTR(a.pa_account,1,1) = '6' THEN SUBSTR(a.pa_account,2,1)
                        WHEN SUBSTR(a.pa_account,1,1) = '7' THEN 'T' -- Transfer Accounts
                        WHEN SUBSTR(a.pa_account,1,1) = '8' THEN 'Y' -- Overhead Accounts
                    END) AS sub,
                    a.pp_program, 
                    a.pl_location, 
                    a.accounting_period, 
                    a.refresh_date, 
                    a.full_accounting_period, 
                    a.end_full_accounting_period, 
                    a.ledger_date, 
                    a.end_ledger_date, 
                    a.account_type, 
                    a.fund_type, 
                    a.current_mo_budget_amount, 
                    a.current_mo_financial_amount, 
                    a.current_mo_encumbrance_amount, 
                    a.prior_yrs_budget_amount, 
                    a.prior_yrs_financial_amount, 
                    a.prior_mos_budget_amount, 
                    a.prior_mos_financial_amount, 
                    a.prior_mos_encumbrance_amount,
                    (CASE
                        WHEN a.pi_account_index LIKE 'MCH%' THEN 0
                        WHEN a.pi_account_index LIKE 'MCL%' THEN 0
                        ELSE 1
                    END) AS reportable
    FROM            ga.f_ifoapal AS a
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

/*dw_db.ga.f_ledger_activity*/
BEGIN TRY
    SELECT          b.la_id, 
                    b.lt_id, 
                    b.if_id, 
                    b.ol_id, 
                    b.gl_id, 
                    b.la_ledger_indicator, 
                    b.la_field_indicator, 
                    b.la_amount, 
                    b.la_rule_sequence, 
                    b.la_process_code, 
                    b.refresh_date, 
                    b.accounting_period, 
                    b.la_debit_credit, 
                    b.full_accounting_period, 
                    (CASE
                        WHEN b.la_field_indicator = '01' THEN b.la_amount
                        WHEN b.la_field_indicator = '02' THEN b.la_amount
                        ELSE CAST(0.0 AS DECIMAL(19,4))
                    END) AS budget,
                    (CASE
                        WHEN b.la_field_indicator = '03' THEN b.la_amount
                        ELSE CAST(0.0 AS DECIMAL(19,4))
                    END) AS financial,
                    (CASE
                        WHEN b.la_field_indicator = '04' THEN b.la_amount
                        ELSE CAST(0.0 AS DECIMAL(19,4))
                    END) AS encumbrance,
                    (CASE
                        WHEN b.la_field_indicator = '01' THEN 'Budget'
                        WHEN b.la_field_indicator = '02' THEN 'Budget'
                        WHEN b.la_field_indicator = '03' THEN 'Financial'
                        WHEN b.la_field_indicator = '04' THEN 'Encumbrance'
                        ELSE 'Unknown'
                    END) AS field_indicator
    FROM            ga.f_ledger_activity AS b 
                    INNER JOIN ga.f_ledger_transaction AS c ON b.lt_id = c.lt_id AND b.full_accounting_period = c.full_accounting_period 
                    INNER JOIN ga.f_ifoapal AS a ON c.if_id = a.if_id AND c.full_accounting_period = a.full_accounting_period
    WHERE           a.full_accounting_period >= 201400 
                    AND ((a.pf_fund IN ('212F5A', '857B3A', '857BEA', '857G8A', '8593AA', '8593AA', '89332A', '8716EA', '858DAA', '18079B', '18079C', '88777A', '872B5A', '89576A', '05397A', '19900A') 
                        AND a.pi_account_index IN('MED7690','MED7792','MED4982','MED2303','MED6168','MED6169','MED7909','MED7991','MED7372','MED4652','MED6318','CFM2998','MED9904','CCT14MJ','IRAJAIN','MEDJAIN')) 
                    OR (a.pi_account_index IN('MEDMJS1','MEDMJS2','MEDMJSF','MEDMJEQ','MED6976','MEDACMJ','MEDD010','MEDDCMJ','MEDJAIN','MEDHTRR','MEDHTAC','MEDHTDI','ECEPMOZ','MEDMJS4','MEDMJS3', 'ECEPMOZ', 'MEDMCMJ', 'MEDMCMJ', 'ECEPMOZ', 'ECEPMOZ', 'VCOMJAI', 'VCOMJAI', 'ECEPMOZ', 'MED4MJ5', 'VCOMJAI', 'MED4MJ5', 'VCOMJAI', 'VCOMJAI', 'MED4MJ5', 'VCOMJAI', 'MED4MJ5', 'VCOMJAI', 'MED4MJ5', 'VCOMJAI', 'MED4MJ5', 'VCOMJAI', 'MED4MJ5')))
END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH