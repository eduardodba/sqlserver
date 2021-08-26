-- ================================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 22/08/2021
-- Description: Exibir tamanho da base / tabela, ultima leitura e ultima escrita
-- ================================================================================

IF OBJECT_ID(N'dba.dbo.spaceused', N'U') IS NOT NULL
   DROP TABLE dba.dbo.spaceused; 
GO

create table dba.dbo.spaceused (
 Servidor sysname
,[Database] sysname
,Tabela varchar(128)
,Numero_Linhas bigint
,Tabela_MB decimal(15,2)
,Index_MB decimal(15,2)
,Total_MB decimal(15,2)
,Percentual decimal(15,2)
,Database_MB decimal(15,2)
,Ultima_alteracao datetime
,ultima_leitura datetime)

DECLARE @dbname NVARCHAR(255), @sql1 NVARCHAR(max), @sql2 NVARCHAR(max)
DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
SELECT name FROM sys.databases WHERE state_desc = 'ONLINE' and database_id > 4;
OPEN c
FETCH NEXT FROM c INTO @dbname ;

WHILE @@fetch_status = 0
BEGIN
    set @sql1 =
    'use '+@dbname+'         
	if OBJECT_ID(''tempdb..#temp'') is not null
	drop table #temp
		CREATE TABLE #temp(
		db_name varchar(50),
		tbl_id int ,
		tbl_name varchar(128),
		rows_num bigint,
		total_size decimal(15,2),
		data_space decimal(15,2),
		index_space decimal(15,2),
		db_size decimal(15,2),
		percent_of_db decimal(15,2))

	if object_id(''Tempdb..#tabelas'') is not null
		drop table #tabelas

	;with table_space_usage (table_Name,index_Name,used,reserved,ind_rows,tbl_rows,type_Desc)
	AS(
	select ''[''+s.name+''].[''+o.name+'']''
		,coalesce(i.name,''heap'')
		,p.used_page_Count * 8. / 1024
		,p.reserved_page_count * 8. / 1024
		,p.row_count 
		,case when i.index_id in (0,1) then p.row_count else 0 end
		,i.type_Desc
	from sys.dm_db_partition_stats p with (nolock)
	join sys.objects o with (nolock) on o.object_id = p.object_id
	join sys.schemas s with (nolock) on s.schema_id = o.schema_id
	left join sys.indexes i with (nolock) on i.object_id = p.object_id and i.index_id = p.index_id
	where o.type_desc = ''user_Table'' and o.is_Ms_shipped = 0)
	
	select  t.table_Name,
			t.index_name,
			sum(t.used) as used_in_kb,
		    sum(t.reserved) as reserved_in_kb,
			case grouping (t.index_name) when 0 then sum(t.ind_rows) else sum(t.tbl_rows) end as rows,
			type_Desc
	into #tabelas
	from table_space_usage t with (nolock)
	group by t.table_Name,t.index_Name,type_Desc
	with rollup order by grouping(t.table_Name),t.table_Name,
	grouping(t.index_Name),t.index_name
	
	if object_id(''Tempdb..#Resultado_Final'') is not null
		drop table #Resultado_Final'

set @sql2 ='
insert into #temp (tbl_name, rows_num, total_size, data_space, index_space)
	select Table_Name tbl_name
		,max(rows) rows_num 
		,sum(reserved_in_kb) [total_size]
		,sum(case when Type_Desc in (''CLUSTERED'',''HEAP'') then reserved_in_kb else 0 end) [data_space]
		,sum(case when Type_Desc in (''NONCLUSTERED'') then reserved_in_kb else 0 end) [index_space]
	from #tabelas
	where index_Name is not null and Type_Desc is not null
	group by  Table_Name
	order by 3 desc

	UPDATE #temp SET db_name = '''+@dbname+'''
	
	UPDATE #temp SET total_size = total_size,
								  data_space = data_space,
								  index_space = index_space

	UPDATE #temp SET db_size = (SELECT SUM(CAST(data_space as decimal(15,2))) FROM #temp)
	
	update #temp SET db_size = (SELECT CAST(SUM(size) * 8. / 1024 AS DECIMAL(15,2)) FROM sys.master_files WHERE database_id = DB_ID());
	
	update #temp SET percent_of_db = (total_size/db_size) * 100;

	WITH temp_table(tbl_name,idx_name,last_user_update,user_updates,last_user_seek,last_user_scan)
	AS(
	SELECT
		''['' + schema_name(tbl.schema_id) + ''].[''+object_name(ius.object_id)+'']''
		,six.name
		,ius.last_user_update
		,ius.user_updates
		,ius.last_user_seek
		,ius.last_user_scan
	FROM sys.dm_db_index_usage_stats ius with(nolock)
	INNER JOIN sys.tables tbl with(nolock) ON (tbl.OBJECT_ID = ius.OBJECT_ID)
	INNER JOIN sys.indexes six with(nolock) ON six.index_id = ius.index_id and six.object_id = tbl.OBJECT_ID
	WHERE ius.database_id = DB_ID()
	)

	insert into dba.dbo.spaceused
	select	'''+@@SERVERNAME+''' as [Servidor]
			,t1.db_name as [Database]
			,t1.tbl_name as [Tabela]
			,t1.rows_num as [Numero_Linhas]
			,t1.data_space as [Tabela_MB]
			,t1.index_space as [Index_MB]
			,t1.total_size as [Total_MB]
			,t1.percent_of_db as [Percentual]
			,t1.db_size as [Database_MB]
			,MAX(t2.last_user_update) as [Ultima_alteracao]
			,CASE WHEN MAX(t2.last_user_seek) > MAX(t2.last_user_scan) THEN MAX(t2.last_user_seek)
			WHEN MAX(t2.last_user_scan) > MAX(t2.last_user_seek) THEN MAX(t2.last_user_scan)
			ELSE MAX(t2.last_user_scan) END [ultima_leitura]
from #temp t1 LEFT JOIN temp_table t2 with(nolock) ON t1.tbl_name = t2.tbl_name
GROUP BY						t1.db_name
                               ,t1.tbl_name
                               ,t1.rows_num
                               ,t1.data_space
                               ,t1.index_space
                               ,t1.total_size
                               ,t1.percent_of_db
                               ,t1.db_size'


exec (@sql1+@sql2);
    FETCH NEXT FROM c INTO @dbname;
END
CLOSE C
DEALLOCATE c

select * from dba.dbo.spaceused order by Total_MB desc
