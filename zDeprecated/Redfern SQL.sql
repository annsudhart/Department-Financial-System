/* DANIEL REDFERN CODE - SQL ADJUSTED */
SELECT  b.full_accounting_period AS AccountingPeriod,
        a.pi_account_index AS IndexNum,
        a.po_organization AS Organization,
        a.pf_fund AS Fund,
        a.PP_PROGRAM AS Program,
        a.pa_account AS Account,
        CASE
            WHEN SUBSTRING(a.PA_ACCOUNT,1,1) = '5' THEN 'R' -- Revenue accounts
            WHEN SUBSTRING(a.PA_ACCOUNT,1,1) = '6' THEN SUBSTRING(a.PA_ACCOUNT,2,1)
            WHEN SUBSTRING(a.PA_ACCOUNT,1,1) = '7' THEN 'T' -- Transfer accounts      
            WHEN SUBSTRING(a.PA_ACCOUNT,1,1) = '8' THEN 'Y' -- Overhead accounts
            ELSE 'U' -- Unknown
        END AS Sub,
        c.lt_document_number AS DocNum,
        c.lt_document_reference_number AS DocRefNum,
        c.lt_description AS TransDescription,
        c.LT_RULE_CLASS_CODE AS RuleClass,
        CASE 
            WHEN b.LA_FIELD_INDICATOR = '01' THEN b.LA_AMOUNT
            WHEN b.LA_FIELD_INDICATOR = '02' THEN b.LA_AMOUNT
            ELSE 0.0
        END AS Budget,
        CASE 
            WHEN b.LA_FIELD_INDICATOR = '03' THEN b.LA_AMOUNT
            ELSE 0.0
        END AS Financial,
        CASE 
            WHEN b.LA_FIELD_INDICATOR = '04' THEN b.LA_AMOUNT
            ELSE 0.0
        END AS Encumbrance,
        CASE 
            WHEN b.LA_FIELD_INDICATOR = '01' THEN 'Budget'
            WHEN b.LA_FIELD_INDICATOR = '02' THEN 'Budget'
            WHEN b.LA_FIELD_INDICATOR = '03' THEN 'Financial'
            WHEN b.LA_FIELD_INDICATOR = '04' THEN 'Encumbrance'
            ELSE 'Unknown'
        END AS Field_Indicator,
        b.la_ledger_indicator AS LedgerIndicator,
        DATE(c.LT_TRANSACTION_DATE) as TransDate,
        DATE() AS create_ts,
        c.REFRESH_DATE AS update_ts 
FROM    GA.F_IFOAPAL AS a, 
        GA.F_LEDGER_ACTIVITY AS b, 
        GA.F_LEDGER_TRANSACTION AS c, 
        GA.F_ACCOUNTING_PERIOD AS d, 
        SQLDSE.EXPANDORG AS oh 
WHERE   a.if_id = b.if_id 
        AND b.lt_id = c.lt_id 
        AND a.full_accounting_period = d.full_accounting_period 
        AND la_ledger_indicator = 'O' 
        AND pa_account <> '400000' 
        AND PO_ORGANIZATION = oh.CHILD_ORG 
        AND oh.ORG ='JAAAAA' 
        AND (a.pi_account_index NOT LIKE 'MCH%' 
            AND a.pi_account_index NOT LIKE 'MCL%') 
        AND (d.AC_STATUS IN ('F','O') OR RIGHT(CAST(d.FULL_ACCOUNTING_PERIOD AS CHAR(6)),2) = '14');
