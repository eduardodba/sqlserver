CREATE OR ALTER PROCEDURE sp_valida_VersaoFCI AS

/*****************************************************
* Script para verificar versões do SQL Server em um   *
* cluster e identificar se há nós com a mesma versões *
*                                                     *
* Resumo do Script:                                   *
* Este script percorre os nós de um cluster do SQL    *
* Server, utilizando PowerShell, para obter as        *
* versões instaladas. Em seguida, compara as versões  *
* com a versão atual do servidor. Se for encontrada   *
* a mesma versão, é retornado 'OK', caso contrário,   *
* é retornado 'NOK'.                                  *
*													  *	
* Requisitos:                                         *
* EXEC sp_configure 'show advanced options', 1        *
* GO												  *
* RECONFIGURE										  *
* GO												  *
* EXEC sp_configure 'xp_cmdshell', 1				  *	
* GO												  *
* RECONFIGURE										  *
******************************************************/


BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		IF EXISTS (SELECT NodeName FROM sys.dm_os_cluster_nodes)
		BEGIN
			-- Declaração da tabela @tab para armazenar os resultados
			DECLARE @tab AS TABLE (result varchar(100), servidor varchar(100), instancia varchar(100), versao varchar(100))
			DECLARE @cmd NVARCHAR(2000)
			DECLARE @name VARCHAR(50)
			
			-- Declaração do cursor para percorrer os nós do cluster
			DECLARE nodes CURSOR FOR 
			    SELECT NodeName 
				FROM sys.dm_os_cluster_nodes
				WHERE is_current_owner = 0
			
			OPEN nodes  
			FETCH NEXT FROM nodes INTO @name  
			
			WHILE @@FETCH_STATUS = 0  
			BEGIN 
			    -- Construção do comando para executar o PowerShell em cada nó do cluster
			    SET @cmd = 'powershell.exe -command Invoke-Command -ComputerName ' + @name + ' -ScriptBlock { foreach ($Install in (Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'').InstalledInstances) {write-host $Install $((Get-ItemProperty ^"^"^"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$((Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'').$Install)\Setup""^")).PatchLevel}}'
			    -- Execução do comando e inserção dos resultados na tabela @tab
			    INSERT INTO @tab (result)
			    EXEC xp_cmdshell @cmd
			    -- Atualização do campo servidor da tabela @tab
			    UPDATE @tab SET servidor = @name WHERE servidor IS NULL
			    FETCH NEXT FROM nodes INTO @name 
			END 
			CLOSE nodes  
			DEALLOCATE nodes 

			DECLARE @aux AS TABLE (origem varchar(100) default CAST(SERVERPROPERTY('MACHINENAME') as VARCHAR(100)), versao varchar(100))
			
			SET @cmd = 'powershell.exe -command foreach ($Install in (Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'').InstalledInstances) {write-host $Install $((Get-ItemProperty ^"^"^"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$((Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'').$Install)\Setup""^")).PatchLevel}'

			INSERT INTO @aux (versao)
			EXEC xp_cmdshell @cmd

			-- Verificação se existe um nó do cluster com a mesma versão do node atual
			IF EXISTS ( 
			    SELECT 1
			    FROM (SELECT * FROM @tab AS ValorOriginal) AS t
			    INNER JOIN sys.dm_os_cluster_nodes 
					ON NodeName = servidor
			    WHERE  result IS NOT NULL AND 
					   is_current_owner = 0 AND 
					   result in (select versao from @aux) AND
					   LEFT(result, CHARINDEX(' ', result) - 1) = @@SERVICENAME
			)
			    print 'OK - Cluster com a mesma versao entre os nodes' 
			ELSE IF NOT EXISTS (select 1 from @aux where CAST(SERVERPROPERTY('MACHINENAME') as VARCHAR(100)) = origem)
				print 'Problema para coleta informacao' 
			ELSE
			    print 'NOK - Cluster com versoes diferentes entre os nodes' 
				
		END
		ELSE
			print 'A Instancia nao e um cluster FCI'
	END TRY
	BEGIN CATCH
		print 'Problema para coleta informacao' 
	END CATCH
END



