--STATUS DA SINCRONIZACAO
SELECT DISTINCT(synchronization_health_desc)
		FROM sys.dm_hadr_database_replica_states;
	
	
		
--BACKUPS TLOG MAIORES QUE 40MIN
WITH sqltmp (DatabaseName, LastBackupId) AS
(
SELECT sdb.Name ,MAX(bus.backup_set_id)
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON (bus.database_name = sdb.name AND bus.type = 'L' )
GROUP BY sdb.name
)
SELECT a.DatabaseName, b.backup_start_date , b.backup_finish_date,
Convert( numeric (8,2),Round(b.backup_size/ (1024*1024),2) ) [Size_MB], 
(SELECT ISNULL(DATEDIFF(Mi,b.backup_start_date,(SELECT DATEADD(mi,-40,GETDATE()))),0)) as Min_Atraso
FROM sqltmp a INNER JOIN msdb.dbo.backupset b ON
( a.LastBackupId = b.backup_set_id)
WHERE a.DatabaseName NOT IN ('tempdb','model','msdb','master')
       and b.backup_start_date < (SELECT DATEADD(mi,-40,GETDATE()))
ORDER BY DatabaseName, b.backup_finish_date desc;



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

	
	
	
	
	