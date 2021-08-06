-- ====================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 04/08/2021
-- Description: REPLICAR DATAFILES CRIADOS NO ORIGINAL PARA A REPLICA
-- Description: CRIAR UM JOB PARA EXECUTAR ESSA PROC EM UM SERVER QUE 
-- TENHA COMUNICACAO COM OS DOIS AMBIENTES
-- ====================================================================


--CARREGAR DADOS DO SERVER REPLICA

IF OBJECT_ID('tempdb..#TABLE_FILEGROUPS_REPLICA') IS NOT NULL DROP TABLE #TABLE_FILEGROUPS_REPLICA
	CREATE TABLE  #TABLE_FILEGROUPS_REPLICA  (  [database] sysname, [filegroup_id] int, [filegroup_name] sysname )
GO


declare @db sysname, @cmd nvarchar(max)

--Obter os filegroups existes em todas as bases
declare cursorDB cursor fast_forward for
select name from [REPLICA].master.sys.databases where state_desc = 'ONLINE' and database_id > 4
open cursorDB
fetch next from cursorDB into @db
while @@FETCH_STATUS <> -1
begin
set @cmd = '
	insert into #TABLE_FILEGROUPS_REPLICA  select ''' +@db+ ''' as DB, groupid, groupname from [REPLICA].' +@db+ '.sys.sysfilegroups'
exec (@cmd)
    fetch next from cursorDB into @db
end
close cursorDB
deallocate cursorDB
GO


--Obter DB, caminho, tamanho, dataile e tipo para usar na criação dos comandos
IF OBJECT_ID('tempdb..#TABLE_DATAFILES_REPLICA') IS NOT NULL DROP TABLE #TABLE_DATAFILES_REPLICA
SELECT a.name AS [BD]
	 ,b.filename as [UNIDADE]
	 ,SUM(b.size/128*1024) as [SIZE]
	 ,b.name as [DATAFILE]
	 ,case when len (replace ( b .filename ,'ldf', '')) <> LEN (b .filename) then 'log' else 'dados' end [TIPO]
	 ,b.groupid 
INTO #TABLE_DATAFILES_REPLICA
from [REPLICA].master.dbo.sysdatabases a 
left join [REPLICA].master.dbo.sysaltfiles b on a.dbid = b.dbid 
inner join [REPLICA].master.sys.databases s on s.database_id=b.dbid
where s.state_desc = 'ONLINE' and s.database_id > 4
group by a.name,b.filename,b.name, b.groupid
GO


--Gerar o script para arquivos de dados, utilizando filegroup_name obtido na primeira consulta
IF OBJECT_ID('tempdb..#TABLE_REPLICA') IS NOT NULL DROP TABLE #TABLE_REPLICA
SELECT	'ALTER DATABASE ['+BD+'] ADD FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 524288KB ) TO FILEGROUP [' +f.[filegroup_name]+ ']' AS SCRIPT
		,BD
		,UNIDADE
		,DATAFILE
		,TIPO
INTO #TABLE_REPLICA
FROM #TABLE_DATAFILES_REPLICA 
INNER JOIN #TABLE_FILEGROUPS_REPLICA f ON f.[database]=BD and f.[filegroup_id]=groupid
WHERE TIPO ='dados'
ORDER BY BD
GO


--Gerar o script para os arquivos de log
INSERT INTO #TABLE_REPLICA 
SELECT	'ALTER DATABASE ['+BD+'] ADD LOG FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 204800KB )' AS SCRIPT
		,BD
		,UNIDADE
		,DATAFILE
		,TIPO
FROM #TABLE_DATAFILES_REPLICA 
WHERE TIPO ='log'
GO




--CARREGAR DADOS DO SERVER ORIGINAL

IF OBJECT_ID('tempdb..#TABLE_FILEGROUPS_ORIGINAL') IS NOT NULL DROP TABLE #TABLE_FILEGROUPS_ORIGINAL
	CREATE TABLE  #TABLE_FILEGROUPS_ORIGINAL  (  [database] sysname, [filegroup_id] int, [filegroup_name] sysname )
GO

declare @db sysname, @cmd nvarchar(max)

--Obter os filegroups existes em todas as bases
declare cursorDB cursor fast_forward for
select name from [ORIGINAL].master.sys.databases where state_desc = 'ONLINE' and database_id > 4
open cursorDB
fetch next from cursorDB into @db
while @@FETCH_STATUS <> -1
begin
set @cmd = '
	insert into #TABLE_FILEGROUPS_ORIGINAL  select ''' +@db+ ''' as DB, groupid, groupname from [ORIGINAL].' +@db+ '.sys.sysfilegroups'
exec (@cmd)
    fetch next from cursorDB into @db
end
close cursorDB
deallocate cursorDB
GO


--Obter DB, caminho, tamanho, dataile e tipo para usar na criação dos comandos
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
inner join [ORIGINAL].master.sys.databases s on s.database_id=b.dbid
where s.state_desc = 'ONLINE' and s.database_id > 4
group by a.name,b.filename,b.name, b.groupid
GO


--Gerar o script para arquivos de dados, utilizando filegroup_name obtido na primeira consulta
SELECT	'ALTER DATABASE ['+BD+'] ADD FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 524288KB ) TO FILEGROUP [' +f.[filegroup_name]+ ']' AS SCRIPT
		,BD
		,UNIDADE
		,DATAFILE
		,TIPO
INTO #TABLE_ORIGINAL
FROM #TABLE_DATAFILES_ORIGINAL
INNER JOIN #TABLE_FILEGROUPS_ORIGINAL f ON f.[database]=BD and f.[filegroup_id]=groupid
WHERE TIPO ='dados'
ORDER BY BD
GO


--Gerar o script para os arquivos de log
INSERT INTO #TABLE_ORIGINAL 
SELECT	'ALTER DATABASE ['+BD+'] ADD LOG FILE ( NAME = N'''+datafile+''', FILENAME = N''' +unidade+ '''  , SIZE = ' +CONVERT(VARCHAR(10), SIZE)+ 'KB , FILEGROWTH = 204800KB )' AS SCRIPT
		,BD
		,UNIDADE
		,DATAFILE
		,TIPO
FROM #TABLE_DATAFILES_ORIGINAL
WHERE TIPO ='log'
GO

	 
--Inserir na tabela de replica, somente os valores que existem no Original e não existem na Replica
INSERT INTO [REPLICA].master.dbo.TABLE_DATAFILES
SELECT p.SCRIPT,p.BD FROM #TABLE_ORIGINAL p
INNER JOIN(
	SELECT pa.BD,pa.UNIDADE,pa.DATAFILE,pa.TIPO FROM #TABLE_ORIGINAL pa EXCEPT SELECT pr.BD,pr.UNIDADE,pr.DATAFILE,pr.TIPO FROM #TABLE_REPLICA pr) a
	ON p.UNIDADE=a.UNIDADE
GO		



-- ====================================================================
	-- Description: STEP 2 DO JOB
	-- Description: INICIAR O JOB NO SERVIDOR REPLICA
-- ====================================================================

EXEC [REPLICA].[msdb].[dbo].sp_start_job @job_name="job_name"



-- ====================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 04/08/2021
-- Description: REPLICAR DATAFILES CRIADOS NO ORIGINAL PARA A REPLICA
-- Description: CRIAR UM JOB QUE EXECUTE ESSA PROC NO SERVIDOR REPLICA
-- ====================================================================
 
--Gerar um cursos para executar o script de cada linha inserida na tabela e truncar após
DECLARE @script nvarchar(max)
DECLARE datafiles_cursor CURSOR FAST_FORWARD
FOR SELECT SCRIPT FROM master.dbo.TABLE_DATAFILES b INNER JOIN (select name,state_desc from sys.databases where state_desc='ONLINE' and database_id > 4) a ON a.name=b.bd
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
GO
