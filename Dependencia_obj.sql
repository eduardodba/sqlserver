--VER OBJETOS REFERENCIADOS EM UMA VIEW, PROCEDURE, ETC.
/*
FN	SQL_SCALAR_FUNCTION
UQ	UNIQUE_CONSTRAINT
SQ	SERVICE_QUEUE
F 	FOREIGN_KEY_CONSTRAINT
U 	USER_TABLE
D 	DEFAULT_CONSTRAINT
PK	PRIMARY_KEY_CONSTRAINT
V 	VIEW
S 	SYSTEM_TABLE
IT	INTERNAL_TABLE
P 	SQL_STORED_PROCEDURE
TF	SQL_TABLE_VALUED_FUNCTION
*/


USE Credito
GO
SELECT referencing_id, 
OBJECT_SCHEMA_NAME(referencing_id) +'-'+ OBJECT_NAME(referencing_id) AS referencing_object_name,
obj.type_desc as referenced_object_type,
referenced_schema_name + '-' + 
referenced_entity_name AS referenced_object_name
FROM sys.sql_expression_dependencies as sed
INNER JOIN sys.objects as obj ON sed.referencing_id=obj.object_id
WHERE referencing_id IN (SELECT object_id FROM sys.objects WHERE type='P')
ORDER BY referenced_object_name
GO




--Para exibir os objetos que dependem de uma tabela
USE BD_ARS;
GO  
SELECT * FROM sys.sql_expression_dependencies  
WHERE referencing_id = OBJECT_ID(N'dbo.TB_Postagem');   
GO


--Para exibir os objetos dos quais uma tabela depende
USE BD_ARS;    
GO  
SELECT * FROM sys.sql_expression_dependencies  
WHERE referenced_id = OBJECT_ID(N'dbo.TB_Postagem');   
GO  


