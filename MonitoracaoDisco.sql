ALTER PROCEDURE SP_MonitoracaoDisco AS
BEGIN

IF NOT EXISTS (SELECT 0 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME ='MonitoracaoDisco')
create table MonitoracaoDisco( Disco varchar(50), PctFree decimal(10,1), DataColeta datetime); 

truncate table MonitoracaoDisco;

DECLARE @QUERY nvarchar(MAX)
DECLARE @CONDICAO1 nvarchar(MAX)
DECLARE @CONDICAO2 nvarchar(MAX)

SELECT @CONDICAO1 = ' AND (growth > 0 and PctFree < 10)'
	  ,@CONDICAO2 = ' OR ((Disco.Drive=''C:\'' or Disco.Drive=''D:\'') and PctFree < 10)'
	  ,@QUERY= '
insert into MonitoracaoDisco (Disco, PctFree, DataColeta)
select distinct(disco.Drive) Disco
	  ,disco.PctFree
      ,GETDATE()
from sys.sysaltfiles inner join sys.sysdatabases on sysaltfiles.dbid = sysdatabases.dbid
left join (	select Drive
				 ,FreeSpaceInMB / 1024 FreeSpaceInMB
				 ,TotalSpaceInMB / 1024 TotalSpaceInMB
				 ,cast(100*FreeSpaceInMB/TotalSpaceInMB as decimal (10,1)) PctFree
			from ( SELECT DISTINCT dovs .volume_mount_point AS Drive
						 ,cast(CONVERT (bigint , dovs . available_bytes /1048576.0 ) as decimal( 10 ,2 )) FreeSpaceInMB
						 ,cast(CONVERT (bigint ,( dovs . total_bytes )/1048576.0 ) as decimal( 10 ,2 )) TotalSpaceInMB
					FROM sys . master_files mf
					CROSS APPLY sys. dm_os_volume_stats (mf .database_id, mf.FILE_ID ) dovs) disco
			) disco on (LEN(sysaltfiles.filename) - LEN(REPLACE(sysaltfiles.filename,disco.Drive,''''))) = LEN(disco.Drive)
where 1=1'  

SET @QUERY = (@QUERY + @CONDICAO1 + @CONDICAO2)

EXEC SP_EXECUTESQL @QUERY

IF( (SELECT COUNT(*) FROM MonitoracaoDisco) > 0)
	select 'verificar' status
ELSE	select 'ok' status

END
