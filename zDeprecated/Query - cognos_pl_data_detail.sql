SELECT  TOP (100) PERCENT
        d.accounting_period, 
        d.base_group, 
        d.major_group_code, 
        d.division_id, 
        d.organization, 
        d.project_type_id, 
        d.index_code, 
        d.fund_category, 
        d.fund, 
        d.program, 
        d.account,
        d.rule_class_code, 
        d.mission_id, 
        d.pl_line_item_id, 
        d.pl_type_id, 
        d.pl_category_id, 
        ISNULL(c.cost_element_name, ISNULL(d.fund_category,'Uncategorized')) AS costelement,
        d.budget_value,
        d.financial_value, 
        d.transaction_value,
        CAST(d.transaction_value * ISNULL(m.multiplier_gaap,0) AS MONEY) AS amount,
        (d.transaction_value * ISNULL(m.multiplier_report,0)) AS report_value
FROM    cognos.pl_data_detail AS d
        LEFT OUTER JOIN cognos.cost_element AS c
        ON d.account = c.account 
        AND d.pl_line_item_id = c.pl_line_item_id 
        AND d.pl_type_id = c.pl_type_id 
        LEFT OUTER JOIN cognos.pl_type_multiplier AS m
        ON d.pl_type_id = m.pl_type_id
GROUP BY    d.accounting_period, 
            d.base_group, 
            d.major_group_code, 
            d.division_id, 
            d.organization, 
            d.project_type_id, 
            d.index_code, 
            d.fund_category, 
            d.fund, 
            d.program, 
            d.account, 
            d.rule_class_code, 
            d.mission_id, 
            d.pl_line_item_id, 
            d.pl_type_id, 
            d.pl_category_id, 
            ISNULL(c.cost_element_name, ISNULL(d.fund_category, 'Uncategorized'))
ORDER BY    d.accounting_period, 
            d.division_id, 
            d.organization, 
            d.mission_id, 
            d.fund_category, 
            d.fund, 
            d.index_code, 
            d.account, 
            d.rule_class_code,
            costelement