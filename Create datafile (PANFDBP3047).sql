-- Script para criar os datafiles que existem no Pancred e não foram criados no PANFDBP3047
-- DATA: 20/07/2021
-- AUTOR: EDUARDO


--Tabela para gerar o comando de criação
WITH TABLE_DATAFILES ([BD], [UNIDADE], [SIZE], [DATAFILE], [TIPO], [groupid]) AS (
SELECT a.name AS [BD]
	 ,b.filename as [UNIDADE]
	 ,SUM(b.size/128*1024) as [SIZE]
	 ,b.name as [DATAFILE]
	 ,case when len (replace ( b .filename ,'ldf', '')) <> LEN (b .filename) then 'log' else 'dados' end [TIPO]
	 ,b.groupid 
from master..sysdatabases a 
left join master..sysaltfiles b on a.dbid = b.dbid
WHERE a.name IN ('DATABASE1','DATABASE2','DATABASE3') 
group by a.name,b.filename,b.name, b.groupid)

SELECT CASE WHEN TIPO = 'dados' THEN 'ALTER DATABASE ['+BD+'] ADD FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB ) TO FILEGROUP [' +FILEGROUP_NAME(groupid)+ ']'
	   ELSE 'ALTER DATABASE ['+BD+'] ADD LOG FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB )'
	   END AS SCRIPT, BD, UNIDADE, DATAFILE, TIPO
FROM TABLE_DATAFILES 
ORDER BY BD



--Cursor para criar os datafiles faltantes
DECLARE @script nvarchar(max)
DECLARE datafiles_cursor CURSOR FAST_FORWARD
FOR SELECT SCRIPT FROM TABLE_DATAFILES1 EXCEPT SELECT SCRIPT FROM TABLE_DATAFILES2
OPEN datafiles_cursor;
FETCH NEXT FROM datafiles_cursor INTO @script;
WHILE @@fetch_status = 0
    BEGIN
        print @script
		--EXEC (@script)
    END;
CLOSE datafiles_cursor;
DEALLOCATE datafiles_cursor;
