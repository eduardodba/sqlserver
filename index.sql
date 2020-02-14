--MOSTRAR FRAGMENTAÇÃO DOS INDEXS(PARA UMA DATABASE)
USE Teste_index
GO
IF EXISTS (SELECT * FROM tempdb.sys.all_objects WHERE name LIKE '#bbc%' )
DROP TABLE #bbc
CREATE TABLE #bbc (DatabaseName VARCHAR(100),SchemaName VARCHAR(50),ObjectName VARCHAR(100),Index_id int, indexName VARCHAR(100),avg_fragmentation_percent FLOAT,IndexType VARCHAR(100),Action_Required VARCHAR(100) DEFAULT 'NA')
GO
INSERT INTO #bbc (DatabaseName,SchemaName,ObjectName,Index_id, indexName,avg_fragmentation_percent,IndexType)
SELECT DB_NAME() AS DatabaseName, 
	   SCHEMA_NAME(t.schema_id) AS SchemaName,
	   OBJECT_NAME (a.OBJECT_ID) AS ObjectName,
	   a.index_id, b.name AS IndexName, 
	   avg_fragmentation_in_percent, index_type_desc
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.OBJECT_ID = b.OBJECT_ID AND a.index_id = b.index_id 
JOIN sys.tables AS t ON t.object_id=a.object_id
WHERE b.index_id <> 0 AND avg_fragmentation_in_percent <>0
GO 
UPDATE #bbc SET Action_Required ='Rebuild' WHERE avg_fragmentation_percent >30 
GO
UPDATE #bbc SET Action_Required ='Rorganize' WHERE avg_fragmentation_percent <30 AND avg_fragmentation_percent >5
GO
SELECT * FROM #bbc ORDER BY avg_fragmentation_percent DESC




/*MOSTRAR FRAGMENTAÇÃO DOS INDEXS (PARA TODAS AS BASES DA INSTÂNCIA)
If exists (select * from tempdb.sys.all_objects where name like '#bbc%' )
drop table #bbc
CREATE TABLE #bbc (DatabaseName VARCHAR(100),SchemaName VARCHAR(50),ObjectName VARCHAR(100),Index_id int, indexName VARCHAR(100),avg_fragmentation_percent FLOAT,IndexType VARCHAR(100),Action_Required VARCHAR(100) DEFAULT 'NA')
GO
INSERT INTO #bbc (DatabaseName,SchemaName,ObjectName,Index_id, indexName,avg_fragmentation_percent,IndexType)
exec master.sys.sp_MSforeachdb ' USE [?]
SELECT db_name() as DatabaseName, SCHEMA_NAME(t.schema_id) AS SchemaName, OBJECT_NAME (a.object_id) as ObjectName, 
a.index_id, b.name as IndexName, 
avg_fragmentation_in_percent, index_type_desc
-- , record_count, avg_page_space_used_in_percent --(null in limited)
FROM sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.OBJECT_ID = b.OBJECT_ID AND a.index_id = b.index_id 
JOIN sys.tables AS t ON t.object_id=a.object_id
WHERE b.index_id <> 0 and avg_fragmentation_in_percent <>0'
go 
update #bbc
set Action_Required ='Rebuild'
where avg_fragmentation_percent >30 
go
update #bbc
set Action_Required ='Rorganize'
where avg_fragmentation_percent <30 and avg_fragmentation_percent >5
go
SELECT * FROM #bbc ORDER BY avg_fragmentation_percent DESC
*/



--MOSTRAR INDEXS QUE PODERIAM SER CRIADOS PARA MELHORAR O DESEMPENHO
SELECT
Db_name(dm_mid.database_id) AS DatabaseName,
dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
dm_migs.last_user_seek AS Last_User_Seek,
OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '_'
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','_'),'[',''),']','') 
+ CASE
WHEN dm_mid.equality_columns IS NOT NULL
AND dm_mid.inequality_columns IS NOT NULL THEN '_'
ELSE ''
END
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
+ ']'
+ ' ON ' + dm_mid.statement
+ ' (' + ISNULL (dm_mid.equality_columns,'')
+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
IS NOT NULL THEN ',' ELSE
'' END
+ ISNULL (dm_mid.inequality_columns, '')
+ ')'
+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
ON dm_mig.index_handle = dm_mid.index_handle
--WHERE dm_mid.database_ID = DB_ID()
ORDER BY Avg_Estimated_Impact DESC
GO



--MOSTRAR ULTIMOS INDEXS CRIADOS
SELECT object_schema_name(stats.object_id) AS Object_Schema_Name,
    object_name(stats.object_id) AS Object_Name,
    indexes.name AS Index_Name, 
    STATS_DATE(stats.object_id, stats.stats_id) AS Stats_Last_Update 
FROM sys.stats
JOIN sys.indexes
    ON stats.object_id = indexes.object_id
    AND stats.name = indexes.name
ORDER BY Stats_Last_Update DESC



--REORGANIZAR UM ÍNDICE ESPECÍFICO
ALTER INDEX IX_NAME
  ON dbo.Employee  
REORGANIZE ;   
GO  

-- REORGANIZAR TODOS OS ÍNDICES DE UMA TABELA
ALTER INDEX ALL ON dbo.Employee  
REORGANIZE ;   
GO  

-- REBUILD DE UM ÍNDICE ESPECÍFICO
ALTER INDEX PK_Employee_BusinessEntityID ON dbo.Employee
REBUILD;

-- REBUILD DE TODOS ÍNDICE DE UMA TABELA
ALTER INDEX ALL ON dbo.Employee
REBUILD;
