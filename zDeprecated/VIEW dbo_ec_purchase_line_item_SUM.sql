USE [dw_db]
GO

SELECT  p.transaction_id,
        SUM(CASE WHEN CAST(i.quantity AS INT) = 0 THEN 1 ELSE ISNULL(i.quantity,1) END) AS quantity,
        SUM(CAST((CASE WHEN CAST(i.quantity AS INT) = 0 THEN 1 ELSE ISNULL(i.quantity,1) END)*CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)) AS DECIMAL(19,4))) AS direct_amount,
        SUM(CAST(((CASE WHEN CAST(i.quantity AS INT) = 0 THEN 1 ELSE ISNULL(i.quantity,1) END)*CAST(ISNULL(i.unit_cost,0) AS DECIMAL(19,4)))+(-1 * ISNULL(i.discount_amount,0))+ISNULL(i.freight_amount,0)+ISNULL(i.duty_amount,0) AS DECIMAL(19,4))) AS total_amount
FROM    pur.ec_line_item AS i 
        RIGHT OUTER JOIN    pur.ec_purchase AS p ON i.transaction_id = p.transaction_id 
        LEFT OUTER JOIN     pur.ec_cardholder AS c ON p.workgroup_key = c.workgroup_key AND p.card_key = c.card_key
GROUP BY p.transaction_id