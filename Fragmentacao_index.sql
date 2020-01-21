--DOWNLOAD ADVENTURE WORKS
--https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2017.bak
--REFERENCIAS
--FRAGMENTAÇÃO ENTRE 5 E 30 APLICAR REORGANIZE
--FRAGMENTAÇÃO MAIOR QUE 30 APLICAR REBUILD
--REORGANIZAR INDICES
USE AdventureWorks2017
SELECT '1' TEMPO,
c.[name] as 'Schema',
b.[name] as 'Tabela',
d.[name] as 'Indice',
a.avg_fragmentation_in_percent as PCT_Frag,
a.page_count as 'Paginas'
--INSERINDO EM TABELA TEMPORARIO
INTO #ANALISE_IX
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.tables b 
     on b.[object_id] = a.[object_id]
INNER JOIN sys.schemas c 
     on b.[schema_id] = c.[schema_id]
INNER JOIN sys.indexes AS d 
     ON d.[object_id] = a.[object_id]
	AND a.index_id = d.index_id
WHERE a.database_id = DB_ID()
AND a.avg_fragmentation_in_percent >5
AND d.[name]  IS NOT NULL
ORDER BY a.avg_fragmentation_in_percent desc

--VERIFICANDO DADOS DA TEMPO
SELECT * FROM #ANALISE_IX


--GERANDO DDL PARA RECONSTRUIR OU REORGANIZAR INDICES
SELECT 
c.[name] as 'Schema',
b.[name] as 'Tabela',
d.[name] as 'Index',
a.avg_fragmentation_in_percent as PCT_Frag,
a.page_count as 'Paginas',

--GERADNDO DDL
CASE WHEN a.avg_fragmentation_in_percent >5 
          and a.avg_fragmentation_in_percent<30
THEN  'ALTER INDEX '+d.[name]+' ON '+c.[name]+'.'+b.[name]+' REORGANIZE' 
   WHEN a.avg_fragmentation_in_percent >=30 
 THEN 'ALTER INDEX '+d.[name]+' ON '+c.[name]+'.'+b.[name]+' REBUILD' 
 ELSE ' ' END COMANDO
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.tables b 
     on b.[object_id] = a.[object_id]
INNER JOIN sys.schemas c 
     on b.[schema_id] = c.[schema_id]
INNER JOIN sys.indexes AS d 
     ON d.[object_id] = a.[object_id]
	AND a.index_id = d.index_id
WHERE a.database_id = DB_ID()
AND a.avg_fragmentation_in_percent >5
AND d.[name]  IS NOT NULL
ORDER BY a.avg_fragmentation_in_percent desc

--GERANDO INFORMAÇÃO DA FRAGMENTAÇÃO APÓS REBUILD OU REORGANIZE

--INSERINDO EM TABELA TEMPORARIO
--DROP TABLE #ANALISE_IX
INSERT INTO #ANALISE_IX
SELECT '2' AS TEMPO,
c.[name] as 'Schema',
b.[name] as 'Tabela',
d.[name] as 'indice',
a.avg_fragmentation_in_percent as PCT_Frag,
a.page_count as 'Paginas'

FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS a
INNER JOIN sys.tables b 
     on b.[object_id] = a.[object_id]
INNER JOIN sys.schemas c 
     on b.[schema_id] = c.[schema_id]
INNER JOIN sys.indexes AS d 
     ON d.[object_id] = a.[object_id]
	AND a.index_id = d.index_id
WHERE a.database_id = DB_ID()
AND a.avg_fragmentation_in_percent >5
AND d.[name]  IS NOT NULL
ORDER BY a.avg_fragmentation_in_percent desc

--COMPARANDO ANTES E DEPOIS
--SELECT * FROM #ANALISE_IX
WITH ANTES (tempo, tabela, indice,pct)
as (select a.tempo,a.tabela,a.indice, a.Pct_frag from #ANALISE_IX a
		where a.tempo='1'),
DEPOIS (tempo, tabela, indice,pct)
as (select a.tempo,a.tabela,a.indice, a.Pct_frag from #ANALISE_IX a
		where a.tempo='2')

SELECT A.TABELA, A.indice,A.PCT,B.PCT,ISNULL((B.PCT/A.PCT),100) AS REDUCAO
FROM ANTES A
LEFT JOIN DEPOIS B
ON A.TABELA=B.TABELA
AND A.indice=B.indice

--ELIMINANDO A TABELA TEMP
DROP TABLE #ANALISE_IX





--Listar todos index fragmentados de uma database
SELECT dbschemas.[name] as 'Schema',
dbtables.[name] as 'Table',
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
ORDER BY indexstats.avg_fragmentation_in_percent desc

-- adicionar clausula para buscar uma tabela em específico
-- WHERE indexstats.database_id = DB_ID() AND dbtables.[ name ] like '%%' 



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

