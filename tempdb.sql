/*Tempdb session File usage
----------------------------------
sys.dm_db_session_space_usage : Retorna o número de páginas alocadas e desalocadas por cada sessão para o banco de dados.
sys.dm_exec_sessions: Detalhes sobre as sessões.
*/

--Maior sessao com consumo do tempdb mais query em execução
SELECT
    sys.dm_exec_sessions.session_id AS [SESSION ID],
    DB_NAME(sys.dm_exec_sessions.database_id) AS [DATABASE Name],
    --program_name AS [Program Name],
    login_name AS [USER Name],
    status,
	HOST_NAME AS [System Name],
	Login_Time,
	(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
    --(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
    (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
    --(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
    --cpu_time AS [CPU TIME (in milisec)],
    --total_scheduled_time AS [Total Scheduled TIME (in milisec)],
    --total_elapsed_time AS    [Elapsed TIME (in milisec)],
	Text
    --(memory_usage * 8)      AS [Memory USAGE (in KB)],
    /*CASE is_user_process
         WHEN 1      THEN 'user session'
         WHEN 0      THEN 'system session'
    END AS [SESSION Type], row_count AS [ROW COUNT]*/
FROM 
	sys.dm_db_session_space_usage 
	INNER join sys.dm_exec_sessions
ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
INNER JOIN sys.dm_exec_connections ON sys.dm_exec_connections.session_id=sys.dm_exec_sessions.session_id
CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle)
WHERE sys.dm_exec_sessions.session_id > 50
ORDER BY [SPACE Allocated FOR USER Objects (in KB)] DESC,[SPACE Allocated FOR Internal Objects (in KB)] DESC 
 
 
------------------------------------------------------------------------------------------------------------------
--Consumo da temdb by VitorFava
SELECT
    sys.dm_exec_sessions.session_id AS [SESSION ID],
    DB_NAME(sys.dm_exec_sessions.database_id) AS [DATABASE Name],
    HOST_NAME AS [System Name],
    program_name AS [Program Name],
    login_name AS [USER Name],
    status,
    cpu_time AS [CPU TIME (in milisec)],
    total_scheduled_time AS [Total Scheduled TIME (in milisec)],
    total_elapsed_time AS    [Elapsed TIME (in milisec)],
    (memory_usage * 8)      AS [Memory USAGE (in KB)],
    (user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
    (user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
    (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
    (internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
    CASE is_user_process
         WHEN 1      THEN 'user session'
         WHEN 0      THEN 'system session'
    END AS [SESSION Type], row_count AS [ROW COUNT]
FROM 
	sys.dm_db_session_space_usage 
	INNER join sys.dm_exec_sessions
ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
WHERE sys.dm_exec_sessions.session_id > 50
