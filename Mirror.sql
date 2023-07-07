-- Ver sincronização do mirror
SELECT databases.name AS DatabaseName,
       database_mirroring.mirroring_state_desc,
       database_mirroring.mirroring_role_desc,
       database_mirroring.mirroring_safety_level,
       database_mirroring.mirroring_safety_level_desc,
       database_mirroring.mirroring_safety_sequence,
    database_mirroring.mirroring_witness_name,
    database_mirroring.mirroring_witness_state,
    database_mirroring.mirroring_witness_state_desc   
FROM sys.database_mirroring    
INNER JOIN sys.databases
ON databases.database_id=database_mirroring.database_id
where databases.database_id>4


--Failover mirror 
ALTER DATABASE MirrorDB SET PARTNER FAILOVER
