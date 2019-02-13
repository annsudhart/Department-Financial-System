USE [dw_db]
GO

SELECT  c.organization, 
        c.organization_name, 
        c.home_department_code, 
        c.department_name, 
        c.CARD_TYPE_DESCRIPTION, 
        c.card_key, 
        c.employee_id, 
        c.card_name, 
        c.name_comp, 
        c.ecch_orig_training_date, 
        c.ecch_training_date, 
        c.emp_status_cd, 
        c.date_issued, 
        c.status, 
        c.expiration_month, 
        c.expiration_year, 
        c.cancellation_date, 
        c.cancelled_by, 
        p.transaction_id, 
        p.transaction_date, 
        p.posted_date, 
        p.reference_number, 
        p.point_of_sales_code, 
        p.vendor_mcc, 
        i.vendor_id,
        p.vendor_tax_id, 
        p.vendor_name, 
        p.vendor_city, 
        p.vendor_state, 
        p.vendor_zip, 
        p.vendor_country,
        i.vendor_order_number,
        i.order_date,
        i.destination_zip,
        i.destination_country,
        i.line_item_sequence,
        i.line_item_sequence,
        i.purchase_invoice_number,
        i.commodity_code,
        i.supply_type,
        i.line_item_description,
        (CASE WHEN CAST(i.quantity AS INT) = 0 THEN 1 ELSE ISNULL(i.quantity,1) END) AS quantity,
        ISNULL(i.unit_of_measure,'EA') AS unit_of_measure,
        CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)) AS unit_cost,
        CAST(-1 * i.discount_amount AS DECIMAL(19,4)) AS discount_amount,
        CAST(ISNULL(i.freight_amount,0) AS DECIMAL(19,4)) AS freight_amount,
        CAST(ISNULL(i.duty_amount,0) AS DECIMAL(19,4)) AS duty_amount,
        CAST(CAST(ISNULL(i.quantity,1) AS DECIMAL(19,4))*CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)) AS DECIMAL(19,4)) AS direct_amount,
        CAST((CAST(ISNULL(i.quantity,1) AS DECIMAL(19,4))*CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)))+(-1 * i.discount_amount)+ISNULL(i.freight_amount,0)+ISNULL(i.duty_amount,0) AS DECIMAL(19,4)) AS total_amount,
        CASE WHEN p.calculated_use_tax_amount > p.posted_use_tax_amount THEN p.calculated_use_tax_amount ELSE p.posted_use_tax_amount END AS use_tax,
        CAST(CASE WHEN t.total_amount = 0 THEN (CASE WHEN CAST(i.quantity AS INT) = 0 THEN 1 ELSE ISNULL(i.quantity,1) END)/t.quantity ELSE CAST((CAST(ISNULL(i.quantity,1) AS DECIMAL(19,4))*CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)))+(-1 * i.discount_amount)+ISNULL(i.freight_amount,0)+ISNULL(i.duty_amount,0) AS DECIMAL(19,4))/t.total_amount END AS DECIMAL(19,4)) AS line_item_split,
        p.calculated_use_tax_amount,
        p.posted_use_tax_amount,
        CAST(p.transaction_amount AS DECIMAL(19,4)) AS total_transaction_amount,
        t.quantity AS transaction_quantity,
        t.direct_amount AS transaction_direct_amount,
        t.total_amount AS transaction_total_amount
FROM    dbo.ec_purchase_line_item_SUM AS t 
        RIGHT OUTER JOIN pur.ec_purchase AS p ON t.transaction_id = p.transaction_id 
        LEFT OUTER JOIN pur.ec_line_item AS i ON p.transaction_id = i.transaction_id 
        LEFT OUTER JOIN pur.ec_cardholder AS c ON p.workgroup_key = c.workgroup_key AND p.card_key = c.card_key