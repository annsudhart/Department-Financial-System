USE [dw_db];
GO

SELECT OBJECT_NAME([database_id]), OBJECT_NAME([object_id]),*
FROM sys.dm_exec_procedure_stats;