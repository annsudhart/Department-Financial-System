USE [dw_db];
GO

IF OBJECT_ID ('coa_db.orgnhier_table_UPD','P') IS NOT NULL
	DROP PROCEDURE coa_db.orgnhier_table_UPD;
GO

CREATE PROCEDURE	coa_db.orgnhier_table_UPD
AS
BEGIN
	BEGIN TRY
		DELETE	
		FROM	coa_db.orgnhier_table;

		INSERT INTO	coa_db.orgnhier_table
					(
						orgn_code,
						[top],
						bottom,
						code_level,
						code_1,
						code_2,
						code_3,
						code_4,
						code_5,
						code_6,
						code_7,
						code_8,
						refresh_date,
						orgnhier_table_id
					)
		SELECT	d.orgn_code,
				d.[top],
				d.bottom,
				d.code_level,
				d.code_1,
				d.code_2,
				d.code_3,
				d.code_4,
				d.code_5,
				d.code_6,
				d.code_7,
				d.code_8,
				d.refresh_date,
				d.orgnhier_table_id
		FROM	DW_DB..COA_DB.ORGNHIER_TABLE AS d
		WHERE	d.code_3 IN('JBAA03');

	END TRY
	BEGIN CATCH
		EXEC dbo.PrintError
		EXEC dbo.LogError
	END CATCH
END;
GO