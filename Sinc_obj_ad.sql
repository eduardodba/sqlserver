USE DBA
GO



IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('sp_replica_obj'))
   exec('CREATE PROCEDURE sp_replica_obj AS BEGIN SET NOCOUNT ON; END')
GO

ALTER  PROCEDURE [dbo].[sp_replica_obj] (@ACAO varchar(50)) AS
BEGIN

    SET NOCOUNT ON

    SELECT @ACAO = CASE WHEN @ACAO = 'login' THEN 'Copy-DbaLogin'
                        WHEN @ACAO = 'jobs' THEN 'Copy-DbaAgentJob'
                        WHEN @ACAO = 'linkedserver' THEN 'Copy-DbaLinkedServer' END 
    
    IF EXISTS (SELECT role_desc 
                   FROM sys.availability_replicas ar
                   LEFT JOIN sys.dm_hadr_availability_replica_states rs    
                       ON rs.replica_id = ar.replica_id  
                   WHERE replica_server_name = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(256)) AND
                         role_desc = 'PRIMARY')
    BEGIN
        /*
        -- =====================================
        --   Verificar se a pasta existe
        -- =====================================
        */
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
        SELECT DISTINCT TOP 1 replica_server_name
        FROM sys.availability_groups ag  
        INNER JOIN sys.availability_replicas ar    
            ON ag.group_id = ar.group_id  
        LEFT JOIN sys.dm_hadr_availability_replica_states rs    
            ON rs.replica_id = ar.replica_id      
        WHERE ag.is_distributed = 0 AND 
              replica_server_name <> @@SERVERNAME;
    
        PRINT '|||       | Nodes carregados.'
    
    
        /*
        -- =====================================
        --   Replica Objetos
        -- =====================================
        */
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
            PRINT CHAR(9)+CHAR(9)+CHAR(9)+@cmd;
            EXEC sp_executesql @cmd;
            FETCH NEXT FROM c INTO @cmd;
        END
        CLOSE c;
        DEALLOCATE c;
        
        PRINT '||||||||||| replicado.'
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
        SELECT DISTINCT TOP 1 replica_server_name
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
                         role_desc = 'PRIMARY')
        BEGIN
            PRINT '||||      | Conectado em um node primário...'
            
            IF EXISTS (SELECT 1 FROM JOB_ACTIVE WHERE IS_PRIMARY = 0)
            BEGIN
                PRINT '|||||     | Node era secundário e virou primário...'
                UPDATE JOB_ACTIVE SET IS_PRIMARY = 1;
                PRINT '||||||    | Habilitando os jobs...'
                
                DECLARE cjob CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
                    SELECT name FROM JOB_ACTIVE
                OPEN cjob;
                FETCH NEXT FROM cjob INTO @job;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    PRINT CHAR(9)+CHAR(9)+CHAR(9)+ 'Executando: exec msdb..sp_update_job @job_name = ''' + @job + ''', @enabled = 1;';
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
                            NAME NOT LIKE 'SPLIT_PARTICAO_EB_MOVTO') AND 
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
                    SELECT name FROM JOB_ACTIVE;
                OPEN cjob;
                FETCH NEXT FROM cjob INTO @job;
                WHILE @@FETCH_STATUS = 0
                BEGIN
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






exec dba..sp_replica_obj 'linkedserver'
GO

exec dba..sp_replica_obj 'login'
GO




