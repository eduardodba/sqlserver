IF OBJECT_ID (N'spTempDBSizeInfo' ) IS NOT NULL
        DROP procedure spTempDBSizeInfo;
USE[master]
GO
CREATE PROC [dbo].[spTempDBSizeInfo]
AS
DECLARE @subject varchar(500)
DECLARE @body NVARCHAR (MAX)
DECLARE @body_format varchar(20)='HTML'
SELECT @subject='Free TempDB space on '+@@ServerName+' - '+CAST(100 -cast((A.TotalSpaceInMB-cntr_value/1024)*100/A.TotalSpaceInMB as int) AS VARCHAR(3))+'% left of '+cast(A.TotalSpaceInMB as varchar(12))+'MB'
FROM sys.dm_os_performance_counters
CROSS APPLY(select sum(size)*8/1024 as TotalSpaceInMB from tempdb.sys.database_files where type=0) AS A
WHERE counter_name='Free Space in tempdb (KB)'

CREATE TABLE[dbo].[#tblWhoIsActive](
[dd hh:mm:ss.mss] [varchar](8000) NULL,
[session_id] [smallint] NOT NULL,
[sql_text] [xml] NULL,
[login_name] [nvarchar](128) NOT NULL,
[wait_info] [nvarchar](4000) NULL,
[tran_log_writes] [nvarchar](4000) NULL,
[CPU] [varchar](30) NULL,
[tempdb_allocations] [varchar](30) NULL,
[tempdb_current] [varchar](30) NULL,
[blocking_session_id] [smallint] NULL,
[reads] [varchar](30) NULL,
[writes] [varchar](30) NULL,
[physical_reads] [varchar](30) NULL,
[query_plan] [xml] NULL,
[used_memory] [varchar](30) NULL,
[status] [varchar](30) NOT NULL,
[tran_start_time] [datetime] NULL,
[open_tran_count] [varchar](30) NULL,
[percent_complete] [varchar](30) NULL,
[host_name] [nvarchar](128) NULL,
[database_name] [nvarchar](128) NULL,
[program_name] [nvarchar](128) NULL,
[start_time] [datetime] NOT NULL,
[login_time] [datetime] NULL,
[request_id] [int] NULL,
[collection_time] [datetime] NOT NULL) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
EXEC sp_WhoIsActive
@get_transaction_info=2,
@get_plans=1,
@destination_table='#tblWhoIsActive'
SELECT TOP 5
[dd hh:mm:ss.mss],
session_id,
CAST(sql_text as varchar(MAX)) AS sql_text,
login_name,
(REPLACE(tempdb_current,',','')*8)/1024 as tempdb_current_MB,
(REPLACE(tempdb_allocations,',','')*8)/1024 as tempdb_allocations_MB,
CPU,
reads,
writes
INTO #tblWhoIsActive_temp
FROM #tblWhoIsActive
WHERE REPLACE(tempdb_allocations,',','')>0
ORDER BY tempdb_allocations DESC
IF @@ROWCOUNT=0
BEGIN

SET @body=N'<head>'+ N'<style type="text/css">h2, body {font-family: Arial, verdana;} table{font-size:11px; border-collapse:collapse;} td{background-color:#F1F1F1; border:1px solid black; padding:3px;} th{background-color:#99CCFF;}</style>'+
N'<h2><font color="#0000ff" size="4">Free TempDB space</font></h2>'+ N'</head>'+ N'<p>'+' '+'</p>'+N'<body>'+N' <hr> '+N'<h1><font color="#0000ff" size="2">The top 5 TempDB intensive queries currently running are:</font></h1>'+
N' '+N'<font color="#0000ff" size="2">No queries using TempDB currently running</font>'+N' '+ N' <br></br>'+ N'<p>'+' '+'</p>'+ N' <hr> '+N'<h1><font color="#0000ff" size="2">TempDB components size MB:</font></h1>'+
N' '+ N'<table border="1">'+ N'<tr><th>PersistedTableSizeMB</th><th>VersionStoreSizeMB</th></tr>' +
CAST((
SELECT td=SUM(au.total_pages)*8/1024,'',
td=MAX(A.VersionStoreSizeMB),''
FROM tempdb.sys.partitions p
INNER JOIN tempdb.sys.allocation_units au
ON p.hobt_id=au.container_id
CROSS APPLY (SELECT cntr_value/1024 AS VersionStoreSizeMB FROM sys.dm_os_performance_counters WHERE counter_name='Version Store Size (KB)') AS A
WHERE OBJECT_NAME(p.object_id) not like '#%'
FOR XML PATH('tr'),TYPE )
AS NVARCHAR(MAX))+
N'</table>'+ N'</body>';
END
ELSE
BEGIN
SET @body= N'<head>'+ N'<style type="text/css">h2, body {font-family: Arial, verdana;} table{font-size:11px; border-collapse:collapse;} td{background-color:#F1F1F1; border:1px solid black; padding:3px;} th{background-color:#99CCFF;}</style>'+
N'<h2><font color="#0000ff" size="4">Free TempDB space</font></h2>'+ N'</head>'+ N'<p>'+' '+'</p>'+N'<body>'+N' <hr> '+N'<h1><font color="#0000ff" size="2">The top 5 tempdb intensive queries currently running are:</font></h1>'+
N' '+ N'<table border="1">'+ N'<tr><th>[dd hh:mm:ss.mss]</th><th>session_id</th><th>sql_text</th><th>login_name</th><th>tempdb_allocations_MB</th><th>tempdb_current_MB</th><th>CPU</th><th>reads</th><th>writes</th></tr>'+
CAST((
SELECT td=[dd hh:mm:ss.mss],'',td=session_id,'',td=CAST(sql_text AS VARCHAR(256)),'','',td=login_name,'',td=tempdb_allocations_MB,'',td=tempdb_current_MB,'',td=CPU,'',td=reads,'',td=writes,''FROM #tblWhoIsActive_temp
ORDER BY tempdb_allocations_MB DESC
FOR XML PATH('tr'),TYPE )
AS NVARCHAR(MAX))+
N'</table>'+ N' <br></br>'+ N'<p>'+' '+'</p>'+ N' <hr> '+ N'<h1><font color="#0000ff" size="2">TempDB components size MB:</font></h1>'+N' '+ N'<table border="1">'+
N'<tr><th>PersistedTableSizeMB</th><th>VersionStoreSizeMB</th></tr>' +
CAST((
SELECT
td=SUM(au.total_pages)*8/1024,'',
td=MAX(A.VersionStoreSizeMB),''
from tempdb.sys.partitions p
INNER JOIN tempdb.sys.allocation_units au
ON p.hobt_id=au.container_id
CROSS APPLY
(SELECT cntr_value/1024 AS VersionStoreSizeMB FROM sys.dm_os_performance_counters WHERE counter_name='Version Store Size (KB)')AS A
WHERE object_name (p.object_id) not like '#%'
FOR XML PATH('tr'),TYPE )AS NVARCHAR(MAX))+
N'</table>'+ N'</body>'
END



EXEC MSDB.dbo.sp_send_dbmail
@profile_name='DBA'
,@recipients='eduardo.barbieri@grupopan.com'
,@subject=@subject
,@body=@body
,@body_format=@body_format


