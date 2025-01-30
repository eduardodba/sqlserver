--Sessoes ativas por base
SELECT top 5
CASE WHEN DB_NAME( r .database_id ) is null then 'TOTAL' else DB_NAME( r .database_id ) END [database],
sum(case when r .blocking_session_id = 0 then 0 else 1 end ) bloked,
count(1) process,
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 0 and 30 then 1 else 0 end) '30s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 31 and 60 then 1 else 0 end) '60s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 61 and 90 then 1 else 0 end) '90s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) > 90 then 1 else 0 end) '> 90___'
FROM sys. dm_exec_requests r INNER JOIN sys.dm_exec_sessions s
ON r .session_id = s.session_id
WHERE r .STATUS NOT IN ( 'sleeping' , 'background' )
group by rollup (DB_NAME( r .database_id ))
order by 3 desc



--Sessoes ativas por hostname
SELECT top 5
CASE WHEN host_name is null then 'TOTAL' else host_name END [HOSTNAME],
sum(case when r .blocking_session_id = 0 then 0 else 1 end ) bloked,
count(1) process,
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 0 and 30 then 1 else 0 end) '30s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 31 and 60 then 1 else 0 end) '60s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) between 61 and 90 then 1 else 0 end) '90s___',
sum(case when DATEDIFF(second, cast(start_time as smalldatetime ),GETDATE()) > 90 then 1 else 0 end) '> 90___'
FROM sys. dm_exec_requests r INNER JOIN sys.dm_exec_sessions s
ON r .session_id = s.session_id
WHERE r .STATUS NOT IN ( 'sleeping' , 'background' )
group by rollup (host_name)
order by 3 desc



--Sessoes ativas por procedure
SELECT TOP 5 * 
FROM (
    SELECT 
        CASE 
            WHEN ISNULL(OBJECT_NAME(t.objectid, t.dbid), 'AdHoc') = 'AdHoc' THEN 
                (SELECT CASE WHEN LEFT(event_info, 100) NOT LIKE '%;%' THEN 'Adhoc' ELSE event_info END 
                 FROM sys.dm_exec_input_buffer(r.session_id, NULL))
            ELSE ISNULL(OBJECT_NAME(t.objectid, t.dbid), 'AdHoc') 
        END AS ObjName,
        SUM(CASE WHEN r.blocking_session_id = 0 THEN 0 ELSE 1 END) AS bloked,
        COUNT(1) AS process,
        SUM(CASE WHEN DATEDIFF(SECOND, CAST(start_time AS smalldatetime), GETDATE()) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS '30s___',
        SUM(CASE WHEN DATEDIFF(SECOND, CAST(start_time AS smalldatetime), GETDATE()) BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS '60s___',
        SUM(CASE WHEN DATEDIFF(SECOND, CAST(start_time AS smalldatetime), GETDATE()) BETWEEN 61 AND 90 THEN 1 ELSE 0 END) AS '90s___',
        SUM(CASE WHEN DATEDIFF(SECOND, CAST(start_time AS smalldatetime), GETDATE()) > 90 THEN 1 ELSE 0 END) AS '> 90___', 
        DB_NAME(t.dbid) + '..sp_recompile ''' + OBJECT_SCHEMA_NAME(t.objectid, t.dbid) + '.' + ISNULL(OBJECT_NAME(t.objectid, t.dbid), '') + '''' AS compile
    FROM sys.dm_exec_requests r 
    INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.status NOT IN ('sleeping', 'background')
    GROUP BY ROLLUP (t.objectid, t.dbid, r.session_id)
) tab 
WHERE ObjName <> 'AdHoc'
ORDER BY process DESC;
