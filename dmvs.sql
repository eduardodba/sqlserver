--Descobrindo Quantas DMV´s seu SQL Server tem

SELECT a.name, a.type_desc
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
order by a.name

--Group by 
SELECT a.type_desc, COUNT(*) as QTD
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
group by a.type_desc

--Group by ROLLUP
SELECT ISNULL(SUBSTRING(a.name,1,CHARINDEX('_',a.name,4)-1),'Total') MOME, COUNT(*) QTD
FROM SYS.all_objects a
WHERE NAME LIKE ('dm%')
group by SUBSTRING(a.name,1,CHARINDEX('_',a.name,4)-1) with rollup
order by 1 asc





--DESCOBRINDO ID DO BANCO

SELECT * FROM sys.sysdatabases
--ENFASE ARQUIVOS DE LOG
--Este DMV retorna informações sobre os arquivos de log de transações. 
--As informações incluem o modelo de recuperação do banco de dados.
select 
	 db_NAME(database_id) dbname,
	 recovery_model,
	 current_vlf_size_mb,
	 total_vlf_count,
	 active_vlf_count,
	 active_log_size_mb,
	 log_truncation_holdup_reason,
	 log_since_last_checkpoint_mb
  from 
	sys.dm_db_log_Stats(5) --PRECISA DE PARAMETRO ID DO BANCO

--AJUSTANDO O PARAMETRO DA DMV PARA RETORNAR TODOS OS BANCOS
select 
	 A.name,
	 B.recovery_model,
	 B.current_vlf_size_mb,
	 B.total_vlf_count,
	 B.active_vlf_count,
	 B.active_log_size_mb,
	 B.log_truncation_holdup_reason,
	 B.log_since_last_checkpoint_mb
  from 
  sys.databases AS A
  CROSS APPLY sys.dm_db_log_Stats(A.database_id) B
  where A.database_id=B.database_id

--Essa exibição analisa especificamente arquivos de log virtuais ou VLFs. Eles compõem o 
--log de transações do banco de dados,ter um grande número de VLFs pode afetar 
--negativamente o tempo de inicialização e recuperação do banco de dados. , 
--Esta view retorna quantas VLFs seu banco de dados possui atualmente, 
--juntamente com seu tamanho e status.
  select 
		 db_NAME(database_id) dbname,
		 file_id,
		 vlf_begin_offset,
		 vlf_size_mb,
		 vlf_sequence_number,
		 vlf_active,
		 vlf_status
	 from 
		sys.dm_db_log_info(5) b --AJUSTANDO O PARAMETRO DA DMV PARA RETORNAR TODOS OS BANCOS

--
--A configuração correta do log de transações é crítica para o desempenho do banco de dados. 
--O log grava todas as transações antes de enviá-las para o arquivo de dados. Em muitos casos, 
--os logs de transações crescem significativamente. Gerenciar e entender como o log de transações 
--está crescendo fornece uma boa indicação sobre o desempenho do sistema. 
 
WITH DATA_VLF AS(
SELECT 
DB_ID(a.[name]) AS DatabaseID,
a.[name] AS dbName, 
CONVERT(DECIMAL(18,2), c.cntr_value/1024.0) AS [Log Size (MB)],
CONVERT(DECIMAL(18,2), b.cntr_value/1024.0) AS [Log Size Used (MB)]
FROM sys.databases AS a WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS b  WITH (NOLOCK) ON a.name = b.instance_name
INNER JOIN sys.dm_os_performance_counters AS c WITH (NOLOCK) ON a.name = c.instance_name
WHERE b.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND c.counter_name LIKE N'Log File(s) Size (KB)%'
AND c.cntr_value > 0 
)

SELECT	[dbName],
		[Log Size (MB)], 
		[Log Size Used (MB)], 
		[Log Size (MB)]-[Log Size Used (MB)] [Log Free (MB)], 
		cast([Log Size Used (MB)]/[Log Size (MB)]*100 as decimal(10,2)) [Log Space Used %],
		COUNT(b.database_id) AS [Number of VLFs] ,
		sum(case when b.vlf_status = 0 then 1 else 0 end) as Free,
		sum(case when b.vlf_status != 0 then 1 else 0 end) as InUse		
FROM DATA_VLF AS a  
CROSS APPLY sys.dm_db_log_info(a.DatabaseID) b
GROUP BY dbName, [Log Size (MB)],[Log Size Used (MB)]


--DBCC PARA LOGS
--POR BANCO DE DADOS
DBCC LOGINFO





-- Conexões ativas
SELECT datediff(MINUTE,a.connect_time,GETDATE()) minutos_conectado, a.* 
FROM sys.dm_exec_connections a
 
-- Sessões ativas
SELECT datediff(MINUTE,a.login_time,GETDATE()) minutos_conectado,a.* 
FROM sys.dm_exec_sessions a
 
-- Requisições solicitadas
SELECT * FROM sys.dm_exec_requests





SELECT TOP 1* FROM CLIENTE
GO 1000

--Identificando tabelas e indices mais usados 
SELECT B.NAME AS TABLE_NAME,C.NAME AS INDEX_NAME,*
FROM SYS.DM_DB_INDEX_USAGE_STATS A
INNER JOIN SYSOBJECTS B
ON B.ID = A.OBJECT_ID
INNER JOIN SYS.INDEXES C
ON A.OBJECT_ID = C.OBJECT_ID
ORDER BY user_scans DESC


--Query para identificar "Querys" pesadas com relação a tempo.
SELECT TOP 100
    DB_NAME(C.[dbid]) as Banco_dados,
    B.text,
    (SELECT CAST(SUBSTRING(B.[text], (A.statement_start_offset/2)+1,   
        (((CASE A.statement_end_offset  
            WHEN -1 THEN DATALENGTH(B.[text]) 
            ELSE A.statement_end_offset  
        END) - A.statement_start_offset)/2) + 1) AS NVARCHAR(MAX)) FOR XML PATH(''), TYPE) AS [TSQL],
    C.query_plan,
	--Tempo
    A.last_execution_time,
    A.execution_count,
	--Tempo Decorrido
    A.total_elapsed_time / 1000 AS total_elapsed_time_ms,
    A.last_elapsed_time / 1000 AS last_elapsed_time_ms,
    A.min_elapsed_time / 1000 AS min_elapsed_time_ms,
    A.max_elapsed_time / 1000 AS max_elapsed_time_ms,
    ((A.total_elapsed_time / A.execution_count) / 1000) AS avg_elapsed_time_ms,
	--Tempo Total Trabalhado
    A.total_worker_time / 1000 AS total_worker_time_ms,
    A.last_worker_time / 1000 AS last_worker_time_ms,
    A.min_worker_time / 1000 AS min_worker_time_ms,
    A.max_worker_time / 1000 AS max_worker_time_ms,
    ((A.total_worker_time / a.execution_count) / 1000) AS avg_worker_time_ms,
    --Leitura Fisica
    A.total_physical_reads,
    A.last_physical_reads,
    A.min_physical_reads,
    A.max_physical_reads,
   --Leitura Logica
    A.total_logical_reads,
    A.last_logical_reads,
    A.min_logical_reads,
    A.max_logical_reads,
   --Escrita Logica
    A.total_logical_writes,
    A.last_logical_writes,
    A.min_logical_writes,
    A.max_logical_writes
FROM
    sys.dm_exec_query_stats A
    CROSS APPLY sys.dm_exec_sql_text(A.[sql_handle]) B
    OUTER APPLY sys.dm_exec_query_plan (A.plan_handle) AS C
	WHERE C.[dbid]=DB_ID()
ORDER BY
    A.total_elapsed_time DESC

