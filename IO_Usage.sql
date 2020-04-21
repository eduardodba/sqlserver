--SELECT SUM(pending_disk_io_count) AS [Number of pending I/Os] FROM sys.dm_os_schedulers 
--SELECT *  FROM sys.dm_io_pending_io_requests



--TEMPO DE LEITURA, ESCRITA E TOTAL POR DATAFILE
SELECT DB_NAME(database_id) AS [Database],
	[file_id], 
	[io_stall_read_ms] AS [Tempo ms para Leitura],		
	[io_stall_write_ms] AS [Tempo ms para Escrita],	
	[io_stall] AS [Tempo ms Total]				
FROM sys.dm_io_virtual_file_stats(NULL,NULL) 
ORDER BY [io_stall_read_ms] DESC
	



SELECT TOP 10
creation_time								--Hora em que o plano foi compilado.
, last_execution_time						--Hora do início da execução do plano.
, total_logical_reads AS [LogicalReads]		--Número total de leituras lógicas efetuadas por execuções deste plano desde sua compilação.
, total_logical_writes AS [LogicalWrites]	--Número total de gravações lógicas efetuadas por execuções deste plano desde sua compilação.
, execution_count							--Número de vezes que o plano foi executado desde sua última compilação.
, total_logical_reads+total_logical_writes AS [AggIO] 
, (total_logical_reads+total_logical_writes)/(execution_count+0.0) AS [AvgIO]
, st.TEXT
, plan_handle
, DB_NAME(st.dbid) AS database_name
, st.objectid AS OBJECT_ID
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_logical_reads+total_logical_writes > 0
AND sql_handle IS NOT NULL
ORDER BY [AggIO] DESC
