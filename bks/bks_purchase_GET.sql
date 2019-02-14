/***************************************************************************************
Name      : Medicine Finance - bks_purchase_GET
License   : Copyright (C) 2018 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Returns Records from pur.bks_purchase
***************************************************************************************/
USE [dw_db];
GO

IF OBJECT_ID('pur.bks_purchase_GET','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.bks_purchase_GET
END
GO

CREATE PROCEDURE    pur.bks_purchase_GET
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY

                            SELECT  bksp.bks_transaction_id,
                                    bksp.modification_indicator,
                                    bksp.transaction_date,
                                    bksp.purchase_invoice_number,
                                    bksp.discount_amount,
                                    bksp.freight_amount,
                                    bksp.duty_amount,
                                    bksp.order_date,
                                    bksp.transaction_amount,
                                    bksp.use_tax_flag,
                                    bksp.use_tax_amount,
                                    bksp.employee_id,
                                    bksp.employee_name,
                                    bksp.document_number,
                                    bksp.comment
                            FROM    pur.bks_purchase AS bksp
                            
                        END TRY
                        BEGIN CATCH
                            /* ERROR HANDLING NEEDED */
                        END CATCH
                    END;
GO