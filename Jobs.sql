
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




--Ver etapa do job em execução
SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,      
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null;


--SHOW STEP JOBS FAILED
SELECT j.name JobName,h.step_name StepName, 
CONVERT(CHAR(10), CAST(STR(h.run_date,8, 0) AS dateTIME), 111) RunDate,
STUFF(STUFF(RIGHT('000000' + CAST ( h.run_time AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') RunTime, run_duration AS 'Duration in Second',
case h.run_status when 0 then 'failed'
when 1 then 'Succeded' 
when 2 then 'Retry' 
when 3 then 'Cancelled' 
when 4 then 'In Progress' 
end as ExecutionStatus, 
h.message MessageGenerated
FROM msdb..sysjobhistory h inner join msdb..sysjobs j
ON j.job_id = h.job_id
where h.run_status not in(1,4)
and run_date >=  FORMAT(GETDATE() - 1, 'yyyyMMdd')
ORDER BY run_date desc, h.run_time desc





--JOB STOP_JOB
-- Identificar o nome do job e alterar no script (select name from msdb.dbo.sysjobs)
declare @Job_Name varchar(256) = 'JOB_NAME'

DECLARE @job_status TABLE
(
JOB_ID UNIQUEIDENTIFIER,
LAST_RUN_DATE VARCHAR(20),
LAST_RUN_TIME VARCHAR(20),
NEXT_RUN_DATE VARCHAR(20),
NEXT_RUN_TIME VARCHAR(20),
NEXT_RUN_SCHEDULE_ID INT,
REQUESTED_TO_RUN INT,
REQUEST_SOURCE INT,
REQUEST_SOURCE_ID VARCHAR(100),
RUNNING INT,
CURRENT_STEP INT,
CURRENT_RETRY_ATTEMPT INT,
[STATE] INT,
PRIMARY KEY ( job_id )
)

INSERT INTO @job_status
EXEC master.dbo.xp_sqlagent_enum_jobs 1, 'N/A' ;

-- t.[STATE] = 1 THEN 'Running'
-- t.[STATE] = 2 THEN 'Waiting'
-- t.[STATE] = 3 THEN 'Retrying'
-- t.[STATE] = 4 THEN 'Not Running'
-- t.[STATE] = 5 THEN 'Suspended'
-- t.[STATE] = 7 THEN 'Completing'
IF EXISTS (SELECT sj.[NAME] 
             FROM [msdb].[dbo].[sysjobs] sj WITH (NOLOCK) 
             LEFT JOIN @job_status t ON sj.JOB_ID = t.JOB_ID 
             WHERE sj.[NAME] = @Job_Name
             AND t.[STATE] <> 4)
begin
print 'Realizando STOP do job ' +  @Job_name + '.'
exec msdb.dbo.sp_stop_job @Job_name
end


