--https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/server-configuration-options-sql-server?view=sql-server-2017
--Listando as op��es de configura��o avan�ada

USE master;  
GO  
EXEC sp_configure 'show advanced option', '1';  

--Execute RECONFIGURE e exiba todas as op��es de configura��o:

RECONFIGURE;  
EXEC sp_configure; 




--Verificando parametro de mem�ria maxima
SELECT a.name,a.value, a.value_in_use
FROM sys.configurations a 
WHERE a.name = 'max server memory (MB)'


--Defina a op��o de mem�ria m�xima do servidor como 4 GB.

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
