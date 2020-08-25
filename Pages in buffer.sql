--Mostrar Pages no Buffer / Dirty Pages / Clean Pages
SELECT
    DB_NAME(dm_os_buffer_descriptors.database_id) DatabaseName,
    COUNT(*) AS [Total Pages In Buffer],
    COUNT(*) * 8 / 1024 AS [Buffer Size in MB],
    SUM(CASE dm_os_buffer_descriptors.is_modified 
                WHEN 1 THEN 1 ELSE 0
        END) AS [Dirty Pages],
    SUM(CASE dm_os_buffer_descriptors.is_modified 
                WHEN 1 THEN 0 ELSE 1
        END) AS [Clean Pages],
    SUM(CASE dm_os_buffer_descriptors.is_modified 
                WHEN 1 THEN 1 ELSE 0
        END) * 8 / 1024 AS [Dirty Page (MB)],
    SUM(CASE dm_os_buffer_descriptors.is_modified 
                WHEN 1 THEN 0 ELSE 1
        END) * 8 / 1024 AS [Clean Page (MB)]
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.databases ON dm_os_buffer_descriptors.database_id = databases.database_id
GROUP BY DB_NAME(dm_os_buffer_descriptors.database_id)
ORDER BY [Total Pages In Buffer] DESC;


--Gravar dirty pages no disco
CHECKPOINT 

--Limpar as Clean Pages do disco
DBCC DROPCLEANBUFFERS



--Localizar Objeto por pagina	
DBCC TRACEON (3604);

--Informar o codigo da pagina
DBCC PAGE (111, 1, 2491781, 0);

--Localizar o objeto ID
SELECT OBJECT_NAME (375672386);

DBCC TRACEOFF (3604);
GO
