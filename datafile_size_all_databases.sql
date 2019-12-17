--Listar datafiles de todas as bases
exec sp_MSForEachDB @command1=N' use ?
select SUBSTRING(db_name(),1,30);
SELECT
	size * 8 / 1024 AS size_in_mb,
    --[file_id],
	--[type],
	SUBSTRING(type_desc,1,20) as type_desc,
    --data_space_id,
    --[name],
    physical_name
	--state,
    --state_desc,
FROM
    sys.database_files AS DF;'
	



