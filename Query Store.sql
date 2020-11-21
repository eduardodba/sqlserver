--Estudo Query store

--Criar uma base para estudo
CREATE DATABASE [qstore_demo]
 ON  PRIMARY 
( NAME = N'qs_demo', FILENAME = N'H:\qs_demo.mdf' , SIZE = 102400KB , 
		MAXSIZE = 1024000KB , FILEGROWTH = 20480KB )
 LOG ON 
( NAME = N'qs_demo_log', FILENAME = N'H:\qs_demo_log.ldf' , SIZE = 20480KB , 
		MAXSIZE = 1024000KB , FILEGROWTH = 20480KB )
GO
ALTER DATABASE [qstore_demo] SET AUTO_UPDATE_STATISTICS OFF 
GO
ALTER DATABASE [qstore_demo] SET AUTO_CREATE_STATISTICS OFF 
GO
ALTER DATABASE [qstore_demo] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [qstore_demo] SET QUERY_STORE = OFF
GO



USE qstore_demo
GO

-- create a table
CREATE TABLE dbo.db_store (c1 CHAR(3) NOT NULL, c2 CHAR(3) NOT NULL, c3 SMALLINT NULL)
GO

-- create a stored procedure
CREATE PROC dbo.proc_1 @par1 SMALLINT
AS 
SET NOCOUNT ON
SELECT c1, c2 FROM dbo.db_store
WHERE c3 = @par1
GO


-- populate the table (this may take a couple of minutes)
SET NOCOUNT ON
INSERT INTO [dbo].db_store (c1,c2,c3) SELECT '18','2f',2
go 20000
INSERT INTO [dbo].db_store (c1,c2) SELECT '171','1ff'
go 4000  
INSERT INTO [dbo].db_store (c1,c2,c3) SELECT '172','1ff',0
go 10
INSERT INTO [dbo].db_store (c1,c2,c3)   SELECT '172','1ff',4 
go 15000



-- enable Query Store on the database
ALTER DATABASE [qstore_demo] SET QUERY_STORE = ON
GO


EXEC dbo.proc_1 0
GO 30



CREATE NONCLUSTERED INDEX NCI_1
ON dbo.db_store (c3)
GO


EXEC dbo.proc_1 0
GO 20



CREATE NONCLUSTERED INDEX NCI_2
ON dbo.db_store (c3, c1)
GO


EXEC dbo.proc_1 0
GO 20




UPDATE  dbo.db_store SET c1  ='1' WHERE c3 = '0'
UPDATE  dbo.db_store SET c2  ='3ff' WHERE c3 = '1'
DELETE FROM dbo.db_store  WHERE c3 = 3
INSERT INTO  dbo.db_store (c1,c2,c3) SELECT '173','1fa',0
GO 5


EXEC dbo.proc_1 0
GO 20



--EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 13;



CREATE NONCLUSTERED INDEX NCI_3
ON dbo.db_store (c3)
INCLUDE (c1,c2)



--EXEC sp_query_store_unforce_plan @query_id = 1, @plan_id = 13
GO


EXEC dbo.proc_1 0
GO
