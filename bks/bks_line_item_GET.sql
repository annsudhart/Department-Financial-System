/***************************************************************************************
Name      : Medicine Finance - bks_line_item_GET
License   : Copyright (C) 2018 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Returns Records from pur.bks_line_item
***************************************************************************************/
USE [dw_db];
GO

IF OBJECT_ID('pur.bks_line_item_GET','P') IS NOT NULL
BEGIN
    DROP PROCEDURE pur.bks_line_item_GET
END
GO

CREATE PROCEDURE    pur.bks_line_item_GET
                    @ResetMe INT = 0
                    AS
                    BEGIN
                        BEGIN TRY

                            SELECT  bksl.bks_transaction_id,
                                    bksl.bks_line_item_id,
                                    bksl.modification_indicator,
                                    bksl.product_code,
                                    bksl.line_item_description,
                                    bksl.serial_number,
                                    bksl.quantity_val,
                                    bksl.unit_of_measure,
                                    bksl.unit_cost_val,
                                    bksl.discount_amount,
                                    bksl.freight_amount,
                                    bksl.duty_amount,
                                    bksl.index_code,
                                    bksl.fund_code,
                                    bksl.organization_code,
                                    bksl.program_code,
                                    bksl.account_code,
                                    bksl.location_code,
                                    bksl.transaction_amount,
                                    bksl.transaction_description,
                                    bksl.equipment_flag,
                                    bksl.use_tax_flag,
                                    bksl.use_tax_amount,
                                    bksl.comment
                            FROM    pur.bks_line_item AS bksl
                            
                        END TRY
                        BEGIN CATCH
                            /* ERROR HANDLING NEEDED */
                        END CATCH
                    END;
GO