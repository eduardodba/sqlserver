USE [master]

set transaction isolation level read uncommitted
-------------------------------------------------------------------------------------------------------------------
-- <01> LISTAR O STATUS DAS REQUISICOES EM EXECUCAO. CHECAR STATUS DE BLOQUEIOS.
-------------------------------------------------------------------------------------------------------------------

DECLARE @database  VARCHAR(30) = NULL  
DECLARE @loginame  VARCHAR(30) = NULL
DECLARE @hostname  VARCHAR(30) = NULL
DECLARE @programa  VARCHAR(80) = NULL
DECLARE @sqltexto  VARCHAR(90) = NULL /* '%nome_proc%'  */
DECLARE @sessionid int         = NULL
DECLARE @linkedserver int = NULL -- 1 para filtrar apenas linkedserver

SELECT	
	R.session_id
,	R.blocking_session_id
,	DB_NAME(R.database_id) AS database_name
,	S.login_name
,	S.[host_name]
,	S.[program_name]
,	R.command
,	R.[status]
,	actual_query = ISNULL(SUBSTRING(T.text,R.statement_start_offset/2 , (CASE WHEN R.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), T.text)) * 2 ELSE R.statement_end_offset END - R.statement_start_offset)/2),'')
,	isnull(OBJECT_NAME(t.objectid, t.dbid),'AdHoc') as ObjName
,	R.start_time
,	total_time = CASE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) WHEN '23:59:59' THEN '00:00:00' ELSE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) END
,	REPLICATE('0', 2 - LEN((R.cpu_time/1000) / 3600)) + CAST(((R.cpu_time/1000) / 3600) AS VARCHAR) + ':' + 
	REPLICATE('0', 2 - LEN(((R.cpu_time/1000) % 3600) / 60)) + CAST((((R.cpu_time/1000) % 3600) / 60) AS VARCHAR) + ':' + 
	REPLICATE('0', 2 - LEN(((R.cpu_time/1000) % 3600) % 60)) + CAST((((R.cpu_time/1000) % 3600) % 60) AS VARCHAR) AS cpu_time
,	REPLICATE('0', 2 - LEN(((R.total_elapsed_time - R.cpu_time)/1000) / 3600)) + CAST((((R.total_elapsed_time - R.cpu_time)/1000) / 3600) AS VARCHAR) + ':' + 
	REPLICATE('0', 2 - LEN((((R.total_elapsed_time - R.cpu_time)/1000) % 3600) / 60)) + CAST(((((R.total_elapsed_time - R.cpu_time)/1000) % 3600) / 60) AS VARCHAR) + ':' + 
	REPLICATE('0', 2 - LEN((((R.total_elapsed_time - R.cpu_time)/1000) % 3600) % 60)) + CAST(((((R.total_elapsed_time - R.cpu_time)/1000) % 3600) % 60) AS VARCHAR) AS total_wait
,	DATEDIFF (SS, S.last_request_end_time, GETDATE()) / 1000 AS SleepingTimeSec
,	R.wait_time
,	Tasks = (SELECT COUNT(*) FROM sys.dm_os_tasks TSK WHERE R.session_id = TSK.session_id)
,	R.wait_type
,	R.last_wait_type
,	R.wait_resource
,	R.writes
,	R.reads
,	R.logical_reads
,	R.row_count
,	Parallelism	= G.dop
,	R.open_transaction_count
,	G.query_cost
,	G.requested_memory_kb / 1024.0 as RequestedMemoryMB
,	g.granted_memory_kb / 1024.0 as GrantedMemoryMB
,	G.used_memory_kb / 1024.0 as UsedMemoryMB
,	S.client_interface_name
,	C.client_net_address
--,	C.client_tcp_port
--,	R.[lock_timeout]
,	R.open_resultset_count
--,	C.net_transport
--,	C.protocol_type
--,	T.[text]
,	P.query_plan
,	R.plan_handle
,	r.sql_handle
,	r.statement_sql_handle
,	S.login_time
,	S.last_request_start_time
,	S.last_request_end_time
, (Select name AS name From sys.servers Where is_linked = 1 and t.text like '%'+name+'%') Linkdserver
,	R.percent_complete AS [% completed]
--,	DATEADD(MINUTE, estimated_completion_time /60/1000, GETDATE()) AS estimated_time
--,	R.ansi_defaults
--,	R.ansi_nulls
--,	R.ansi_padding
--,	R.arithabort
FROM
	sys.dm_exec_requests R
	INNER JOIN sys.dm_exec_sessions S 
		ON	(R.session_id = S.session_id)
	INNER JOIN sys.dm_exec_connections C 
		ON	(R.session_id = C.session_id AND S.session_id = C.session_id)
	LEFT JOIN sys.dm_exec_query_memory_grants G 
		ON	(R.session_id = G.session_id AND S.session_id = G.session_id)
	OUTER APPLY sys.dm_exec_query_plan(R.plan_handle) P
	OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) T
WHERE
	(DB_NAME(R.database_id) LIKE @database or @database is null)
AND (S.login_name LIKE @loginame or @loginame is null)
AND (S.host_name LIKE @hostname or @hostname is null)
AND (S.program_name LIKE @programa or @programa is null)
AND (T.[text] LIKE @sqltexto or @sqltexto is null)
AND (r.session_id = @sessionid or @sessionid is null)
AND ((@linkedserver = 1 and T.[text] LIKE '%'+(Select name AS name From sys.servers Where is_linked = 1)+'%') or @linkedserver is null)
ORDER BY
	total_time DESC, cpu_time DESC
	--r.session_id
OPTION (RECOMPILE);
