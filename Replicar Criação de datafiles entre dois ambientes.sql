IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('sp_replica_datafiles'))
   exec('CREATE PROCEDURE sp_replica_datafiles AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE sp_replica_datafiles AS
BEGIN
	
	
	-- ====================================================================
	-- Author     : Eduardo R Barbieri
	-- Create date: 04/08/2021
	-- Description: REPLICAR DATAFILES CRIADOS NO ORIGINAL PARA A REPLICA
	-- Description: CRIAR UM JOB PARA EXECUTAR ESSA PROC EM UM SERVER QUE 
	-- TENHA COMUNICACAO COM OS DOIS AMBIENTES
	-- ====================================================================

	IF OBJECT_ID('tempdb..#TABLE_FILEGROUPS_REPLICA') IS NOT NULL DROP TABLE #TABLE_FILEGROUPS_REPLICA
	CREATE TABLE  #TABLE_FILEGROUPS_REPLICA  (  [database] sysname, [filegroup_id] int, [filegroup_name] sysname )
	EXEC  sp_msforeachdb  'use ? 
		insert into #TABLE_FILEGROUPS_REPLICA select db_name(), groupid, groupname  from sys.sysfilegroups'
	
	IF OBJECT_ID('tempdb..#TABLE_DATAFILES_REPLICA') IS NOT NULL DROP TABLE #TABLE_DATAFILES
	SELECT a.name AS [BD]
		 ,b.filename as [UNIDADE]
		 ,SUM(b.size/128*1024) as [SIZE]
		 ,b.name as [DATAFILE]
		 ,case when len (replace ( b .filename ,'ldf', '')) <> LEN (b .filename) then 'log' else 'dados' end [TIPO]
		 ,b.groupid 
	INTO #TABLE_DATAFILES_REPLICA
	from [REPLICA].master.dbo.sysdatabases a 
	left join [REPLICA].master.dbo.sysaltfiles b on a.dbid = b.dbid
	group by a.name,b.filename,b.name, b.groupid
	
	SELECT CASE WHEN TIPO = 'dados' THEN 'ALTER DATABASE ['+BD+'] ADD FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB ) TO FILEGROUP [' +f.[filegroup_name]+ ']'
		   ELSE 'ALTER DATABASE ['+BD+'] ADD LOG FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB )'
		   END AS SCRIPT, BD, UNIDADE, DATAFILE, TIPO
	INTO #TABLE_REPLICA
	FROM #TABLE_DATAFILES_REPLICA 
	INNER JOIN #TABLE_FILEGROUPS_REPLICA f ON f.[database]=BD and f.[filegroup_id]=groupid
	ORDER BY BD
	
	
	
	--CARREGAR DADOS PANCRED
	IF OBJECT_ID('tempdb..#TABLE_FILEGROUPS_ORIGINAL') IS NOT NULL DROP TABLE #TABLE_FILEGROUPS_ORIGINAL
	CREATE TABLE  #TABLE_FILEGROUPS_ORIGINAL  (  [database] sysname, [filegroup_id] int, [filegroup_name] sysname )
	EXEC  sp_msforeachdb  'use ?
		insert into #TABLE_FILEGROUPS_ORIGINAL select db_name(), groupid, groupname  from sys.sysfilegroups'
	
	IF OBJECT_ID('tempdb..#TABLE_DATAFILES_ORIGINAL') IS NOT NULL DROP TABLE #TABLE_DATAFILES_ORIGINAL
	SELECT a.name AS [BD]
		 ,b.filename as [UNIDADE]
		 ,SUM(b.size/128*1024) as [SIZE]
		 ,b.name as [DATAFILE]
		 ,case when len (replace ( b .filename ,'ldf', '')) <> LEN (b .filename) then 'log' else 'dados' end [TIPO]
		 ,b.groupid 
	INTO #TABLE_DATAFILES_ORIGINAL
	from [ORIGINAL].master.dbo.sysdatabases a 
	left join [ORIGINAL].master.dbo.sysaltfiles b on a.dbid = b.dbid
	group by a.name,b.filename,b.name, b.groupid
	
	SELECT CASE WHEN TIPO = 'dados' THEN 'ALTER DATABASE ['+BD+'] ADD FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB ) TO FILEGROUP [' +f.[filegroup_name]+ ']'
		   ELSE 'ALTER DATABASE ['+BD+'] ADD LOG FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 65536KB )'
		   END AS SCRIPT, BD, UNIDADE, DATAFILE, TIPO
	INTO #TABLE_ORIGINAL
	FROM #TABLE_DATAFILES_ORIGINAL
	INNER JOIN #TABLE_FILEGROUPS_ORIGINAL f ON f.[database]=BD and f.[filegroup_id]=groupid
	ORDER BY BD
	
		 
	--INSERIR VALORES NO REPLICA
	INSERT INTO [REPLICA].master.dbo.TABLE_DATAFILES
	SELECT p.SCRIPT,p.BD FROM #TABLE_ORIGINAL p
	INNER JOIN(
		SELECT pa.BD,pa.UNIDADE,pa.DATAFILE,pa.TIPO FROM #TABLE_ORIGINAL pa EXCEPT SELECT pr.BD,pr.UNIDADE,pr.DATAFILE,pr.TIPO FROM #TABLE_REPLICA pr) a
		ON p.UNIDADE=a.UNIDADE
 
END







IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('sp_cria_datafiles'))
   exec('CREATE PROCEDURE sp_cria_datafiles AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE sp_cria_datafiles AS
BEGIN
	-- ====================================================================
	-- Author     : Eduardo R Barbieri
	-- Create date: 04/08/2021
	-- Description: REPLICAR DATAFILES CRIADOS NO ORIGINAL PARA A REPLICA
	-- Description: CRIAR UM JOB QUE EXECUTE ESSA PROC NO SERVIDOR REPLICA
	-- ====================================================================
	 
	DECLARE @script nvarchar(max)
	DECLARE datafiles_cursor CURSOR FAST_FORWARD
	FOR SELECT SCRIPT FROM master.dbo.TABLE_DATAFILES b INNER JOIN (select name,state_desc from sys.databases where state_desc='ONLINE' and database_id > 4) a ON a.name=b.bd
	OPEN datafiles_cursor;
	WHILE 1 = 1
	BEGIN
	FETCH NEXT FROM datafiles_cursor INTO @script;
	IF @@FETCH_STATUS = -1 BREAK ;
		--select @script
		EXEC (@script)
	END
	CLOSE datafiles_cursor;
	DEALLOCATE datafiles_cursor;

	TRUNCATE TABLE master.dbo.TABLE_DATAFILES
END
