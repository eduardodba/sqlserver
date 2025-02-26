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



--Verifica backup database por tipo	   
use msdb
go
select  s.backup_set_id,
             s.machine_name,
        s.first_lsn,
        s.last_lsn,
        s.database_name,
        s.backup_start_date,
        s.backup_finish_date,
        s.type,
             f.physical_device_name
from    backupset s join backupmediafamily f
        on s.media_set_id = f.media_set_id
where   --s.backup_finish_date > '03/15/2019' -- or any recent date to limit result set
         s.database_name = 'FaturaMensal'
		 and s.is_copy_only=0
		 and s.type='L'
             --and s.last_lsn = '1394458000019363600012'
order by s.backup_finish_date DESC    




--Last backup by type
SELECT	sdb.NAME AS DBNAME
	   ,Max(backup_start_date) AS DATA_INICIO
	   ,Max(bs.backup_finish_date) AS DATA_FIM
	   ,CASE WHEN bs.type = 'D' THEN 'FULL'
			 WHEN bs.type = 'I' THEN 'DIFF'
			 WHEN bs.type = 'L' THEN 'LOG'
	    END AS TIPO
	   ,CONVERT(VARCHAR(8), Convert(TIME, Convert(DATETIME, Datediff(ms, Max(backup_start_date), Max(bs.backup_finish_date)) / 86400000.0))) [DURACAO]
FROM master.sys.databases sdb
LEFT OUTER JOIN msdb.dbo.backupset bs ON bs.database_name = sdb.NAME
WHERE ( bs.type = 'D'
		OR bs.type = 'I'
		OR bs.type = 'L'
		OR bs.type IS NULL)
	AND state_desc IN ('ONLINE')
	AND replica_id IS NULL
	--AND sdb.NAME = 'database2'
GROUP BY sdb.NAME
		,bs.type
ORDER BY sdb.NAME









--Portal Monitoração

    if OBJECT_ID('tempdb..#backupset') is not null
        DROP TABLE #backupset

    select
        bs.database_name	
    ,	bs.[type]			
    ,	max(bs.backup_finish_date) backup_finish_date
	,	max(bs.backup_start_date) backup_start_date
    into #backupset
    from MSDB.dbo.backupset bs
    group by
        bs.database_name
     ,	bs.[type]


    DECLARE  
            @full_minutes	int
       ,	@log_minutes	int
       ,	@diff_minutes	int


    IF (select SERVERPROPERTY('IsHadrEnabled')) = 1 
    BEGIN
    
    DECLARE @node NVARCHAR(255), @QUERY1 NVARCHAR(MAX)
    DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
    
    select  replica_server_name      
    from sys.availability_groups ag  
    inner join sys.availability_replicas ar    
        on ag.group_id = ar.group_id  
    left join sys.dm_hadr_availability_replica_states rs    
        on  rs.replica_id = ar.replica_id      
    where ag.is_distributed = 0     
    and replica_server_name <> @@SERVERNAME
    
        OPEN c
        FETCH NEXT FROM c INTO @node ;
        WHILE @@fetch_status = 0
        BEGIN
            SET @QUERY1 = '
            insert into #backupset
            select
                bs.database_name	as DBName
            ,	bs.[type]			as BackupType
            ,	max(bs.backup_finish_date) backup_finish_date
			,	max(bs.backup_start_date) backup_start_date
        from ['+ @node +'].MSDB.dbo.backupset bs
        group by
            bs.database_name
        ,	bs.[type]'

        EXEC SP_EXECUTESQL @QUERY1
        FETCH NEXT FROM c INTO @node;

        END
        CLOSE C
        DEALLOCATE c
    END
    
    SELECT @full_minutes = -1 * threshold FROM dba.MONIT.config WHERE servico = 'BACKUP FULL'
    SELECT @diff_minutes = -1 * threshold FROM dba.MONIT.config WHERE servico = 'BACKUP DIFERENCIAL'
    SELECT @log_minutes  = -1 * threshold FROM dba.MONIT.config WHERE servico = 'BACKUP LOG'
       
    -- Last Backup por Database / Type
    declare @BackupType as table (
        BackupType  char(1)
      , BackupDesc  varchar(128)
    )

    insert into @BackupType ( BackupType, BackupDesc ) 
      values   ( 'D', 'DatabaseBackupFull' )
             , ( 'L', 'LogBackup' )
             , ( 'I', 'DiffBackup' )
    ; with cteBackup as (
        SELECT
            d.name          as DBName
          , bt.BackupDesc   as BackupDesc
          , bkps.LastBackup as LastBackup
		  , bkps.LastBackupStart as LastBackupStart
        FROM
            @BackupType bt 
          cross join
            sys.databases d
          left join
        ( select
              bs.database_name	as DBName
            , bs.[type]			as BackupType
            , max(bs.backup_finish_date) LastBackup
			, max(bs.backup_start_date) LastBackupStart
          from #backupset bs
          group by
              bs.database_name
            , bs.[type]  ) bkps
        on d.name = bkps.DBName
       and bt.BackupType = bkps.BackupType)

       

SELECT 
    bkp.DBName,
    CONVERT(VARCHAR(20), ISNULL(bkp.DatabaseBackupFull, '1900-01-01'), 22) AS DatabaseBackupFull,
    DATEDIFF(MINUTE, CONVERT(VARCHAR(20), ISNULL(bkp.DatabaseBackupFullStart, '1900-01-01'), 22), CONVERT(VARCHAR(20), ISNULL(bkp.DatabaseBackupFull, '1900-01-01'), 22)) as ElapseMinFull,
	CASE WHEN ISNULL(bkp.DatabaseBackupFull, '1900-01-01') < DATEADD(MINUTE, @full_minutes, GETDATE()) 
             OR DbName = 'master' 
             AND ISNULL(bkp.DatabaseBackupFull, '1900-01-01') < DATEADD(MINUTE, @diff_minutes, GETDATE()) 
        THEN 'Backup em atraso' 
        ELSE 'OK' 
    END AS Situacao_FULL,
    CONVERT(VARCHAR(20), ISNULL(bkp.LogBackup, '1900-01-01'), 22) AS LogBackup,
    DATEDIFF(minute, CONVERT(VARCHAR(20), ISNULL(bkp.LogBackupStart, '1900-01-01'), 22), CONVERT(VARCHAR(20), ISNULL(bkp.LogBackup, '1900-01-01'), 22)) as ElapseMinLog,
	CASE 
        WHEN ISNULL(bkp.LogBackup, '1900-01-01') < DATEADD(MINUTE, @log_minutes, GETDATE()) 
             AND db.recovery_model_desc = 'FULL' 
        THEN 'Backup em atraso' 
        ELSE 'OK' 
    END AS Situacao_Log,
    CONVERT(VARCHAR(20), ISNULL(bkp.DiffBackup, '1900-01-01'), 22) AS DiffBackup,
    DATEDIFF(minute, CONVERT(VARCHAR(20), ISNULL(bkp.DiffBackupStart, '1900-01-01'), 22), CONVERT(VARCHAR(20), ISNULL(bkp.DiffBackup, '1900-01-01'), 22)) as ElapseMinDiff,
	CASE 
        WHEN ISNULL(bkp.DiffBackup, '1900-01-01') < DATEADD(MINUTE, @diff_minutes, GETDATE()) 
             AND ISNULL(bkp.DatabaseBackupFull, '1900-01-01') < DATEADD(MINUTE, @diff_minutes, GETDATE()) 
             AND bkp.DBName <> 'master' 
        THEN 'Backup em atraso' 
        ELSE 'OK' 
    END AS Situacao_Diff,
	(SUM(CAST(mf.size AS bigint)) * 8 / 1024) / 1024 AS Size_GBs
FROM 
    (SELECT 
         DBName, 
         MAX(CASE WHEN BackupDesc = 'DatabaseBackupFull' THEN LastBackup END) AS DatabaseBackupFull,
         MAX(CASE WHEN BackupDesc = 'LogBackup' THEN LastBackup END) AS LogBackup,
         MAX(CASE WHEN BackupDesc = 'DiffBackup' THEN LastBackup END) AS DiffBackup,
         MAX(CASE WHEN BackupDesc = 'DatabaseBackupFull' THEN LastBackupStart END) AS DatabaseBackupFullStart,
         MAX(CASE WHEN BackupDesc = 'LogBackup' THEN LastBackupStart END) AS LogBackupStart,
         MAX(CASE WHEN BackupDesc = 'DiffBackup' THEN LastBackupStart END) AS DiffBackupStart
     FROM 
         cteBackup
     WHERE 
         BackupDesc IN ('DatabaseBackupFull', 'LogBackup', 'DiffBackup')
     GROUP BY 
         DBName) bkp
INNER JOIN 
    sys.databases db ON bkp.DBName = db.name
INNER JOIN sys.master_files mf 
	ON db.database_id = mf.database_id
WHERE 
    DBName COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (SELECT [database_name] FROM dba.MONIT.db_excecao) 
    AND db.state_desc = 'ONLINE'
GROUP BY bkp.DBName, bkp.DatabaseBackupFull, bkp.DatabaseBackupFullStart, bkp.LogBackup, bkp.LogBackupStart, recovery_model_desc, bkp.DiffBackup,
bkp.DiffBackupStart

ORDER BY 
    Situacao_FULL, Situacao_Diff, Situacao_Log;
