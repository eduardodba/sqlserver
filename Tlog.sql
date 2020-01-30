--VER ESTADO DO LOG DE TRANSAÇÕES
DBCC SQLPERF (LOGSPACE)



--INFORMAÇÕES DOS AQRUIVOS
--SELECT * FROM DBO.SYSFILES;
EXECUTE SP_HELPFILE



--VER SE É POSSIVEL TRUNCAR O LOG
SELECT NAME, LOG_REUSE_WAIT_DESC FROM sys.databases;



--VER TRANSACTION EM ABERTO
DBCC OPENTRAN


--BACKUP TLOG
BACKUP log Faturamensal TO DISK = 'NUL:' WITH FORMAT, INIT, MAXTRANSFERSIZE = 1048576, BUFFERCOUNT = 100, COMPRESSION, STATS=1;
GO


--TRUNCATE LOG
USE [FaturaMensal]
GO
DBCC SHRINKFILE (N'FaturaMensal_log' , 0, TRUNCATEONLY)
GO



/*
BACKUP DO LOG

BACKUP LOG [hom_teste] TO  DISK = N'D:\Program Files\Microsoft SQL Server\log2'
GO
*/

-- Verifica a utilização dos arquivos de Log das databases
-- Caso a performance counters esteja vazia, tem que resolver esse problema antes.
SELECT db.[name] AS [Database Name],
       db.recovery_model_desc AS [Recovery Model],
       db.log_reuse_wait_desc AS [Log Reuse Wait Description],
       ls.cntr_value AS [Log Size (KB)],
       lu.cntr_value AS [Log Used (KB)],
       CAST(CAST(lu.cntr_value AS FLOAT) / CASE
                                               WHEN CAST(ls.cntr_value AS FLOAT) = 0 THEN
                                                   1
                                               ELSE
                                                   CAST(ls.cntr_value AS FLOAT)
                                           END AS DECIMAL(18, 2)) * 100 AS [Log Used %],
       db.[compatibility_level] AS [DB Compatibility Level],
       db.page_verify_option_desc AS [Page Verify Option]

FROM sys.databases AS db
    INNER JOIN sys.dm_os_performance_counters AS lu
        ON db.name = lu.instance_name
    INNER JOIN sys.dm_os_performance_counters AS ls
        ON db.name = ls.instance_name
WHERE lu.counter_name LIKE '%Log File(s) Used Size (KB)%'
      AND ls.counter_name LIKE '%Log File(s) Size (KB)%';

-- select * from sys.dm_os_performance_counters


--Informações do Transaction Log
--LOGFILE 2 (SP_helpfile)
select * from sys.dm_io_virtual_file_stats(DB_ID(),2);



-- Criar arquivo de log ldf

USE master;  
GO

ALTER DATABASE Solutions   
ADD LOG FILE 
(  
    NAME = Solutions_log_2,  
    FILENAME = '/var/opt/mssql/data/Solutions_log2.ldf',  
    SIZE = 10MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5%  
);
GO


-- Verificar arquivo
USE TransactionLog;  
GO

SELECT name, physical_name  
FROM sys.database_files;  
GO


--Deletar arquivo ldf
ALTER DATABASE TransactionLog REMOVE FILE database_log_temp 




--Ler conteudo do transaction log
--Para tentar identificar um crescimento do tlog, quando não tem sessão transacao aberta
SELECT 
 [current lsn],
 [transaction id],
 [operation],
 [transaction name],
 [context],
 [allocunitname],
 [page id],
 [slot id],
 [begin time],
 [end time],
 [number of locks],
 [lock information]
FROM sys.fn_dblog(NULL,NULL)
WHERE Operation in
	('LOP_BEGIN_XACT','LOP_MODIFY_ROW','LOP_DELETE_ROWS','LOP_INSERT_ROWS','LOP_COMMIT_XACT')
ORDER BY [begin time] DESC
