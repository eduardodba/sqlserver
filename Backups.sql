--BACKUP MONITOR
SELECT
 database_name AS "Nome do banco" ,
 database_state AS "Estado" ,
 database_recmodel AS "Recovery Model" ,
 CASE
  WHEN check_flag = 'nao' THEN 'Ignorado'
  ELSE
   CASE
    WHEN full_date is null THEN 'Critico: Sem Backup Full.'
    WHEN full_min > thresholds.full_max_minutes THEN 'Problema: Backup Full Atrasado'
    WHEN check_flag <> 'apenas_full' AND tlog_date is null THEN 'Problema: Sem Backup de TLog'
    WHEN check_flag <> 'apenas_full' AND tlog_min > thresholds.tlog_max_minutes THEN  'Problema: Backup TLOG Atrasado'
    ELSE 'Regular'
    END
  END AS "Situacao do backup" ,
  full_date AS "Ultimo Full",
  tlog_date AS "Ultimo TLog" ,
  CONVERT(VARCHAR(30),DATEADD(minute,(thresholds.full_max_minutes*-1),GETDATE()),120) AS "Minimo Esperado (Full)",
  CONVERT(VARCHAR(30),DATEADD(minute,(thresholds.tlog_max_minutes*-1),GETDATE()),120) AS "Minimo Esperado (TLog)"
 FROM ( SELECT 2880 AS full_max_minutes
             ,  720 AS tlog_max_minutes
      ) thresholds
    , ( SELECT d.dbn AS database_name
             , d.rm  AS database_recmodel
             , d.sd  AS database_state
             , d.cf  AS check_flag
             , bf.mdt AS full_date
             , DATEDIFf(minute,bf.mdt,GETDATE()) AS full_min
             , bl.mdt AS tlog_date
             , DATEDIFf(minute,bl.mdt,GETDATE()) AS tlog_min
          FROM ( SELECT sd.name AS dbn
                      , sd.recovery_model_desc rm 
                      , sd.state_desc sd
                      , CASE WHEN sd.name in ('tempdb','model') THEN 'nao'
                             WHEN sd.state_desc <> 'ONLINE' THEN 'nao'
                             ELSE CASE WHEN sd.recovery_model_desc = 'SIMPLE' THEN 'apenas_full'
                                       ELSE 'completo'
                                  END
                        END as cf
                   FROM master.sys.databases sd
               ) d
               left outer join ( SELECT database_name dbn
                                      , max(backup_finish_date) AS mdt
                                   FROM msdb.dbo.backupset
                                  where type in ('D','I')
                                  group by database_name
                               ) bf
                            ON bf.dbn = d.dbn
               left outer join ( SELECT database_name dbn
                                      , max(backup_finish_date) AS mdt
                                   FROM msdb.dbo.backupset
                                  where type = 'L'
                                  group by database_name
                               ) bl
                            ON bl.dbn = d.dbn 
      ) data
 ORDER BY 1,4
 

--HISTORICO
select  bs.database_name, 
bs.backup_start_date as INICIAL, 
bs.backup_finish_date as FINAL,
bs.type, bs.recovery_model , 
bf.physical_device_name, 
CONVERT(NUMERIC(10,2), bs.compressed_backup_size/1024/1024) AS 'Backup Size(MB)'
from msdb..backupset bs
join msdb..backupmediafamily bf
on bs.media_set_id = bf.media_set_id
where backup_start_date >= getdate() -1 
--and type='D' 
--and bs.database_name not in ('dba','master','model','msdb')
--and bs.database_name ='faturamensal'
order by 2 desc

--select * from msdb..backupset  compressed_backup_size


--BACKUP PROCESS
SELECT
   session_id, percent_complete,
    start_time ,
    command, 
    b.name AS DatabaseName, --Most of the time will said Main but this is because db is not accesible
    DATEADD(ms,estimated_completion_time,GETDATE()) AS 'Previsão de Término',
    (estimated_completion_time/1000/60) AS MinutesToFinish
    FROM sys.dm_exec_requests a
    INNER JOIN sys.databases b 
    ON a.database_id = b.database_id
    WHERE b.name <> 'master'
    and command like '%restore%' or command like '%Backup%' AND estimated_completion_time > 0
	
	
--BACKUPS TLOG MAIORES QUE 40MIN
WITH sqltmp (DatabaseName, LastBackupId) AS
(
SELECT sdb.Name ,MAX(bus.backup_set_id)
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON (bus.database_name = sdb.name AND bus.type = 'L' )
GROUP BY sdb.name
)
SELECT @@SERVERNAME 'Server', a.DatabaseName, b.backup_start_date , b.backup_finish_date,m.physical_device_name,
Convert( numeric (8,2),Round(b.backup_size/ (1024*1024),2) ) [Size_MB], 
(SELECT ISNULL(DATEDIFF(Mi,b.backup_start_date,(SELECT DATEADD(mi,-40,GETDATE()))),0)) as Min_Atraso
FROM sqltmp a INNER JOIN msdb.dbo.backupset b ON
( a.LastBackupId = b.backup_set_id)
LEFT OUTER JOIN msdb.dbo.backupmediafamily m ON b.media_set_id = m.media_set_id
WHERE a.DatabaseName NOT IN ('tempdb','model','msdb','master')
       and b.backup_start_date < (SELECT DATEADD(mi,-40,GETDATE()))
ORDER BY DatabaseName, Min_Atraso;



--BACKUP FULL ATRASADO
SELECT  name as "Nome do Banco"
       ,state_desc as "Estado"
       ,recovery_model_desc as "Recovery Model"
       ,d AS 'Ultimo Backup Full'
	   ,i AS 'Ultimo Backup Diferencial'
FROM (SELECT db.name
            ,db.state_desc
            ,db.recovery_model_desc
            ,type
            ,backup_finish_date
        FROM master.sys.databases db LEFT OUTER JOIN msdb.dbo.backupset a 
			ON a.database_name = db.name) AS Sourcetable PIVOT (MAX(backup_finish_date) FOR type IN ( D, I, L ) ) AS MostRecentBackup
WHERE d <= DATEADD(day, -2, getdate()) and
	  name not in ('tempdb','model')
ORDER BY d
