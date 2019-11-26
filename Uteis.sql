--Procs uteis 
SP_who2
SP_whoisactive
SP_who "x"
SP_who "active"



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




--DMV's AlwaysOn -- SQL SERVER
sys.dm_hadr_auto_page_repair
sys.dm_hadr_availability_group_states
sys.dm_hadr_availability_replica_cluster_states
sys.dm_hadr_availability_replica_states
sys.dm_hadr_availability_replica_cluster_nodes
sys.dm_hadr_cluster
sys.dm_hadr_cluster_members
sys.dm_hadr_cluster_networks
sys.dm_hadr_database_replica_cluster_states
sys.dm_hadr_database_replica_states
sys.dm_hadr_instance_node_map
sys.dm_hadr_name_id_map
sys.dm_tcp_listener_states




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




--Listar user roles sql server (uma database)
USE DATABASE_NAME
select rp.name as 'Role Name', mp.name as 'User' from sys.database_role_members rm
inner join sys.database_principals rp on rm.role_principal_id = rp.principal_id
inner join sys.database_principals mp on rm.member_principal_id = mp.principal_id
order by 2




--Listar user roles sql server
create table ##RolesMembers
(
    [Database] sysname,
    RoleName sysname,
    MemberName sysname
)
exec dbo.sp_MSforeachdb 'insert into ##RolesMembers select ''[?]'', ''['' + r.name + '']'', ''['' + m.name + '']'' 
from [?].sys.database_role_members rm 
inner join [?].sys.database_principals r on rm.role_principal_id = r.principal_id
inner join [?].sys.database_principals m on rm.member_principal_id = m.principal_id
-- where r.name = ''db_owner'' and m.name != ''dbo'' -- you may want to uncomment this line';
select * from ##RolesMembers
order by [Database], [RoleName]

drop table ##RolesMembers





--Conectar com outro usuário
EXECUTE AS USER = 'TESTE'
SELECT SYSTEM_USER


--Grant Schema
GRANT SELECT ON SCHEMA::VENDA TO USR_TESTE