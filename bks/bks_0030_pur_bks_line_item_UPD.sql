/***************************************************************************************
Name      : BSO Financial Management Interface - finlink_ledger_query
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates Bookstore Purchase Tables
***************************************************************************************/
USE [dw_db];
GO

IF OBJECT_ID('pur.bks_0030_pur_bks_line_item_UPD','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.bks_0030_pur_bks_line_item_UPD
END
GO

CREATE PROCEDURE    pur.bks_0030_pur_bks_line_item_UPD
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY

                            UPDATE  pur.bks_line_item
                            SET     pur.bks_line_item.bks_transaction_id = s.bks_transaction_id
                            FROM    pur.bks_line_item AS d
                                    INNER JOIN  pur.bks_purchase AS s ON (d.purchase_invoice_number = s.purchase_invoice_number)
                            WHERE   d.bks_transaction_id IS NULL
                                    OR d.bks_transaction_id = '';

                            UPDATE  pur.bks_line_item
                            SET     pur.bks_line_item.unit_cost_val = (d.transaction_amount - d.discount_amount - d.freight_amount - d.duty_amount)/d.quantity_val
							FROM	pur.bks_line_item AS d
                            WHERE   d.quantity_val <> 0;
                            
                        END TRY
                        BEGIN CATCH
                            /* ERROR HANDLING NEEDED */
                        END CATCH
                    END;
GO