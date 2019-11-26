--https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/server-configuration-options-sql-server?view=sql-server-2017
--Listando as opções de configuração avançada

USE master;  
GO  
EXEC sp_configure 'show advanced option', '1';  

--Execute RECONFIGURE e exiba todas as opções de configuração:

RECONFIGURE;  
EXEC sp_configure; 




--Verificando parametro de memória maxima
SELECT a.name,a.value, a.value_in_use
FROM sys.configurations a 
WHERE a.name = 'max server memory (MB)'


--Defina a opção de memória máxima do servidor como 4 GB.

	sp_configure 'show advanced options', 1;
	GO
	RECONFIGURE;
	GO
	sp_configure 'max server memory', 4096;
	GO
	RECONFIGURE;
	GO
	sp_configure 'show advanced options', 0;
	GO
	RECONFIGURE;
