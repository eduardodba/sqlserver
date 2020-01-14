--DMV's AlwaysOn
/*sys.dm_hadr_auto_page_repair
sys.dm_hadr_availability_group_states
sys.dm_hadr_availability_replica_cluster_states
sys.dm_hadr_availability_replica_states
sys.dm_hadr_availability_replica_cluster_nodes
sys.dm_hadr_cluster
sys.dm_hadr_cluster_members
sys.dm_hadr_cluster_networks
sys.dm_hadr_database_replica_cluster_states
sys.dm_hadr_database_replica_states
sys.dm_hadr_instance_node_map
sys.dm_hadr_name_id_map
sys.dm_tcp_listener_states
sys.availability_groups
sys.availability_groups_cluster
sys.availability_replicas
sys.availability_group_listener_ip_addresses
sys.availability_group_listeners
*/


--SERVERNAME, DATABASE, AG, SINCRONIZAÇÃO
SELECT 
	ar.replica_server_name, 
	adc.database_name, 
	ag.name AS AG_NAME,
	(CASE drs.is_primary_replica
        WHEN 0 THEN 'SECUNDARIA'
        WHEN 1 THEN 'PRIMARIA'
    END) as sincronizacao_status, 
	drs.synchronization_state_desc 
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
ORDER BY 
	adc.database_name,
	ag.name, 
	ar.replica_server_name;
	
	
	



--Nós do cluster e status
select member_name
	,member_type_desc
	,(CASE member_state
        WHEN 0 THEN 'Offline'
        WHEN 1 THEN 'Online'
    END)
	,member_state_desc
from sys.dm_hadr_cluster_members



--Grup_name, node_name
select distinct(group_name)
		,node_name 
from sys.dm_hadr_availability_replica_cluster_nodes




--Database e Status
select database_name
	  ,(CASE is_failover_ready
        WHEN 0 THEN 'Sincronizando'
        WHEN 1 THEN 'Sincronizado'
    END) as Status -- Indica se o banco de dados secundário está sincronizado com o banco de dados primário
from sys.dm_hadr_database_replica_cluster_states







--Repica_name, Database, Ag_name, Sincronização Status
SELECT 
	ar.replica_server_name, 
	adc.database_name, 
	ag.name AS ag_name, 
	drs.is_local, 
	drs.is_primary_replica, 
	drs.synchronization_state_desc, 
	drs.is_commit_participant, 
	drs.synchronization_health_desc, 
	drs.recovery_lsn, 
	drs.truncation_lsn, 
	drs.last_sent_lsn, 
	drs.last_sent_time, 
	drs.last_received_lsn, 
	drs.last_received_time, 
	drs.last_hardened_lsn, 
	drs.last_hardened_time, 
	drs.last_redone_lsn, 
	drs.last_redone_time, 
	drs.log_send_queue_size, 
	drs.log_send_rate, 
	drs.redo_queue_size, 
	drs.redo_rate, 
	drs.filestream_send_rate, 
	drs.end_of_log_lsn, 
	drs.last_commit_lsn, 
	drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
ORDER BY 
	adc.database_name,
	ag.name, 
	ar.replica_server_name;
	
	
	
--NAME,SERVER NAME, ROLE_DESC(PRIMARY)
IF SERVERPROPERTY ('IsHadrEnabled') = 1
BEGIN
SELECT
   AGC.name -- Availability Group
 , RCS.replica_server_name -- SQL cluster node name
 , ARS.role_desc  -- Replica Role
FROM
 sys.availability_groups_cluster AS AGC
  INNER JOIN sys.dm_hadr_availability_replica_cluster_states AS RCS
   ON
    RCS.group_id = AGC.group_id
  INNER JOIN sys.dm_hadr_availability_replica_states AS ARS
   ON
    ARS.replica_id = RCS.replica_id
WHERE
 ARS.role_desc = 'PRIMARY'
END
	
	
	
	
--LIST ENDPOINT Hadr_endpoint
SELECT port, NAME FROM sys.tcp_endpoints where name ='Hadr_endpoint';  



--synchronization_health_desc, replica_server_name
IF SERVERPROPERTY ('IsHadrEnabled') = 1
BEGIN
SELECT
	DISTINCT(HDR.synchronization_health_desc)
   ,RCS.replica_server_name 
FROM
  sys.dm_hadr_availability_replica_cluster_states AS RCS
  INNER JOIN sys.dm_hadr_availability_replica_states AS ARS
   ON
    ARS.replica_id = RCS.replica_id
	INNER JOIN sys.dm_hadr_database_replica_states AS HDR
	ON ARS.replica_id = HDR.replica_id
WHERE
 ARS.role_desc = 'PRIMARY'
END
	
