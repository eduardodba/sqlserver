--Mostrar o tipo de espera de recurso
SELECT es.session_id, DB_NAME(er.database_id) AS [database_name],
OBJECT_NAME(qp.objectid, qp.dbid) AS [object_name], -- NULL if Ad-Hoc or Prepared statements
er.wait_type,
er.wait_resource,
er.status,
(SELECT CASE
WHEN pageid = 1 OR pageid % 8088 = 0 THEN 'Is_PFS_Page'
WHEN pageid = 2 OR pageid % 511232 = 0 THEN 'Is_GAM_Page'
WHEN pageid = 3 OR (pageid - 1) % 511232 = 0 THEN 'Is_SGAM_Page'
WHEN pageid IS NULL THEN NULL
ELSE 'Is Not PFS, GAM or SGAM page' END
FROM (SELECT CASE WHEN er.[wait_type] LIKE 'PAGE%LATCH%' AND er.[wait_resource] LIKE '%:%'
THEN CAST(RIGHT(er.[wait_resource], LEN(er.[wait_resource]) - CHARINDEX(':', er.[wait_resource], LEN(er.[wait_resource])-CHARINDEX(':', REVERSE(er.[wait_resource])))) AS INT)
ELSE NULL END AS pageid) AS latch_pageid
) AS wait_resource_type,
er.wait_time AS wait_time_ms,
(SELECT qt.TEXT AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt
FOR XML PATH(''), TYPE) AS [running_batch],
(SELECT SUBSTRING(qt2.TEXT,
(CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END),
(CASE WHEN er.statement_end_offset = -1 THEN DATALENGTH(qt2.TEXT) ELSE er.statement_end_offset/2 END - (CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END))) AS [text()] FROM sys.dm_exec_sql_text(er.sql_handle) AS qt2
FOR XML PATH(''), TYPE) AS [running_statement],
qp.query_plan
FROM sys.dm_exec_requests er
LEFT OUTER JOIN sys.dm_exec_sessions es ON er.session_id = es.session_id
CROSS APPLY sys.dm_exec_query_plan (er.plan_handle) qp
WHERE er.session_id <> @@SPID AND es.is_user_process = 1
ORDER BY er.total_elapsed_time DESC, er.logical_reads DESC, [database_name], session_id