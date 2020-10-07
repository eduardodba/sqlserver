
SELECT pool_id
,NAME
,min_memory_percent
,max_memory_percent
,max_memory_kb / 1024 AS max_memory_in_MB
,used_memory_kb / 1024 AS used_memory_in_MB
,target_memory_kb / 1024 AS target_memory_in_MB
FROM sys.dm_resource_governor_resource_pools



SELECT d.database_id
,d.NAME AS DbName
,d.resource_pool_id AS PoolId
,p.NAME AS PoolName
,p.min_memory_percent
,p.max_memory_percent
FROM sys.databases d
LEFT OUTER JOIN sys.resource_governor_resource_pools p
ON p.pool_id = d.resource_pool_id
