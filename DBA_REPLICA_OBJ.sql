--Replicação de linkedservers / Login  / Jobs no AG

exec dba..sp_replica_obj 'linkedserver'
exec dba..sp_replica_obj 'login'
exec dba..sp_replica_obj 'job'
exec dba..sp_sinc_jobs





USE DBA
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('sp_replica_obj'))
   exec('CREATE PROCEDURE sp_replica_obj AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[sp_replica_obj] (@ACAO varchar(50)) AS
BEGIN
    SET NOCOUNT ON
    
    IF ((SELECT SERVERPROPERTY('IsHadrEnabled')) = 1)
    BEGIN
        SELECT @ACAO = CASE WHEN @ACAO = 'login' THEN 'Copy-DbaLogin'
                            WHEN @ACAO = 'job' THEN 'Copy-DbaAgentJob'
                            WHEN @ACAO = 'linkedserver' THEN 'Copy-DbaLinkedServer' END 
        
        IF EXISTS (SELECT role_desc 
                    FROM sys.availability_replicas ar
                    LEFT JOIN sys.dm_hadr_availability_replica_states rs    
                        ON rs.replica_id = ar.replica_id  
                    WHERE replica_server_name = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(256)) AND
                            role_desc = 'PRIMARY') AND EXISTS (SELECT top 1 1
                                                                FROM sys.availability_groups ag
                                                                JOIN sys.dm_hadr_availability_replica_states ar ON ag.group_id = ar.group_id
                                                                JOIN sys.dm_hadr_database_replica_cluster_states dbcs ON ar.replica_id = dbcs.replica_id
                                                                WHERE ar.role_desc = 'PRIMARY')
        BEGIN
            PRINT '|         | Validando se a pasta C:\dbatools existe...'
        
            DECLARE @folderPath NVARCHAR(255) = 'C:\dbatools';
            DECLARE @command NVARCHAR(4000);
            DECLARE @result INT;
            DECLARE @cmd NVARCHAR(MAX);
            
            SET @command = 'IF EXIST "' + @folderPath + '" (echo 1) ELSE (echo 0)';
            
            DROP TABLE IF EXISTS #result;
            CREATE TABLE #result (output NVARCHAR(255));
            
            INSERT INTO #result (output)
            EXEC xp_cmdshell @command;
            
            SELECT @result = CAST(output AS INT) FROM #result WHERE output IS NOT NULL;
            
            DROP TABLE #result;
            
            IF @result = 0
            BEGIN
                RAISERROR('Erro: A pasta não existe.', 16, 1);
            END
        
            PRINT '||        | Pasta validada.'
        
            PRINT '||        | Carregando os nodes do cluster em variável...'
            
            DECLARE @nodes AS TABLE (replica_server_name VARCHAR(200));
            INSERT INTO @nodes
            SELECT DISTINCT replica_server_name
            FROM sys.availability_groups ag  
            INNER JOIN sys.availability_replicas ar    
                ON ag.group_id = ar.group_id  
            LEFT JOIN sys.dm_hadr_availability_replica_states rs    
                ON rs.replica_id = ar.replica_id      
            WHERE ag.is_distributed = 0 AND 
                replica_server_name <> @@SERVERNAME;
        
            PRINT '|||       | Nodes carregados.'
        
            PRINT '|||||     | Executando '+@ACAO+'...'
            
            DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
                SELECT 'xp_cmdshell ''powershell.exe Import-Module -Name C:\dbatools -Verbose; '+@ACAO+' -Source "' +
                    CAST(SERVERPROPERTY('ServerName') AS VARCHAR(256)) +
                    '" -Destination "' + replica_server_name + '" -Verbose;'''
                FROM @nodes;
            
            OPEN c;
            FETCH NEXT FROM c INTO @cmd;
    
            WHILE @@FETCH_STATUS = 0
            BEGIN   
                IF @ACAO = 'Copy-DbaLinkedServer'
                BEGIN
                    DECLARE @excludeServers NVARCHAR(MAX) = '';
                    DECLARE @serverName VARCHAR(200);
                    DECLARE server_cursor CURSOR FOR 
                        SELECT replica_server_name FROM @nodes;
                    
                    OPEN server_cursor;
                    FETCH NEXT FROM server_cursor INTO @serverName;
                    
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @excludeServers += @serverName + ', ';
                        FETCH NEXT FROM server_cursor INTO @serverName;
                    END
                    
                    CLOSE server_cursor;
                    DEALLOCATE server_cursor;
                    
                    -- Remove the trailing comma and space
                    SET @excludeServers = LEFT(@excludeServers, LEN(@excludeServers) - 1);
                    
                    SET @cmd = REPLACE(@cmd, '" -Verbose;', '" -ExcludeLinkedServer "' + @excludeServers + '" -Verbose;');
                END

                PRINT CHAR(9)+CHAR(9)+CHAR(9)+@cmd;
                EXEC sp_executesql @cmd;
                FETCH NEXT FROM c INTO @cmd;
            END
            CLOSE c;
            DEALLOCATE c;
            
            PRINT '||||||||||| replicado.'
        END
    END
END
GO





USE DBA
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('sp_sinc_jobs'))
   exec('CREATE PROCEDURE sp_sinc_jobs AS BEGIN SET NOCOUNT ON; END')
GO

ALTER  PROCEDURE [dbo].[sp_sinc_jobs] AS
BEGIN
    
    SET NOCOUNT ON

    IF ((SELECT SERVERPROPERTY('IsHadrEnabled')) = 1)
    BEGIN
    
        DECLARE @folderPath NVARCHAR(255) = 'C:\dbatools';
        DECLARE @command NVARCHAR(4000);
        DECLARE @cmd NVARCHAR(MAX);
        DECLARE @job VARCHAR(200);
    
        PRINT '||        | Carregando os nodes do cluster em variável...'
        
        DECLARE @nodes AS TABLE (replica_server_name VARCHAR(200));
        INSERT INTO @nodes
        SELECT DISTINCT replica_server_name
        FROM sys.availability_groups ag  
        INNER JOIN sys.availability_replicas ar    
            ON ag.group_id = ar.group_id  
        LEFT JOIN sys.dm_hadr_availability_replica_states rs    
            ON rs.replica_id = ar.replica_id      
        WHERE ag.is_distributed = 0 AND 
              replica_server_name <> @@SERVERNAME;
    
        PRINT '|||       | Nodes carregados.'
    
    
        PRINT '|||       | Verificando controle dos jobs ativos no primary...'
    
        IF OBJECT_ID(N'DBO.JOB_ACTIVE', N'U') IS NULL  
        BEGIN
            CREATE TABLE JOB_ACTIVE (NAME VARCHAR(200), IS_PRIMARY BIT DEFAULT 0);
        END
    
    
        IF EXISTS (SELECT role_desc 
                   FROM sys.availability_replicas ar
                   LEFT JOIN sys.dm_hadr_availability_replica_states rs    
                       ON rs.replica_id = ar.replica_id  
                   WHERE replica_server_name = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(256)) AND
                         role_desc = 'PRIMARY') AND EXISTS (SELECT top 1 1
                                                            FROM sys.availability_groups ag
                                                            JOIN sys.dm_hadr_availability_replica_states ar ON ag.group_id = ar.group_id
                                                            JOIN sys.dm_hadr_database_replica_cluster_states dbcs ON ar.replica_id = dbcs.replica_id
                                                            WHERE ar.role_desc = 'PRIMARY')
        BEGIN
            PRINT '||||      | Conectado em um node primário...'
            
            IF EXISTS (SELECT 1 FROM JOB_ACTIVE WHERE IS_PRIMARY = 0)
            BEGIN
                PRINT '|||||     | Node era secundário e virou primário...'
                UPDATE JOB_ACTIVE SET IS_PRIMARY = 1;
                PRINT '||||||    | Habilitando os jobs...'
                
                DECLARE cjob CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
                    SELECT name FROM JOB_ACTIVE where name in (select name from msdb.dbo.sysjobs where enabled = 0)
                OPEN cjob;
                FETCH NEXT FROM cjob INTO @job;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SELECT @cmd = 'exec msdb..sp_update_job @job_name = ''' + @job + ''', @enabled = 1;';
                    PRINT CHAR(9)+CHAR(9)+CHAR(9)+ 'Executando: exec msdb..sp_update_job @job_name = ''' + @job + ''', @enabled = 1;';
                    EXEC sp_executesql @cmd;
                    FETCH NEXT FROM cjob INTO @job;
                END
                CLOSE cjob;
                DEALLOCATE cjob;
            END
            ELSE IF EXISTS (SELECT TOP 1 1 FROM JOB_ACTIVE WHERE IS_PRIMARY = 1) OR NOT EXISTS (SELECT TOP 1 1 FROM JOB_ACTIVE)
            BEGIN
                PRINT '|||||     | Node permanece como primário...'
                PRINT '||||||    | Atualizando lista de jobs ativos...'
                
                MERGE INTO JOB_ACTIVE AS target
                USING (
                    SELECT NAME 
                    FROM msdb.dbo.sysjobs 
                    WHERE ( NAME NOT LIKE 'MONIT%' AND 
                            NAME NOT LIKE '%IndexOptimize%' AND 
                            NAME NOT LIKE '%Baseline%' AND 
                            NAME NOT LIKE '%DBA%' AND 
                            NAME NOT LIKE '%Backup%' AND 
                            NAME NOT LIKE '%kill%' AND
                            NAME NOT LIKE '%purge_%history' AND
                            NAME NOT IN ('AUDITORIA_MONITOR', 
                                         'DatabaseIntegrityCheck - SYSTEM_DATABASES',
                                         'DatabaseIntegrityCheck - USER_DATABASES',
                                         'STOP_EXPURGO',
                                         'CommandLog Cleanup',
                                         'AlwaysOn_Latency_Data_Collection')) AND 
                            enabled = 1
                ) AS source
                ON target.NAME = source.NAME
                WHEN NOT MATCHED BY TARGET THEN
                    INSERT (NAME)
                    VALUES (source.NAME)
                WHEN NOT MATCHED BY SOURCE THEN
                    DELETE;
    
                PRINT '|||||||   | Lista de jobs ativos atualizada.'
    
                DECLARE @replica_server_name VARCHAR(200);
                PRINT '|||||||   | Replicando jobs ativos para os demais nodes...'
                
                DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
                    SELECT replica_server_name FROM @nodes;
                
                OPEN c;
                FETCH NEXT FROM c INTO @replica_server_name;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SELECT @cmd = '
                        IF EXISTS (SELECT 1 FROM dba.dbo.JOB_ACTIVE AS source
                                   WHERE NOT EXISTS (SELECT 1 FROM ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE AS target
                                                     WHERE target.NAME = source.NAME))
                        BEGIN
                            INSERT INTO ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE (NAME)
                            SELECT NAME FROM dba.dbo.JOB_ACTIVE AS source
                            WHERE NOT EXISTS (SELECT 1 FROM ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE AS target
                                              WHERE target.NAME = source.NAME)
                        END
                    
                        IF EXISTS (SELECT 1 FROM ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE AS target
                                   WHERE NOT EXISTS (SELECT 1 FROM dba.dbo.JOB_ACTIVE AS source
                                                     WHERE source.NAME = target.NAME))
                        BEGIN
                            DELETE FROM ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE
                            WHERE NAME IN (SELECT NAME FROM ' + @replica_server_name + '.dba.dbo.JOB_ACTIVE AS target
                                           WHERE NOT EXISTS (SELECT 1 FROM dba.dbo.JOB_ACTIVE AS source
                                                             WHERE source.NAME = target.NAME))
                        END';
                    
                    --PRINT @cmd;
                    EXEC sp_executesql @cmd;
                    FETCH NEXT FROM c INTO @replica_server_name;
                END
                CLOSE c;
                DEALLOCATE c;
    
                PRINT '||||||||  | Jobs ativos replicados para os demais nodes.'
            END
        END
        ELSE
        BEGIN
            PRINT '||||||||| | Conectado em um node secundário...'  
            IF EXISTS (SELECT TOP 1 1 FROM JOB_ACTIVE WHERE IS_PRIMARY = 0)
            BEGIN
                PRINT '||||||||| | Desativando os jobs...'
                
                DECLARE cjob CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
                    SELECT name FROM JOB_ACTIVE where name in (select name from msdb.dbo.sysjobs where enabled = 1)
                OPEN cjob;
                FETCH NEXT FROM cjob INTO @job;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SELECT @cmd = 'exec msdb..sp_update_job @job_name = ''' + @job + ''', @enabled = 0;';
                    PRINT CHAR(9)+CHAR(9)+CHAR(9)+'Executando: exec msdb..sp_update_job @job_name = ''' + @job + ''', @enabled = 0;';
                    EXEC sp_executesql @cmd;
                    FETCH NEXT FROM cjob INTO @job;
                END
                CLOSE cjob;
                DEALLOCATE cjob;
            
                PRINT '||||||||||| Jobs desativados.'
            END
        END
    END
END
GO


USE [msdb]
GO


IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA_REPLICA_OBJ') 
    EXEC msdb.dbo.sp_delete_job @job_name=N'DBA_REPLICA_OBJ' , @delete_unused_schedule=1
GO


DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DBA_REPLICA_OBJ', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=2, 
        @notify_level_page=2, 
        @delete_level=0, 
        @category_name=N'[Uncategorized (Local)]', 
        @owner_login_name=N'PAN-MATRIZ\usr_dba_coleta', @job_id = @jobId OUTPUT
select @jobId
GO
declare @server varchar(255)
select @server = cast(SERVERPROPERTY('ServerName') as varchar(50))
EXEC msdb.dbo.sp_add_jobserver @job_name=N'DBA_REPLICA_OBJ', @server_name = @server
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA_REPLICA_OBJ', @step_name=N'Sinc Jobs', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_fail_action=2, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'exec sp_sinc_jobs', 
        @database_name=N'DBA', 
        @flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA_REPLICA_OBJ', @step_name=N'Replica Objs', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_fail_action=2, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'exec sp_replica_obj ''linkedserver'';
exec sp_replica_obj ''login'';
exec sp_replica_obj ''job'';
', 
        @database_name=N'DBA', 
        @flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA_REPLICA_OBJ', @step_name=N'Desabilita Jobs Passivo', 
        @step_id=3, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_fail_action=2, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'exec sp_sinc_jobs', 
        @database_name=N'DBA', 
        @flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'DBA_REPLICA_OBJ', 
        @enabled=1, 
        @start_step_id=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=2, 
        @notify_level_page=2, 
        @delete_level=0, 
        @description=N'', 
        @category_name=N'[Uncategorized (Local)]', 
        @owner_login_name=N'PAN-MATRIZ\usr_dba_coleta', 
        @notify_email_operator_name=N'', 
        @notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DBA_REPLICA_OBJ', @name=N'1hr', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=8, 
        @freq_subday_interval=1, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=1, 
        @active_start_date=20250115, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO



