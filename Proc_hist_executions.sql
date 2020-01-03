use Credito
SELECT object_name(m.object_id) as OBJECT_NAME, MAX(qs.last_execution_time) as DATE
FROM   sys.sql_modules m
LEFT   JOIN (sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st)
ON m.object_id = st.objectid
AND st.dbid = db_id()
GROUP  BY object_name(m.object_id)
order by 2 desc;