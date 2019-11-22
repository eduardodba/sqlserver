--número de I/Os pendentes que estão aguardando a conclusão de toda a instância do SQL Server
SELECT SUM(pending_disk_io_count) AS [Number of pending I/Os] FROM sys.dm_os_schedulers 


--detalhes sobre a contagem de I/O paralisada informada pela primeira consulta
SELECT *  FROM sys.dm_io_pending_io_requests


--CPU
select a.spid,db.name, a.cpu as 'CPU(bytes)', a.memusage, a.last_batch,
a.blocked, a.status, a.hostname, a.program_name, a.cmd, a.loginame from sys.sysprocesses a
inner join sys.sysdatabases db on a.dbid = db.dbid
where a.loginame <> 'CSFCPV\au_20005101832' and a.loginame <> 'sa' and  a.status <> 'background' --and a.spid=173 
order by 6,3 desc -- dba..sp_dba


--SESSOES ATIVAS
SELECT login_name, status, COUNT(*) as conexoes FROM sys.dm_exec_sessions 
WHERE login_name <> 'CSFCPV\au_20005101832' and login_name <> 'CSFCPV\cluster_sql' and
is_user_process = 1 GROUP BY login_name, status order by status
select login_name, status,host_name, program_name, * FROM sys.dm_exec_sessions WHERE 
login_name <> 'CSFCPV\au_20005101832' and login_name <> 'sa'  and login_name <> 'CSFCPV\cluster_sql'
and is_user_process = 1 order by 2 