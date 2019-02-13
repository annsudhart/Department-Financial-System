USE [dw_db];
GO

CREATE SCHEMA dw_coa_db;
GO

CREATE VIEW dw_coa_db.orgnhier_table AS
SELECT	d.*
FROM	DW_DB..COA_DB.ORGNHIER_TABLE AS d
WHERE	d.code_3 IN ('JBAA03', 'JBAA19');
GO

CREATE VIEW dw_coa_db.orgn_table AS
SELECT d.*
FROM DW_DB..COA_DB.ORGN_TABLE AS d
	 INNER JOIN (SELECT	d.*
FROM	DW_DB..COA_DB.ORGNHIER_TABLE AS d
WHERE	d.code_3 IN ('JBAA03', 'JBAA19')) AS o ON o.orgn_code = d.orgn_code;
GO