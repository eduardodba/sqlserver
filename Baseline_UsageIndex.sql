  
-- ============================================================
-- Author     : Eduardo R Barbieri
-- Create date: 31/08/2021
-- Description: BASELINE INDEX USAGE
-- ============================================================


IF OBJECT_ID(N'dba.dbo.Baseline_UsageIndex', N'U') IS NULL
BEGIN
	CREATE TABLE dba.dbo.Baseline_UsageIndex (
		 DatabaseName varchar(100)
		,TableName varchar(200)
		,IndexName varchar(200)
		,Seeks int
		,Scans int
		,updates int
		,IndexSizeMB bigint
		,LastSeek datetime
		,LastScan datetime
		,LastUpdate datetime
		,dtColeta datetime)
	WITH (DATA_COMPRESSION = PAGE);
END


DECLARE @dbname NVARCHAR(255), @sql NVARCHAR(max)
DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
SELECT name FROM sys.databases WHERE state_desc = 'ONLINE' and database_id > 4;
OPEN c
FETCH NEXT FROM c INTO @dbname ;

WHILE @@fetch_status = 0
BEGIN
    set @sql =
    'use '+@dbname+' 
	INSERT INTO dba.dbo.Baseline_UsageIndex
	SELECT  DB_NAME() AS DatabaseName
		   ,SCHEMA_NAME(s.schema_id) +''.''+OBJECT_NAME(i.OBJECT_ID) AS TableName
		   ,i.name AS IndexName
		   ,ius.user_seeks AS Seeks
		   ,ius.user_scans AS Scans
		   ,ius.user_updates AS Updates
		   ,CASE WHEN ps.usedpages > ps.pages THEN (ps.usedpages - ps.pages) ELSE 0 
		  END * 8 / 1024 AS IndexSizeMB
		   ,ius.last_user_seek AS LastSeek
		   ,ius.last_user_scan AS LastScan
		   ,ius.last_user_update AS LastUpdate
		   ,getdate() AS dtColeta
	FROM sys.indexes i
	INNER JOIN sys.dm_db_index_usage_stats ius ON ius.index_id = i.index_id AND ius.OBJECT_ID = i.OBJECT_ID
	INNER JOIN (SELECT sch.name, sch.schema_id, o.OBJECT_ID, o.create_date FROM sys.schemas sch 
		 INNER JOIN sys.objects o ON o.schema_id = sch.schema_id) s ON s.OBJECT_ID = i.OBJECT_ID
	LEFT JOIN (SELECT OBJECT_ID, index_id, SUM(used_page_count) AS usedpages,
		    SUM(CASE WHEN (index_id < 2) 
		  THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) 
		  ELSE lob_used_page_count + row_overflow_used_page_count 
		   END) AS pages
			FROM sys.dm_db_partition_stats
			GROUP BY object_id, index_id) AS ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
	WHERE OBJECTPROPERTY(i.OBJECT_ID,''IsUserTable'') = 1
	AND ius.database_id = DB_ID() --only check indexes in current database
	AND i.type_desc = ''nonclustered'' 
	AND i.is_primary_key = 0
	AND i.is_unique_constraint = 0 
	order by Seeks,Scans'

exec (@sql);
    FETCH NEXT FROM c INTO @dbname;
END
CLOSE C
DEALLOCATE c

