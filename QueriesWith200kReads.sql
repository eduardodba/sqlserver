
--Extended events para coletar querys com logical reads maior que 
USE [master];
GO
CREATE EVENT SESSION [QueriesWith200kReads] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.sql_text,sqlserver.tsql_stack,sqlserver.username)
    WHERE ([logical_reads]>200000))
ADD TARGET package0.event_file(SET filename=N'C:\temp\QueriesWith200kReads.xel')
GO


--Iniciar o Evento
ALTER EVENT SESSION [QueriesWith200kReads]
ON SERVER
STATE = START;
GO



--Consultar os dados coletados
WITH CTE_ExecutedSQLStatements AS
(SELECT
	[XML Data],
	[XML Data].value('(/event[@name=''sql_statement_completed'']/@timestamp)[1]','DATETIME')	AS [Time],
	[XML Data].value('(/event/data[@name=''duration'']/value)[1]','int')						AS [Duration],
	[XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','int')						AS [CPU],
	[XML Data].value('(/event/data[@name=''logical_reads'']/value)[1]','int')					AS [logical_reads],
	[XML Data].value('(/event/data[@name=''physical_reads'']/value)[1]','int')					AS [physical_reads],
	[XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')				AS [SQL Statement]
FROM
	(SELECT 
		OBJECT_NAME				 AS [Event], 
		CONVERT(XML, event_data) AS [XML Data]
	FROM 
		sys.fn_xe_file_target_read_file
	('C:\temp\QueriesWith200kReads*.xel',NULL,NULL,NULL)) as v)
SELECT
	[SQL Statement]		AS [SQL Statement],
	SUM(Duration)		AS [Total Duration],
	SUM(CPU)			AS [Total CPU],
	SUM(Logical_Reads)	AS [Total Logical Reads],
	SUM(Physical_Reads) AS [Total Physical Reads]
FROM
	CTE_ExecutedSQLStatements
GROUP BY
	[SQL Statement]
ORDER BY
	[Total Logical Reads] DESC
GO
