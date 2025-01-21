--Procedure para validar se os jobs e linked servers estão sincronizados entre os nodes do AG

USE [DBA]
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('MONIT_REPLICACAO_OBJ'))
    exec('CREATE PROCEDURE MONIT_REPLICACAO_OBJ AS BEGIN SET NOCOUNT ON; END')
GO

ALTER procedure [dbo].[MONIT_REPLICACAO_OBJ] AS
BEGIN
	SET NOCOUNT ON

	--Executa somente em ambientes AG
	IF ((SELECT SERVERPROPERTY('IsHadrEnabled')) = 1)
	BEGIN
	
		--Cria uma tabela de controle dos objetos localmente
		IF OBJECT_ID(N'DBO.REPLICA_OBJ', N'U') IS NOT NULL  
		    DROP TABLE REPLICA_OBJ
	
		CREATE TABLE REPLICA_OBJ (SERVER VARCHAR(100), OBJ_NAME VARCHAR(100), OBJ_TYPE VARCHAR(100));
	
		--Atualiza os valores com jobs e linkedservers
		MERGE INTO REPLICA_OBJ AS target
		USING (
		    SELECT @@SERVERNAME server, name, 'LinkedServer' type 
		    FROM master.sys.servers 
			UNION ALL
			SELECT @@SERVERNAME server, name, 'Job' type 
		    FROM msdb.dbo.sysjobs 
			WHERE enabled = 1
		) AS source
		ON	target.OBJ_NAME = source.NAME and 
			target.SERVER = source.server and 
			target.OBJ_TYPE = source.type
		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (SERVER, OBJ_NAME, OBJ_TYPE)
		    VALUES (source.server, source.name, source.type)
		WHEN NOT MATCHED BY SOURCE THEN
		    DELETE;
		
		print 'Jobs e linkedservers atualizados na tabela REPLICA_OBJ'
	
		--Caso esteja executando em um node primary e que tenha base no AG
		IF EXISTS (SELECT role_desc 
	               FROM sys.availability_replicas ar
	               LEFT JOIN sys.dm_hadr_availability_replica_states rs    
						ON rs.replica_id = ar.replica_id  
	               WHERE replica_server_name = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(256)) AND
	                     role_desc = 'PRIMARY') AND EXISTS 
					(SELECT top 1 1
	                 FROM sys.availability_groups ag
	                 JOIN sys.dm_hadr_availability_replica_states ar ON ag.group_id = ar.group_id
	                 JOIN sys.dm_hadr_database_replica_cluster_states dbcs ON ar.replica_id = dbcs.replica_id
	                 WHERE ar.role_desc = 'PRIMARY')
	    BEGIN
			DECLARE @replica_server_name VARCHAR(200);
			DECLARE @nodes AS TABLE (replica_server_name VARCHAR(200));
			DECLARE @cmd NVARCHAR(MAX);
			
			INSERT INTO @nodes
			SELECT DISTINCT replica_server_name
			FROM sys.availability_groups ag  
			INNER JOIN sys.availability_replicas ar    
			    ON ag.group_id = ar.group_id  
			LEFT JOIN sys.dm_hadr_availability_replica_states rs    
			    ON rs.replica_id = ar.replica_id      
			WHERE ag.is_distributed = 0 AND 
			      replica_server_name <> @@SERVERNAME;
	
			
			--Cria uma tabela temporaria global de controle dos objetos dos demais nodes
			drop table if exists ##tab_obj
			create table ##tab_obj (SERVER VARCHAR(100), OBJ_NAME VARCHAR(100), OBJ_TYPE VARCHAR(100))
			
			--Grava objs na temporaria
			DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD FOR
				SELECT replica_server_name FROM @nodes;
			OPEN c;
			FETCH NEXT FROM c INTO @replica_server_name;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY
					set @cmd = 'insert into ##tab_obj select * from '+@replica_server_name+'.dba.dbo.REPLICA_OBJ;'
					exec sp_executesql @cmd
				END TRY
				BEGIN CATCH
					RAISERROR('A Tabela nao existe em um dos servidores passivos', 16, 1); 
					RETURN;
				END CATCH
				--print @cmd
			    FETCH NEXT FROM c INTO @replica_server_name;
			END
			CLOSE c;
			DEALLOCATE c;
			
			print 'Jobs e linkedservers carregados dos servidores leitura'
	
			drop table if exists #tb_alerts
	
			--Result set dos objetos que estao no primario e nao existem nos passivos
			;WITH Combined AS (
			    SELECT local.SERVER,
			           local.OBJ_NAME,
			           local.OBJ_TYPE,
			           remote.SERVER AS REMOTE_SERVER,
			           1 AS LINK_STATUS
			    FROM REPLICA_OBJ local
			    CROSS JOIN (SELECT DISTINCT SERVER FROM ##tab_obj) remote
			),
			UpdatedCombined AS (
			    SELECT c.SERVER,
			           c.OBJ_NAME,
			           c.OBJ_TYPE,
			           c.REMOTE_SERVER,
			           CASE 
			               WHEN remote.OBJ_NAME IS NULL THEN 0
			               ELSE c.LINK_STATUS
			           END AS LINK_STATUS
			    FROM Combined c
			    LEFT JOIN ##tab_obj remote
			    ON c.OBJ_NAME = remote.OBJ_NAME 
			    AND c.OBJ_TYPE = remote.OBJ_TYPE
			)
			SELECT SERVER,
			       OBJ_NAME,
			       OBJ_TYPE,
			       REMOTE_SERVER
			into #tb_alerts
			FROM UpdatedCombined
			WHERE LINK_STATUS = 0;
		END
	
		select * from #tb_alerts
	
		/*
		DECLARE @SERVERNAME VARCHAR(MAX), @criticidadeTxt VARCHAR(20)
		SELECT @criticidadeTxt = criticidade FROM dba.MONIT.config WHERE servico = 'Sincronizacao de Job e Linkedserver'
		SELECT @SERVERNAME = REPLACE(@@SERVERNAME, CHAR(92), '/') + ':' + CAST(SERVERPROPERTY('MachineName') AS VARCHAR(50))
	
		--Concatena valores em uma variavel para abrir chamado
		DECLARE @alerts VARCHAR(200);
		SELECT @alerts = COALESCE(@alerts + ', ', '') + Alert
		FROM (SELECT DISTINCT REMOTE_SERVER + ' - ' + OBJ_TYPE AS Alert FROM #tb_alerts) AS Alerts;
	
		
		IF @alerts IS NULL
			    AND EXISTS (SELECT * FROM dba.monit.alerts WHERE ID_EVENTO = 123456 AND IS_CLOSE IS NULL)
			BEGIN
			    UPDATE dba.MONIT.ALERTS 
			    SET IS_CLOSE = 1, DATA_CLOSE = GETDATE() 
			    WHERE ID_EVENTO = 123456 AND IS_CLOSE IS NULL
	
			    EXEC master..SEND_POST_MONIT     
			        @id_evento = '123456',
			        @instance = @SERVERNAME,
			        @metrica1_descricao = 'Sincronizacao de Job e Linkedserver',
			        @metrica1_valor = @alerts,
			        @metrica2_descricao = '-1',
			        @metrica2_valor = '',
			        @status = 'CLOSED',
			        @criticidade = '0'
			END
			ELSE IF @alerts IS NOT NULL
			    AND NOT EXISTS (SELECT * FROM dba.monit.alerts WHERE ID_EVENTO = 123456 AND IS_CLOSE IS NULL)
			BEGIN
			    INSERT INTO dba.MONIT.ALERTS 
			    VALUES (33, 'Problema no linkedServer', @criticidadeTxt, GETDATE(), NULL, NULL)
				PRINT @lkValues
				EXEC master..SEND_POST_MONIT     
			        @id_evento = '123456',
			        @instance = @SERVERNAME,
			        @metrica1_descricao = 'Sincronizacao de Job e Linkedserver',
			        @metrica1_valor = @alerts,
			        @metrica2_descricao = '-1',
			        @metrica2_valor = '',
			        @status = 'OPEN',
			        @criticidade = @criticidadeTxt
			END
			*/
		
	
	END
END


