--TEMPORAL TABLE

--CRIAR UMA TABELA NOVA COMO TEMPORAL
CREATE TABLE [DBO].[DEPARTAMENT] (
	[DEPTID]		INT PRIMARY KEY CLUSTERED;
	[NAME]			NVARCHAR(20) NOT NULL,
	[SYSSTARTTIME]	DATETIME2(0) GENERATED ALWAYS AS ROW START NOT NULL,
	[SYSENDTIME]	DATETIME2(0) GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME ([SYSSTARTTIME],[SYSENDTIME])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [DBO].[DEPARTAMENT_HISTORY]))
GO


--LIGAR O VERSIONAMENTO EM UMA TABELA EXISTENTE
CREATE TABLE [DBO].[EMPLOYEE] (
	[EMPLOYEEID]	INT PRIMARY KEY CLUSTERED;
	[NAME]			NVARCHAR(50) NOT NULL
	[SALARY] 		DECIMAL(10,2) NOT NULL
)
GO

/*CRIANDO OS CAMPOS COMO OCULTOS (HIDDEN)*/
ALTER TABLE [DBO].[DEPARTAMENT] ADD
[SYSSTARTTIME] DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_EMPLOYEE_SYSSTARTTIME DEFAULT '1900-01-01 00:00:00',
[SYSENDTIME] DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_EMPLOYEE_SYSENDTIME DEFAULT '9999-12-31 29:59:59',
PERIOD FOR SYSTEM_TIME ([SYSSTARTTIME],[SYSENDTIME])

ALTER TABLE [DBO].[EMPLOYEE] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [DBO].[DEPARTAMENT_HISTORY]));


--VER SE UMA TABELA É TEMPORAL E QUAL A HISTORICA DELA
SELECT A.NAME, A.OBJECT_ID, A.TEMPORAL_TYPE, A.TEMPORAL_TYPE_DESC, A.HISTORY_TABLE_ID, B.NAME
FROM SYS.TABLES A LEFT JOIN SYS.TABLES B ON B.OBJECT_ID = A.OBJECT_ID
WHERE A.TEMPORAL_TYPE IN (0,2)
GO


--SELECT EM UMA TEMPORAL TABLE
SELECT * FROM DBO.EMPLOYEE
FOR SYSTEM_TIME AS OF '2017-06-28 00:00:00.000'




/* 				LIMITAÇÕES

A Primary Key is required in the current table (System-versioned)
A History table must be created in the same database as the current table
Linked servers are not supported
INSERT and UPDATE statements cannot reference SYSTEM_TIME period columns
The Truncate table operation is not supported on temporal tables
Always On supported
A System-Versioned table does not allowed any constraints
You can’t modify the data in history table “System-Versioned”
Durable memory-optimized tables can be system-versioned
Temporal table support Partitioning and column store index */
