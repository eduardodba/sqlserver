USE MASTER
GO

DECLARE @database VARCHAR(30) = NULL
DECLARE @loginame VARCHAR(30) = NULL
DECLARE @hostname VARCHAR(30) = NULL
DECLARE @programa VARCHAR(80) = NULL
DECLARE @sqltexto VARCHAR(90) = NULL -- '%FI_SP_IncLogDV2%'
DECLARE @ObjName VARCHAR(80) = NULL -- 'FI_SP_IncLogDV2'
DECLARE @sessionid int = NULL
DECLARE @plan int = 1 -- 1 ou NULL
DECLARE @command nvarchar(max)

SET @command = '
SELECT
  R.session_id
, R.blocking_session_id
, DB_NAME(R.database_id) AS database_name
, S.login_name
, S.[host_name]
, S.[program_name]
, R.command
, R.[status]
, actual_query = ISNULL(SUBSTRING(T.text,R.statement_start_offset/2 , (CASE WHEN R.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), T.text)) * 2 ELSE R.statement_end_offset END - R.statement_start_offset)/2),'''')
, CASE 
    WHEN isnull(OBJECT_NAME(t.objectid, t.dbid),''AdHoc'') = ''AdHoc'' THEN 
        (SELECT CASE WHEN LEFT(event_info, 100) NOT LIKE ''%;%'' THEN ''Adhoc'' ELSE event_info END event_info
         FROM sys.dm_exec_input_buffer(R.session_id, NULL))
    ELSE isnull(OBJECT_NAME(t.objectid, t.dbid),''AdHoc'') 
  END as ObjName
, R.start_time
, total_time = CASE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) WHEN ''23:59:59'' THEN ''00:00:00'' ELSE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) END
, REPLICATE(''0'', 2 - LEN((R.cpu_time/1000) / 3600)) + CAST(((R.cpu_time/1000) / 3600) AS VARCHAR) + '':'' +
REPLICATE(''0'', 2 - LEN(((R.cpu_time/1000) % 3600) / 60)) + CAST((((R.cpu_time/1000) % 3600) / 60) AS VARCHAR) + '':'' +
REPLICATE(''0'', 2 - LEN(((R.cpu_time/1000) % 3600) % 60)) + CAST((((R.cpu_time/1000) % 3600) % 60) AS VARCHAR) AS cpu_time
, REPLICATE(''0'', 2 - LEN(((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) / 3600)) + CAST((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) / 3600) AS VARCHAR) + '':'' +
REPLICATE(''0'', 2 - LEN((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) / 60)) + CAST(((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) / 60) AS VARCHAR) + '':'' +
REPLICATE(''0'', 2 - LEN((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) % 60)) + CAST(((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) % 60) AS VARCHAR) AS total_wait
, DATEDIFF (SS, S.last_request_end_time, GETDATE()) / 1000 AS SleepingTimeSec
, R.wait_time
, Tasks = (SELECT COUNT(*) FROM sys.dm_os_tasks TSK WHERE R.session_id = TSK.session_id)
, R.wait_type
, R.last_wait_type
, R.wait_resource
, R.writes
, R.reads
, R.logical_reads
, R.row_count
, Parallelism = G.dop
, R.open_transaction_count
, G.query_cost
, G.requested_memory_kb / 1024.0 as RequestedMemoryMB
, g.granted_memory_kb / 1024.0 as GrantedMemoryMB
, G.used_memory_kb / 1024.0 as UsedMemoryMB
, S.client_interface_name
, C.client_net_address
--, C.client_tcp_port
--, R.[lock_timeout]
, R.open_resultset_count
--, C.net_transport
--, C.protocol_type
--, T.[text]'

IF @plan = 1 
BEGIN
    SET @command = @command + '
, P.query_plan
, TRY_CAST(tpq.query_plan as XML) as TrechoPlanoEmExecusao'
END

SET @command = @command + '
, R.plan_handle
, r.sql_handle
, S.login_time
, S.last_request_start_time
, S.last_request_end_time
, R.percent_complete AS [% completed]
--, DATEADD(MINUTE, estimated_completion_time /60/1000, GETDATE()) AS estimated_time
--, R.ansi_defaults
--, R.ansi_nulls
--, R.ansi_padding
--, R.arithabort
, CASE R.transaction_isolation_level WHEN 0 THEN ''Unspecified'' WHEN 1 THEN ''ReadUncommitted'' WHEN 2 THEN ''ReadCommitted'' WHEN 3 THEN ''Repeatable'' WHEN 4 THEN ''Serializable'' WHEN 5 THEN ''Snapshot'' END AS Transaction_Isolation_Level
, CASE WHEN OBJECT_NAME(t.objectid, t.dbid) IS NOT NULL THEN DB_NAME(t.dbid) + ''..sp_recompile '''''' + OBJECT_SCHEMA_NAME(t.objectid, t.dbid) + ''.'' + ISNULL(OBJECT_NAME(t.objectid, t.dbid), '''') + '''''''' ELSE ''DBCC FREEPROCCACHE (''+CONVERT(VARCHAR(MAX), R.plan_handle, 1)+'')'' END compile
FROM
sys.dm_exec_requests R
INNER JOIN sys.dm_exec_sessions S
ON (R.session_id = S.session_id)
INNER JOIN sys.dm_exec_connections C
ON (R.session_id = C.session_id AND S.session_id = C.session_id)
LEFT JOIN sys.dm_exec_query_memory_grants G
ON (R.session_id = G.session_id AND S.session_id = G.session_id)'

IF @plan = 1 
BEGIN
    SET @command = @command + '
OUTER APPLY sys.dm_exec_query_plan(R.plan_handle) P
Cross apply sys.dm_exec_text_query_plan(R.plan_handle, R.statement_start_offset , R.statement_end_offset) tpq'
END

SET @command = @command + '
OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) T
WHERE 1=1'

IF @database IS NOT NULL
    SET @command = @command + ' AND DB_NAME(R.database_id) LIKE ''' + @database + ''''

IF @loginame IS NOT NULL
    SET @command = @command + ' AND S.login_name LIKE ''' + @loginame + ''''

IF @hostname IS NOT NULL
    SET @command = @command + ' AND S.host_name LIKE ''' + @hostname + ''''

IF @programa IS NOT NULL
    SET @command = @command + ' AND S.program_name LIKE ''' + @programa + ''''

IF @sqltexto IS NOT NULL
    SET @command = @command + ' AND T.[text] LIKE ''' + @sqltexto + ''''

IF @sessionid IS NOT NULL
    SET @command = @command + ' AND r.session_id = ' + CAST(@sessionid AS VARCHAR(10))

IF @ObjName IS NOT NULL
    SET @command = @command + ' AND isnull(OBJECT_NAME(t.objectid, t.dbid),''AdHoc'') = ''' + @ObjName + ''''

SET @command = @command + '
ORDER BY
total_time DESC, cpu_time DESC
--r.session_id
OPTION (RECOMPILE);'

EXEC sp_executesql @command, 
    N'@database VARCHAR(30), 
	  @loginame VARCHAR(30), 
	  @hostname VARCHAR(30), 
	  @programa VARCHAR(80), 
	  @sqltexto VARCHAR(90), 
	  @ObjName VARCHAR(80), 
	  @sessionid int, 
	  @plan int',
      @database, 
	  @loginame, 
	  @hostname, 
	  @programa, 
	  @sqltexto, 
	  @ObjName, 
	  @sessionid, 
	  @plan

GO






--Versao antiga
USE MASTER
GO

DECLARE @database VARCHAR(30) = NULL
DECLARE @loginame VARCHAR(30) = NULL
DECLARE @hostname VARCHAR(30) = NULL
DECLARE @programa VARCHAR(80) = NULL
DECLARE @sqltexto VARCHAR(90) = NULL -- '%FI_SP_IncLogDV2%'
DECLARE @ObjName VARCHAR(80) = NULL -- 'FI_SP_IncLogDV2'
DECLARE @sessionid int = null

SELECT
  R.session_id
, R.blocking_session_id
, DB_NAME(R.database_id) AS database_name
, S.login_name
, S.[host_name]
, S.[program_name]
, R.command
, R.[status]
, actual_query = ISNULL(SUBSTRING(T.text,R.statement_start_offset/2 , (CASE WHEN R.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), T.text)) * 2 ELSE R.statement_end_offset END - R.statement_start_offset)/2),'')
, CASE 
    WHEN isnull(OBJECT_NAME(t.objectid, t.dbid),'AdHoc') = 'AdHoc' THEN 
        (SELECT CASE WHEN LEFT(event_info, 100) NOT LIKE '%;%' THEN 'Adhoc' ELSE event_info END event_info
         FROM sys.dm_exec_input_buffer(R.session_id, NULL))
    ELSE isnull(OBJECT_NAME(t.objectid, t.dbid),'AdHoc') 
  END as ObjName
, R.start_time
, total_time = CASE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) WHEN '23:59:59' THEN '00:00:00' ELSE CONVERT(VARCHAR(20), GETDATE() - R.start_time, 108) END
, REPLICATE('0', 2 - LEN((R.cpu_time/1000) / 3600)) + CAST(((R.cpu_time/1000) / 3600) AS VARCHAR) + ':' +
REPLICATE('0', 2 - LEN(((R.cpu_time/1000) % 3600) / 60)) + CAST((((R.cpu_time/1000) % 3600) / 60) AS VARCHAR) + ':' +
REPLICATE('0', 2 - LEN(((R.cpu_time/1000) % 3600) % 60)) + CAST((((R.cpu_time/1000) % 3600) % 60) AS VARCHAR) AS cpu_time
, REPLICATE('0', 2 - LEN(((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) / 3600)) + CAST((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) / 3600) AS VARCHAR) + ':' +
REPLICATE('0', 2 - LEN((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) / 60)) + CAST(((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) / 60) AS VARCHAR) + ':' +
REPLICATE('0', 2 - LEN((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) % 60)) + CAST(((((CAST(R.total_elapsed_time as BIGINT) - R.cpu_time)/1000) % 3600) % 60) AS VARCHAR) AS total_wait
, DATEDIFF (SS, S.last_request_end_time, GETDATE()) / 1000 AS SleepingTimeSec
, R.wait_time
, Tasks = (SELECT COUNT(*) FROM sys.dm_os_tasks TSK WHERE R.session_id = TSK.session_id)
, R.wait_type
, R.last_wait_type
, R.wait_resource
, R.writes
, R.reads
, R.logical_reads
, R.row_count
, Parallelism = G.dop
, R.open_transaction_count
, G.query_cost
, G.requested_memory_kb / 1024.0 as RequestedMemoryMB
, g.granted_memory_kb / 1024.0 as GrantedMemoryMB
, G.used_memory_kb / 1024.0 as UsedMemoryMB
, S.client_interface_name
, C.client_net_address
--, C.client_tcp_port
--, R.[lock_timeout]
, R.open_resultset_count
--, C.net_transport
--, C.protocol_type
--, T.[text]
--, P.query_plan
--, TRY_CAST(tpq.query_plan as XML) as TrechoPlanoEmExecusao
, R.plan_handle
, r.sql_handle
, S.login_time
, S.last_request_start_time
, S.last_request_end_time
, R.percent_complete AS [% completed]
--, DATEADD(MINUTE, estimated_completion_time /60/1000, GETDATE()) AS estimated_time
--, R.ansi_defaults
--, R.ansi_nulls
--, R.ansi_padding
--, R.arithabort
, CASE R.transaction_isolation_level WHEN 0 THEN 'Unspecified' WHEN 1 THEN 'ReadUncommitted' WHEN 2 THEN 'ReadCommitted' WHEN 3 THEN 'Repeatable' WHEN 4 THEN 'Serializable' WHEN 5 THEN 'Snapshot' END AS Transaction_Isolation_Level
FROM
sys.dm_exec_requests R
INNER JOIN sys.dm_exec_sessions S
ON (R.session_id = S.session_id)
INNER JOIN sys.dm_exec_connections C
ON (R.session_id = C.session_id AND S.session_id = C.session_id)
LEFT JOIN sys.dm_exec_query_memory_grants G
ON (R.session_id = G.session_id AND S.session_id = G.session_id)
--OUTER APPLY sys.dm_exec_query_plan(R.plan_handle) P
OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) T
--Cross apply sys.dm_exec_text_query_plan(R.plan_handle, R.statement_start_offset , R.statement_end_offset) tpq
WHERE
(DB_NAME(R.database_id) LIKE @database or @database is null)
AND (S.login_name LIKE @loginame or @loginame is null)
AND (S.host_name LIKE @hostname or @hostname is null)
AND (S.program_name LIKE @programa or @programa is null)
AND (T.[text] LIKE @sqltexto or @sqltexto is null)
AND (r.session_id = @sessionid or @sessionid is null)
AND (isnull(OBJECT_NAME(t.objectid, t.dbid),'AdHoc') = @ObjName or @ObjName is null)
ORDER BY
total_time DESC, cpu_time DESC
--r.session_id
OPTION (RECOMPILE);



