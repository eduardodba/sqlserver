--Para a replicação no nó secundário "SUSPEND DATA MOVIMENT...."
--Readable Secondary = NO

--Mover arquivos mdf e ldf para outro local
USE MASTER
GO
ALTER DATABASE AdventureWorks2014   
    MODIFY FILE ( NAME = AdventureWorks2014_Data,   
                  FILENAME = 'E:\New_location\AdventureWorks2014_Data.mdf');  
GO
 
ALTER DATABASE AdventureWorks2014   
    MODIFY FILE ( NAME = AdventureWorks2014_Log,   
                  FILENAME = 'E:\New_location\AdventureWorks2014_Log.ldf');  
GO

--Ver atual dos arquivos
SELECT name, physical_name AS NewLocation, state_desc AS OnlineStatus
FROM sys.master_files  
WHERE database_id = DB_ID(N'AdventureWorks2014')  
GO

--Stopa a Instância
--Move os arquivos para o diretório apontado
XCOPY "C:\SQL_DISKS\AGSQLHML_DATA\AdventureWorksDW2016\AdventureWorksDW2016_Data.mdf" "C:\SQL_DISKS\AGSQLHML_LOG\TESTE" /o /x /e /h /k
--Starta a Instância

--Inicie a replicação no nó secundário "RESUME DATA MOVIMENT...."
--Readable Secondary = YES
