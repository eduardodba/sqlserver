
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
