
--	SELECT * FROM msdb.dbo.sysjobs
SELECT command ,
            s.text ,
            start_time,
            percent_complete,
            CAST(((DATEDIFF (s, start_time,GetDate ()))/3600) as varchar) + ' hour(s), '
                  + CAST ((DATEDIFF( s,start_time ,GetDate())% 3600)/60 as varchar ) + 'min, '
                  + CAST ((DATEDIFF( s,start_time ,GetDate())% 60) as varchar ) + ' sec' as running_time,
            CAST((estimated_completion_time /3600000) as varchar) + ' hour(s), '
                  + CAST ((estimated_completion_time %3600000)/ 60000 as varchar) + 'min, '
                  + CAST ((estimated_completion_time %60000)/ 1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second ,estimated_completion_time/ 1000, getdate()) as est_completion_time
FROM sys .dm_exec_requests r
CROSS APPLY sys. dm_exec_sql_text(r .sql_handle) s
WHERE r .command in ( 'RESTORE DATABASE', 'BACKUP DATABASE', 'RESTORE LOG', 'BACKUP LOG')

-------------------------------------------------------------------------------------------------------------------------------------

select step_id
,step_name
,Case 
  When last_run_outcome = 0 then '*** Falha****' 
  When last_run_outcome = 1 then 'ok'
  When last_run_outcome = 3 then '*** Cancelado ***'
  When last_run_outcome = 5 then 'Desconhecido'
end [status]
,last_run_date
from msdb.dbo.sysjobsteps 
where job_id='B8B0658E-D27B-4766-8BD2-90F36177B450'


-------------------------------------------------------------------------------------------------------------------------------------

--select top 100 * From msdb.dbo.sysjobservers where last_run_outcome <> 1

--select * from msdb..sysjobhistory where job_id ='DADB16A9-BA10-492F-BA02-25183B444A3C'
--select * from msdb.dbo.sysjobs where job_id ='DADB16A9-BA10-492F-BA02-25183B444A3C'

Select A.Name, 
--a.date_created,
B.last_run_date, B.last_run_time,
Case 
  When last_run_outcome = 0 then '*** Falha****' 
  When last_run_outcome = 1 then 'ok'
  When last_run_outcome = 3 then '*** Cancelado ***'
  When last_run_outcome = 5 then 'Desconhecido'
  When last_run_date = 0 then '[Sem Registro]'
end [STATUS],
case
	when a.enabled = 1 then 'Ativado'
	when a.enabled = 0 then '[Desativado]'
end [JOB] --, hist.message
	
From msdb.dbo.sysjobs A, msdb.dbo.sysjobservers B
-- , msdb.dbo.sysjobhistory hist 
Where  A.job_id = B.job_id           AND 
       B.last_run_outcome in(0,1,3,5) 
	   --B.last_run_outcome in(0) 
       --AND A.enabled = 1 --and A.enabled = 0 
	   and A.job_id='B8B0658E-D27B-4766-8BD2-90F36177B450'
Order by 1



--Drop JOB 

USE msdb ;  
GO  
  
EXEC sp_delete_job  
    @job_name = N'Dashboard Exceller - Gera Historico' ;  
GO  
