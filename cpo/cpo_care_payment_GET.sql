/***************************************************************************************
Name      : Medicine Finance
License   : Copyright (C) 2018 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- 
***************************************************************************************/
USE [dw_db];
GO

IF OBJECT_ID('cpo.care_payment_GET','P') IS NOT NULL
BEGIN
    DROP PROCEDURE cpo.care_payment_GET
END
GO

CREATE PROCEDURE    cpo.care_payment_GET
                    @flagDataSumType INT = 0
                    AS
                    BEGIN
                        BEGIN TRY

                            IF  @flagDataSumType = 0
                                BEGIN
                                       SELECT   d.care_payment_id, 
                                                d.post_period, 
                                                d.effective_period, 
                                                d.bill_prov_id, 
                                                p1.provider_name AS bill_prov_name, 
                                                d.bill_prov_type_id, 
                                                pt1.provider_type_name AS bill_prov_type_name, 
                                                pt1.provider_type_group_id AS bill_prov_type_group_id, 
                                                ptg1.provider_type_group_name AS bill_prov_type_group_name, 
                                                d.bill_prov_specialty_id, 
                                                s1.specialty_name AS bill_prov_specialty_name, 
                                                d.serv_prov_id, 
                                                p2.provider_name AS serv_prov_name, 
                                                d.serv_prov_type_id, 
                                                pt2.provider_type_name AS serv_prov_type_name, 
                                                pt2.provider_type_group_id AS serv_prov_type_group_id, 
                                                ptg2.provider_type_group_name AS serv_prov_type_group_name, 
                                                d.bill_area_id, 
                                                ba.bill_area_name, 
                                                d.index_code, 
                                                d.pos_type_c, 
                                                d.pos_id, 
                                                d.bill_area_speciality_id, 
                                                s2.specialty_name AS bill_area_specialty_name, 
                                                d.div_id, 
                                                cpo.div.div_name, 
                                                d.subdiv_id, 
                                                sdiv.subdiv_name, 
                                                d.ser_median, 
                                                d.ba_median, 
                                                d.employee_id, 
                                                e.employee_name, 
                                                d.asa, 
                                                d.wrvu, 
                                                d.derived_wrvu, 
                                                d.asa_payment, 
                                                d.wrvu_payment, 
                                                d.logic, 
                                                d.rate_specialty_id, 
                                                s3.specialty_name AS rate_specialty_name, 
                                                d.rate_used, 
                                                d.care_payment, 
                                                d.asa_care_payment, 
                                                d.wrvu_care_payment, 
                                                d.derived_care_payment, 
                                                d.non_wrvu_care_payment
                                        FROM    cpo.bill_area AS ba 
                                                INNER JOIN  cpo.care_payment AS d ON ba.bill_area_id = d.bill_area_id 
                                                INNER JOIN  cpo.div ON d.div_id = cpo.div.div_id 
                                                INNER JOIN  cpo.employee AS e ON d.employee_id = e.employee_id 
                                                INNER JOIN  cpo.provider AS p1 ON d.bill_prov_id = p1.provider_id 
                                                INNER JOIN  cpo.provider_type AS pt1 ON d.bill_prov_type_id = pt1.provider_type_id 
                                                INNER JOIN  cpo.specialty AS s1 ON d.bill_prov_specialty_id = s1.specialty_id 
                                                INNER JOIN  cpo.subdiv AS sdiv ON d.subdiv_id = sdiv.subdiv_id 
                                                INNER JOIN  cpo.provider_type_group AS ptg1 ON pt1.provider_type_group_id = ptg1.provider_type_group_id 
                                                INNER JOIN  cpo.provider AS p2 ON d.serv_prov_id = p2.provider_id 
                                                INNER JOIN  cpo.specialty AS s2 ON d.bill_area_speciality_id = s2.specialty_id 
                                                INNER JOIN  cpo.specialty AS s3 ON d.rate_specialty_id = s3.specialty_id 
                                                INNER JOIN  cpo.provider_type AS pt2 ON d.serv_prov_type_id = pt2.provider_type_id 
                                                INNER JOIN  cpo.provider_type_group AS ptg2 ON pt2.provider_type_group_id = ptg2.provider_type_group_id
                                END

                                IF  @flagDataSumType = 1
                                    BEGIN
                                        SELECT  d.post_period, 
                                                cpo.div.div_name, 
                                                cpo.subdiv.subdiv_name,
                                                SUM(d.wrvu) AS total_wrvu, 
                                                SUM(d.care_payment) AS total_care_payment
                                        FROM    cpo.care_payment AS d 
                                                INNER JOIN  cpo.div ON d.div_id = cpo.div.div_id
                                                INNER JOIN  cpo.subdiv ON d.subdiv_id = cpo.subdiv.subdiv_id
                                        GROUP BY d.post_period, cpo.div.div_name, cpo.subdiv.subdiv_name
                                        ORDER BY d.post_period
                                    END

                            
                        END TRY
                        BEGIN CATCH
                            /* ERROR HANDLING NEEDED */
                        END CATCH
                    END;
GO