--Verifica a quantidade de sessoes por login
SELECT login_name, status, COUNT(*) as conexoes FROM sys.dm_exec_sessions 
WHERE login_name <> 'CSFCPV\cluster_sql' and
is_user_process = 1 GROUP BY login_name, status order by status


--Verifica as sessoes ativas
select login_name, status,host_name, program_name, * FROM sys.dm_exec_sessions WHERE 
login_name <> 'sa'  and login_name <> 'CSFCPV\cluster_sql'
and is_user_process = 1 order by 2 


--sessoes ativas com login em determinado horario
select login_name, status,host_name, program_name, login_time,* 
FROM sys.dm_exec_sessions
WHERE --login_name <> 'sa'  
--and login_name <> 'CSFCPV\cluster_sql'
--and is_user_process = 1 
login_name='dmsql'
and CONVERT(VARCHAR(25), login_time, 126) LIKE '%00:56:%'
order by 2 
