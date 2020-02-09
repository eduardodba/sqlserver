--PARA UMA DATABASE
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




/* PARA TODAS AS BASES DA INSTÂNCIA
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
select * from #bbc
*/



--reorganizar um índice específico
ALTER INDEX IX_NAME
  ON dbo.Employee  
REORGANIZE ;   
GO  

-- reorganizar todos os índices de uma tabela
ALTER INDEX ALL ON dbo.Employee  
REORGANIZE ;   
GO  

-- rebuild de um índice específico
ALTER INDEX PK_Employee_BusinessEntityID ON dbo.Employee
REBUILD;

-- rebuild de todos índice de uma tabela
ALTER INDEX ALL ON dbo.Employee
REBUILD;

