--Wait stats (principais tipos de waits na base)
WITH [Waits] 
     AS (SELECT [wait_type], 
                [wait_time_ms] / 1000.0                             AS [WaitS], 
                ( [wait_time_ms] - [signal_wait_time_ms] ) / 1000.0 AS 
                [ResourceS], 
                [signal_wait_time_ms] / 1000.0                      AS [SignalS] 
                , 
                [waiting_tasks_count] 
                AS [WaitCount], 
                100.0 * [wait_time_ms] / Sum ([wait_time_ms]) 
                                           OVER()                   AS 
                [Percentage], 
                Row_number() 
                  OVER( 
                    ORDER BY [wait_time_ms] DESC)                   AS [RowNum] 
         FROM   sys.dm_os_wait_stats 
         WHERE  [wait_type] NOT IN ( 
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', 
        N'BROKER_TASK_STOP', 
                           N'BROKER_TO_FLUSH', 
                     N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE', 
        N'CHKPT', 
                             N'CLR_AUTO_EVENT', 
                     N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', 
                     -- Maybe uncomment these four if you have mirroring issues 
                     N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', 
                     N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD', 
                             N'DIRTY_PAGE_POLL', 
        N'DISPATCHER_QUEUE_SEMAPHORE', 
                     N'EXECSYNC', N'FSAGENT', 
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', 
                             N'FT_IFTSHC_MUTEX', 
                     -- Maybe uncomment these six if you have AG issues 
                     N'HADR_CLUSAPI_CALL', 
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION' 
                             , 
        N'HADR_LOGCAPTURE_WAIT', 
        N'HADR_NOTIFICATION_DEQUEUE', 
                     N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE', 
        N'KSOURCE_WAKEUP', 
                             N'LAZYWRITER_SLEEP' 
                                                , 
                     N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT', 
                             N'ONDEMAND_TASK_QUEUE', 
        N'PREEMPTIVE_XE_GETTARGETSTATE', 
                     N'PWAIT_ALL_COMPONENTS_INITIALIZED', 
                             N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', 
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP' 
        , 
                                                N'QDS_ASYNC_QUEUE', 
                     N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 
        N'QDS_SHUTDOWN_QUEUE', 
        N'REDO_THREAD_PENDING_WORK', 
        N'REQUEST_FOR_DEADLOCK_SEARCH', 
                     N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', 
        N'SLEEP_BPOOL_FLUSH', 
                                                N'SLEEP_DBSTARTUP', 
                     N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', 
        N'SLEEP_MASTERMDREADY', 
                                                N'SLEEP_MASTERUPGRADED', 
                     N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', 
        N'SLEEP_TASK', 
                                                N'SLEEP_TEMPDBSTARTUP', 
                     N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP', 
        N'SQLTRACE_BUFFER_FLUSH', 
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 
                     N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS', 
        N'WAITFOR', 
                                                N'WAITFOR_TASKSHUTDOWN', 
                     N'WAIT_XTP_RECOVERY', N'WAIT_XTP_HOST_WAIT', 
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 
                                                N'WAIT_XTP_CKPT_CLOSE', 
                     N'XE_DISPATCHER_JOIN', N'XE_DISPATCHER_WAIT', 
        N'XE_TIMER_EVENT' ) 
                AND [waiting_tasks_count] > 0) 
SELECT Max ([W1].[wait_type]) 
       AS 
       [WaitType], 
       Cast (Max ([W1].[waits]) AS DECIMAL (16, 2)) 
       AS [Wait_S], 
       Cast (Max ([W1].[resources]) AS DECIMAL (16, 2)) 
       AS [Resource_S], 
       Cast (Max ([W1].[signals]) AS DECIMAL (16, 2)) 
       AS [Signal_S], 
       Max ([W1].[waitcount]) 
       AS [WaitCount], 
       Cast (Max ([W1].[percentage]) AS DECIMAL (5, 2)) 
       AS [Percentage], 
       Cast (( Max ([W1].[waits]) / Max ([W1].[waitcount]) ) AS DECIMAL (16, 4)) 
       AS 
       [AvgWait_S], 
       Cast (( Max ([W1].[resources]) / Max ([W1].[waitcount]) ) AS 
             DECIMAL (16, 4)) AS 
       [AvgRes_S], 
       Cast (( Max ([W1].[signals]) / Max ([W1].[waitcount]) ) AS 
             DECIMAL (16, 4))   AS 
       [AvgSig_S], 
       Cast ('https://www.sqlskills.com/help/waits/' 
             + Max ([W1].[wait_type]) AS XML) 
       AS [Help/Info URL] 
FROM   [Waits] AS [W1] 
       INNER JOIN [Waits] AS [W2] 
               ON [W2].[rownum] <= [W1].[rownum] 
GROUP  BY [W1].[rownum] 
HAVING Sum ([W2].[percentage]) - Max([W1].[percentage]) < 95; -- percentage threshold 



----------------------------------------------------------------------------------------------------------------------------------------



Set nocount on
Set language us_english

Declare	@TempoMinimoEspera	int, @MostrarTOTALConexoes char(1), @MostrarMAIORTempoEspera char(1),  @MostrarBLOQUEIOS char(1),  @MostrarTRANSCOESAbertas char(1), @MostrarPROCESSOS CHAR(1), @MostrarTempoCPU char(1), @DBName sysname, @MostrarSTATUSConexoes char(1)
	
Set @MostrarTempoCPU = 'S'
-- Set @MostrarTOTALConexoes = 'S'
Set @MostrarSTATUSConexoes = 'S'
Set @MostrarMAIORTempoEspera = 'S'
Select	@TempoMinimoEspera = 2000	-- 2 segundos (milisegundos)

-- Set @MostrarBLOQUEIOS = 'S'
-- Set @MostrarTRANSCOESAbertas	= 'S'
  
Set @MostrarPROCESSOS = 'S'

Select ServerProperty('ComputerNamePhysicalNetBios') as [Nó Atual]
-- mostra
Select 
	p.spid,
	p.ecid,
	p.blocked,
	-- p.dbid,
	DbName = db_name(p.dbid),
	st.text,
	p.cmd,
	p.waittime,
	p.cpu,
	p.status,
	p.lastwaittype,
	p.waitresource,
	p.login_time,
	p.last_batch,
	p.open_tran,
	p.uid,
	p.hostname,
	p.loginame,
	p.nt_domain,
	p.nt_username,
	p.program_name,
	p.physical_io,
	p.memusage,
	p.waittype,
	p.kpid,
	p.sid,
	p.net_address,
	p.net_library,
	p.hostprocess,
	p.context_info,
	p.sql_handle,
	p.stmt_start,
	p.stmt_End,
	p.request_id
Into #t
From sys.sysprocesses AS p 
CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) AS st
Where	p.dbid = case	when @DBName is not null then db_id(@DBName)
						else p.dbid
						End
-- tira fora a minha propria conexão
and	spid <> @@spid 

If @MostrarTempoCPU= 'S'
Begin
	-- *** TEMPO DE CPU
	DECLARE @ts_now bigint 
	Select @ts_now = (Select cpu_ticks/(cpu_ticks/ms_ticks)From sys.dm_os_sys_info) 
	-- trocar o top pela quantidade de minutos de agora para traz que se quer ver
	Select TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
				   SystemIdle AS [System Idle Process], 
				   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
				   DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
	Into #tcpu
	From ( 
		  Select record.value('(./Record/@id)[1]', 'int') AS record_id, 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
				AS [SystemIdle], 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
				'int') 
				AS [SQLProcessUtilization], [timestamp] 
		  From ( 
				Select [timestamp], CONVERT(xml, record) AS [record] 
				From sys.dm_os_ring_buffers 
				Where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
				AND record LIKE '%<SystemHealth>%') AS x 
		  ) AS y 
	ORDER BY record_id DESC
	/*
	Select	'% Utilização da CPU nos ultimos 30 minutos',
			[Min %] = (Select min("sql server process cpu utilization") From #tcpu),
			[Média %] = (Select avg("sql server process cpu utilization") From #tcpu),
			[Max %] = (Select max("sql server process cpu utilization") From #tcpu)
			*/
	Drop table #tcpu
End


If @MostrarTOTALConexoes = 'S'
Begin
	-- total de conexões
	Select	TotalConexoes		= count(*),
			ConexoesPlatRelac	= convert(decimal, sum ( case when dbname = 'PlatRelac' then 1 else 0 End )),
			ConexoesExceller	= convert(decimal, sum ( case when dbname = 'ExcellerWeb' then 1 else 0 End))
	Into	#tc		
	From	#t
	Select	TotalConexoes, 
			ConexoesPlatRelac, [% ConexoesPlatRelac] = convert(int,(ConexoesPlatRelac/TotalConexoes*100)),
			ConexoesExceller, [% ConexoesExceller] = convert(int,(ConexoesExceller/TotalConexoes*100))
	From #tc
	
	Drop table #tc
End

If @MostrarSTATUSConexoes = 'S'
Begin
	-- total de conexões
	Select	Status,
			Qtde	= count(*),
			[Tempo Medio Espera] = avg(waittime),
			[Ultima Execucao] = max(last_batch),
			[Execucao Mais Antiga] = min(last_batch)
	From	#t
	Group by Status
End

-- *** pegar o maior tempo de espera
If @MostrarMAIORTempoEspera = 'S'
Begin
	If @TempoMinimoEspera is null Set @TempoMinimoEspera = 2000
	Select	dbname, waittime = max(waittime)
	Into	#mt
	From	#t
	Where waittime >  @TempoMinimoEspera 
	Group by dbname
	If (	Select count(*) 	From #t , #mt
			Where	#t.dbname	= #mt.dbname
			and		#t.waittime  = #mt.waittime ) > 0 
	Begin
		Select	'Processos Suspensos com Maior Tempo de Espera Superior a ' + convert(varchar(100),@TempoMinimoEspera) + ' milisegundos'
		Select	#t.*
		From	#t , #mt
		Where	#t.dbname	= #mt.dbname
		and		#t.waittime  = #mt.waittime
	End
	Drop table #mt
End

-- *** retornar todos processos
If @MostrarPROCESSOS = 'S'
Begin
		Select  * From #t 
	where cmd<>'AWAITING COMMAND'
	order by waittime desc
End

If @MostrarBLOQUEIOS = 'S'
Begin
	-- Tabelas de Apoio.
	CREATE TABLE #tbheadBlocked ([Host_Id] [int] NULL ,
		[SPID] [int] NULL ,
		[a] [varchar] (14)  NULL,
		[b] [int] NULL ,
		[TextBuffer] [varchar] (max) NULL 
	) 
	Create Table #tbInputBuffer(
	a VarChar(14),
	b int,
	TextBuffer VarChar(max))

	-- Passo1 -- Insere na tabela temporária "#tbheadblocked" todos os SPID que estão bloqueados
	Insert Into #tbheadBlocked Select Host_id(),SPID,null,null,null
	From master..sysprocesses (NoLock)
	Where SPID in (Select Blocked From master..sysprocesses (NoLock)
	Where Blocked <>0)or Blocked <> 0 

	-- Passo 2 -- Abre um cursor para obter o DBCC InputBuffer de todas os SPID que foram inseridas
	-- na tabela do passo 1 e armazena em uma nova tabela temporária "#tbInputBuffer"

	Declare @SPID Int
	Declare C_Buffer CURSOR For Select SPID From #tbheadBlocked e
	Open C_Buffer
	Fetch C_Buffer Into @SPID
	While @@Fetch_Status = 0 
	Begin
		-- limpa preventivamente
		Truncate table #tbInputBuffer
		Insert Into #tbInputBuffer exec ('Dbcc InputBuffer(' + @SPID + ') with NO_INFOMSGS ')
		Update #tbheadBlocked Set TextBuffer = #tbInputBuffer.TextBuffer From #tbInputBuffer Where Spid = @spid
		Fetch C_Buffer Into @SPID
	End
	Close C_Buffer
	Deallocate C_Buffer

	-- Passo 3 -- Faz o Join das tabelas temporárias apresentando o resultado final.
	-- Uma concatenação da SP_Who Active + DBCC InputBuffer() 

	Select	'Processos Bloqueados'
	Select distinct	a.SPID, 
		a.Blocked,
		a.ECID,
		b.TextBuffer,
		a.WaitTime as WaitTimeMS,
		datedIff (mi,a.last_batch,getDate() ) as RunEmMinutos, --Tempo de execução em minutos
		SubString(a.Status,1,10) as Status,
		a.CPU,
		SubString(Cast(a.Physical_IO as Varchar(10)),1,10) as Physical_IO,
		SubString(a.HostName,1,15) as HostName,
		SubString(a.LogiName,1,15) as LoginName,
		SubString(DB_Name(a.dbid),1,13) as DBName,
		SubString(convert(VarChar(24),a.last_batch ,113),1,24) as Last_Batch,
		a.open_tran,
		a.MemUsage
	From master..sysprocesses a (NoLock) Right Outer Join  #tbheadBlocked b (NoLock)
		On a.Spid = b.spid
	Where (a.SPID in (Select c.Blocked From master..sysprocesses c (NoLock)Where Blocked <>0)
			or a.Blocked <> 0 )
	and	a.SPID <> a.Blocked
	Order By a.Blocked 

	Drop Table #tbInputBuffer
	Drop table #tbheadBlocked
End

If @MostrarTRANSCOESAbertas = 'S'
Begin
	Select	'VERIfICAR NA ABA DO PRINT AS TRANSAÇÕES ABERTAS MAIS ANTIGAS'
	Select	distinct dbname, processado = 0 Into #ta From #t
	while (Select count(*) From #ta Where processado = 0 ) > 1
	Begin
		Select	top 1 @dbname = dbname From #ta Where processado = 0
		print 'DBCC OPENTRAN FOR DB: ['+ @dbname + ']'
		dbcc opentran(@dbname) with no_infomsgs
		
		update	#ta Set processado = 1 Where dbname = @dbname
	End
	Drop table #ta 
End
-- trop tabela temporaria		
Drop table #t
