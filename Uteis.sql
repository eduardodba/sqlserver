
--Procs uteis 
SP_who2
SP_whoisactive
SP_who "x"
SP_who "active"

--DB ID
SELECT DB_ID(); 

--Usuarios Orfaos
exec SP_change_users_login 'Report'
exec SP_help_revlogin



--Query em execucao
dbcc inputbuffer (session_id)



--Validar backup
restore verifyonly from disk = 'c:\backup.bak'
GO



--Matar sessao
kill session_id



--Verificar ultimos backups
SELECT database_name, backup_finish_date, type FROM msdb.dbo.backupset



--Ver espaço em disco
execute master.sys.xp_fixeddrives




--Error Log
EXEC sys.xp_readerrorlog
0, -- Error Log ou Agent Log
1, -- Arquivo Desejado
N'server', -- Texto para pesquisar
N'process ID' -- Texto para pesquisar




--Localizar objetos dentro do sql server
select * from sys.all_objects where name='SPNGS_MENSAGERIA_TRADUZIR_MENSAGENS';
 
 
 
--Espaço usado TABELA OU BASE SQL SERVER
USE <nome_banco>
GO
SP_SPACEUSED
sp_helpdb




--VERSAO DO SQL SERVER
SELECT @@VERSION AS 'SQL Server Version';  




--Verificar espaço nos volumes SQL SERVER
SELECT DISTINCT
  vs.volume_mount_point AS [Drive],
  --vs.logical_volume_name AS [Drive Name],
  vs.total_bytes/1024/1024/1024 AS [Drive Size GB],
  vs.available_bytes/1024/1024/1024 AS [Drive Free Space GB]
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
ORDER BY vs.volume_mount_point;




--Conectar com outro usuário
EXECUTE AS USER = 'TESTE'
SELECT SYSTEM_USER


--Grant Schema
GRANT SELECT ON SCHEMA::VENDA TO USR_TESTE


--Listar ultimas procedures modificadas
use DB_ServiceBroker
SELECT name,modify_date  FROM sys.objects 
WHERE type = 'P' AND (DATEDIFF(D,modify_date, GETDATE()) < 1)



--Limpar o errorlog
sp_cycle_errorlog


--Show Constraints
 SELECT (CASE 
        WHEN OBJECTPROPERTY(CONSTID, 'CNSTISDISABLED') = 0 THEN 'ENABLED'
        ELSE 'DISABLED'
        END) AS STATUS,
        OBJECT_NAME(CONSTID) AS CONSTRAINT_NAME,
        OBJECT_NAME(FKEYID) AS TABLE_NAME,
        COL_NAME(FKEYID, FKEY) AS COLUMN_NAME,
        OBJECT_NAME(RKEYID) AS REFERENCED_TABLE_NAME,
        COL_NAME(RKEYID, RKEY) AS REFERENCED_COLUMN_NAME
   FROM SYSFOREIGNKEYS
ORDER BY TABLE_NAME, CONSTRAINT_NAME,REFERENCED_TABLE_NAME, KEYNO 


--Disable / Enable Constraints
ALTER TABLE [TABLE_NAME] NOCHECK CONSTRAINT [ALL|CONSTRAINT_NAME]
ALTER TABLE [TABLE_NAME] WITH CHECK CHECK CONSTRAINT [ALL|CONSTRAINT_NAME]


--Ver Isolation levels
use Workspace
go
dbcc useroptions


--Change restoring mode
use master 
go
SELECT name FROM sys.databases WHERE state_desc = 'RESTORING'

RESTORE DATABASE TransactionLog WITH RECOVERY


--Page life
SELECT [cntr_value] FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Buffer Manager%' AND [counter_name] = 'Page life expectancy' 


--SCRIPT VIA SQLCMD
sqlcmd -S SERVIDOR -E -i C:\Users\xxxxxx\Desktop\xxxxxx.sql -o xxxxx.log


--DATABASE SIZE MB / GB

 SELECT d.NAME
    ,ROUND(SUM(CAST(mf.size AS bigint)) * 8 / 1024, 0) Size_MBs
    ,(SUM(CAST(mf.size AS bigint)) * 8 / 1024) / 1024 AS Size_GBs
FROM sys.master_files mf
INNER JOIN sys.databases d ON d.database_id = mf.database_id
WHERE d.database_id > 4 -- Skip system databases
GROUP BY d.NAME
ORDER BY d.NAME





-------------------------------------------
--	Consultar tabela consummida pela proc
-------------------------------------------
    
select distinct
referenced_entity_name
,is_caller_dependent
,is_selected
,is_updated  
,is_select_all      
,is_all_columns_found     
,is_insert_all      
,is_incomplete
from sys.dm_sql_referenced_entities('sysfunc.FI_SP_AUTWEB_LEVANTAREFINCOMPLETO_046_V3','OBJECT')


--Subir base em Recovery
restore database BASE_NAME with recovery



--SELECT EM TABELA PARTICIONADA


SELECT 
    p.partition_number AS [Partition], 
    fg.name AS [Filegroup], 
    p.Rows
FROM sys.partitions p
    INNER JOIN sys.allocation_units au
    ON au.container_id = p.hobt_id
    INNER JOIN sys.filegroups fg
    ON fg.data_space_id = au.data_space_id
WHERE p.object_id = OBJECT_ID('partitionTable')
ORDER BY [Partition];



select count(*), $partition.PF_ANO(ano) [Partition Number], ano FROM [partitionTable] group by $partition.PF_ANO(ano),ano order by 2
