--db_name 	  Tabela	  Numero_Linhas	    Tabela_KB	Index_KB	    Total_KB	    Percentual	    Database_KB	    Ultima_alteracao	    ultima_leitura

--create table dba.dbo.spaceused (Servidor sysname,[Database] sysname,Tabela varchar(128), Numero_Linhas bigint, Tabela_KB bigint, Index_KB bigint, Total_KB bigint, Percentual decimal(15,2), Database_KB decimal(15,2), Ultima_alteracao datetime, ultima_leitura datetime)

truncate table dba.dbo.spaceused
DECLARE @dbname NVARCHAR(255), @sql NVARCHAR(max)
DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
SELECT name FROM sys.databases 
WHERE state_desc = 'ONLINE' and database_id>4;
OPEN c
FETCH NEXT FROM c INTO @dbname ;

WHILE @@fetch_status = 0
BEGIN
    set @sql =
    'use '+@dbname+'
	
if OBJECT_ID(''tempdb..#temp'') is not null
	    drop table #temp
CREATE TABLE #temp(
db_name varchar(50),
tbl_id int IDENTITY (1, 1),
tbl_name varchar(128),
rows_num int,
total_size varchar(20),
data_space varchar(20),
index_space varchar(20),
unused varchar(20),
percent_of_db decimal(15,2),
db_size decimal(15,2))
EXEC sp_msforeachtable @command1="insert into #temp(tbl_name,rows_num, total_size, data_space, index_space, unused) exec sp_spaceused ''?''",
@command2="update #temp set tbl_name = ''?'' where tbl_id = (select max(tbl_id) from #temp)"
UPDATE #temp
SET db_name = '''+@dbname+'''
UPDATE #temp
SET total_size = SUBSTRING(total_size,1, LEN(total_size)-3),
	data_space = SUBSTRING(data_space,1, LEN(data_space)-3),
	index_space = SUBSTRING(index_space,1, LEN(index_space)-3),
	unused = SUBSTRING(unused,1, LEN(unused)-3)
	
UPDATE #temp
SET db_size = (SELECT SUM(CAST(data_space as decimal(15,2))) FROM #temp)
UPDATE #temp
SET percent_of_db = (total_size/db_size) * 100;
update #temp
SET db_size = (SELECT CAST(SUM(size) * 8. / 1024 AS DECIMAL(15,2)) FROM sys.master_files WHERE database_id = DB_ID());
WITH temp_table(tbl_name,idx_name,last_user_update,user_updates,last_user_seek,last_user_scan,last_user_lookup,user_seeks,user_scans,user_lookups)
AS(
SELECT 
''['' + schema_name(tbl.schema_id) + ''].[''+object_name(ius.object_id)+'']''
,six.name
,ius.last_user_update
,ius.user_updates
,ius.last_user_seek
,ius.last_user_scan
,ius.last_user_lookup
,ius.user_seeks
,ius.user_scans
,ius.user_lookups
FROM
sys.dm_db_index_usage_stats ius 
INNER JOIN sys.tables tbl ON (tbl.OBJECT_ID = ius.OBJECT_ID)
INNER JOIN sys.indexes six ON six.index_id = ius.index_id and six.object_id = tbl.OBJECT_ID
WHERE ius.database_id = DB_ID()
)
insert into dba.dbo.spaceused 
select	'''+@@SERVERNAME+'''
		,t1.db_name 
		,t1.tbl_name as Tabela
		,t1.rows_num as Numero_Linhas
		,t1.data_space as Tabela_KB
		,t1.index_space as Index_KB
		,t1.total_size as Total_KB
		,t1.percent_of_db as Percentual
		,t1.db_size  * 1024 as Database_KB
		,t2.last_user_update as Ultimo_alteracao
		,CASE WHEN t2.last_user_seek > t2.last_user_scan THEN t2.last_user_seek
			 WHEN t2.last_user_scan > t2.last_user_seek THEN t2.last_user_scan
			 ELSE t2.last_user_scan END Ultima_leitura
from #temp t1 LEFT JOIN temp_table t2 ON t1.tbl_name = t2.tbl_name
ORDER BY t1.percent_of_db DESC'

exec (@sql);
    FETCH NEXT FROM c INTO @dbname;
END
CLOSE C
DEALLOCATE c

select * from dba.dbo.spaceused 
