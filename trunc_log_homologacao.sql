--JOB PARA REALIZAR BACKUP E TRUNCAR LOGS DA HOMOLOGAÇÃO
IF EXISTS (
select ROLE_DESC
from sys.dm_hadr_availability_replica_states st
inner join sys.dm_hadr_availability_replica_cluster_states rp
on st.replica_id = rp.replica_id and st.group_id = rp.group_id
inner join
sys.availability_group_listeners ls
on ls.group_id = rp.group_id
where REPLICA_SERVER_NAME=@@SERVERNAME AND ROLE_DESC='PRIMARY')
BEGIN
EXECUTE sp_msforeachdb 'USE [?]
IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'')
begin
if exists (select recovery_model_desc from sys.databases where database_id=db_id() AND recovery_model_desc=''FULL'')
BEGIN TRY
BACKUP LOG [?] TO DISK = ''NUL:''
END TRY
BEGIN CATCH
SELECT 
    DB_NAME() DATABASENAME
    ,ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage  
END CATCH
ELSE
PRINT ''SIMPLE''
END
'
EXECUTE sp_msforeachdb 'USE [?]
DECLARE @sql NVARCHAR(MAX) = '''';
SELECT @sql += ''dbcc shrinkfile (['' + name + '']);'' FROM sysaltfiles where [groupid]=0 and [dbid]=db_id()
EXEC (@sql);
'
END
ELSE
PRINT 'STANDBY'