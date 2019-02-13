SELECT  a.execution_count ,
    OBJECT_NAME(objectid) Name,
    query_text = SUBSTRING( 
    b.text, 
    a.statement_start_offset/2, 
    (	CASE WHEN a.statement_end_offset = -1 
    	THEN len(convert(nvarchar(max), b.text)) * 2 
    	ELSE a.statement_end_offset 
    	END - a.statement_start_offset)/2
    ) ,
    b.dbid ,
    dbname = db_name(b.dbid) ,
    b.objectid ,
    a.creation_time,
    a.last_execution_time,
    a.*
FROM    		sys.dm_exec_query_stats a 
CROSS APPLY 	sys.dm_exec_sql_text(a.sql_handle) as b
ORDER BY a.last_execution_time DESC
