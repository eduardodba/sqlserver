--Pega Lock
--select * from sys.sysprocesses where blocked > 0
 
--Cria, se for a Primeira Vez, as Tabelas Temporárias
If object_id('TEMPDB..#TbLock') Is Null
	Create Table #TbLock
	(
	IdTbLock int identity Not Null,
	Processo smallint Not Null,
	Computador nchar(128),
	Usuario nchar(128),
	Status nchar(30),
	BloqPor smallint Not Null,
	TipoComando char(16),
	Aplicativo nchar(128),
	Login_time datetime,
	EsperaMiliSeg bigint,
	ScriptParado varchar(1000),
	ScriptBloqueador varchar(1000),
	SeqBloq smallint,
	GrpBloq smallint
	)

If object_id('TEMPDB..#InputBuffer') Is Null
	Create Table #InputBuffer
	(
	EventType varchar(100),
	MyParameters smallint,
	EventInfo varchar(2000)
	)

If object_id('TEMPDB..#GroupLock') Is Null
	Create Table #GroupLock
	(
	IdGroupLock int identity Not Null,
	Processo smallint Not Null
	)

--x--

--Variáveis !!!

--Opções:
--0 = Mais rápida e compatível com Sql Server 2000
--1 = Pode ser mais lenta, porém com mais informações, mas não compatível com o Sql Server 2000 por usar as DMVs       
Declare @Opcao binary

--Por Default, usa a mais rápida
Set @Opcao = 1

--Caso a versão seja anterior ao 2005, "força" a opção mais rápida
If 
(
Select Cast(Right(Substring(@@version, Charindex('Sql Server', @@version), 15), 4) As int)
)
< 2005
	Set @Opcao = 0

Declare @Waittime bigint

--ATENÇÃO !!! Defina o tempo mínimo do lock da conexão em milissegundos !!!
Set @Waittime = 0

Declare @MaxId int, @IdLoop int
Declare @MaxIdG int, @IdLoopG int
Declare @SpId smallint, @MyFlagLoop binary, @SeqBloq smallint
Declare @Cmd varchar(50)

Set nocount On

Truncate Table #TbLock
Truncate Table #GroupLock
Set @MyFlagLoop = 0
While @MyFlagLoop = 0
Begin
	If Exists(
	Select 1 From master..sysprocesses 
	Where status in ('runnable', 'suspended') and blocked  <> 0 And waittime >= @Waittime
	)
	Begin
		Insert into #TbLock
		(
		Processo, Computador, Usuario, Status, BloqPor, TipoComando, Aplicativo, Login_Time, EsperaMiliSeg,
		ScriptParado, ScriptBloqueador, SeqBloq
		)
		Select 
		Processo     = spid
		,Computador  = hostname
		,Usuario     = loginame
		,Status      = status
		,BloqPor     = blocked
		,TipoComando = cmd
		,Aplicativo  = program_name
		,login_time
		,EsperaMiliSeg =  waittime
		,Null ,Null, 0
		From master..sysprocesses 
		Where status in ('runnable', 'suspended') and blocked  <> 0
		--Order by blocked desc, status, spid

		--Obtém a conexão que está bloqueando as outras
		Insert into #TbLock
		(
		Processo, Computador, Usuario, Status, BloqPor, TipoComando, Aplicativo, Login_Time, EsperaMiliSeg,
		ScriptParado, ScriptBloqueador, SeqBloq
		)
		Select 
		Processo     = spid
		,Computador  = hostname
		,Usuario     = loginame
		,Status      = status
		,BloqPor     = blocked
		,TipoComando = cmd
		,Aplicativo  = program_name
		,login_time
		,EsperaMiliSeg =  waittime
		,Null ,Null, 0
		From master..sysprocesses  SP
		Where Exists
		(
		Select 1 From #TbLock Where BloqPor = SP.spid
		)
		And SP.blocked = 0

		--Salva a referência das conexões que geraram bloqueios
		Insert into #GroupLock
		Select Processo From #TbLock Where BloqPor = 0

		Select @MaxIdG = Max(IdGroupLock) From #GroupLock
		Set @IdLoopG = 1

		While @IdLoopG <= @MaxIdG
		Begin
			Set @SeqBloq = 1
			Select @SpId = Processo 
			From #GroupLock
			Where IdGroupLock = @IdLoopG

			--Ordena da conexão que gerou o lock para as outras

			--1o do Grupo = Que causou o bloqueio
			Update #TbLock
			Set SeqBloq = @SeqBloq, GrpBloq = @IdLoopG
			Where Processo = @SpId

			Set @SeqBloq = @SeqBloq + 1

			--2o do Grupo
			Update #TbLock 
			Set SeqBloq = @SeqBloq, GrpBloq = @IdLoopG
			Where BloqPor = @SpId

			While 1=1
			Begin
				Set @SeqBloq = @SeqBloq + 1
				Update L2 
				Set L2.SeqBloq = @SeqBloq, L2.GrpBloq = @IdLoopG
				From #TbLock L1 
				Inner Join #TbLock L2 On L2.BloqPor = L1.Processo
				Where L1.SeqBloq > 0 And L2.SeqBloq = 0
				If Not Exists
				(
				Select 1 From #TbLock L1
				Inner Join #TbLock L2 On L2.BloqPor = L1.Processo
				Where L1.SeqBloq > 0 And L2.SeqBloq = 0
				)
					Break
			End
	
			Set @IdLoopG = @IdLoopG + 1

		End

		--Se Opção mais Rápida
		If @Opcao = 0
		Begin
			Set @IdLoop = 1
			Select @MaxId = Max(IdTbLock) From #TbLock
			While @IdLoop <= @MaxId
			Begin
				--Le até 1k do script que está sendo bloqueado
				Truncate Table #Inputbuffer
				Select @SpId = Processo From #TbLock Where IdTbLock = @IdLoop
				Set @Cmd = 'Dbcc InputBuffer(' + Cast(@SpId As varchar(5)) + ')'
				Insert Into #Inputbuffer Exec(@Cmd)
				Update #TbLock Set ScriptParado = EventInfo From #Inputbuffer
				--Le até 1k do script que está bloqueando
				Truncate Table #Inputbuffer
				Select @SpId = BloqPor From #TbLock Where IdTbLock = @IdLoop
				If @SpId > 0
				Begin
					Set @Cmd = 'Dbcc InputBuffer(' + Cast(@SpId As varchar(5)) + ')'
					Insert Into #Inputbuffer Exec(@Cmd)
					Update #TbLock Set ScriptBloqueador = EventInfo From #Inputbuffer
				End
				Set @IdLoop = @IdLoop + 1
			End
		End
		Set @MyFlagLoop = 1
	End
End

If @Opcao = 0
Select 
	TL.GrpBloq
	,TL.SeqBloq
	,TL.Processo,0 'Processo Bloqueado'
	,IsNull(T2.Processo,0) 'Processo Bloqueador'
	,TL.Aplicativo 'Aplicativo Parado'
	,IsNull(T2.Aplicativo,'Não Bloqueado') 'Aplicativo Bloqueador'
	,TL.ScriptParado
	,TL.ScriptBloqueador
	,TL.Usuario 'Usuario Parado'
	,IsNull(T2.Usuario,'-') 'Usuario Bloqueador'
	,TL.Status 'Status Conexao Parada'
	,IsNull(T2.Status,'-') 'Status Conexao Bloqueadora'
	,TL.TipoComando 'Tipo Comando Parado'
	,IsNull(T2.TipoComando,'-') 'Tipo Comando Bloqueador'
	,TL.Login_time 'Login Time Conexao Parada'
	,IsNull(T2.Login_time,0) 'Login Time Conexao Bloqueadora'
	,TL.EsperaMiliSeg 'Espera Conexao Parada'
	,IsNull(T2.EsperaMiliSeg,0) 'Espera Conexao Bloqueadora'
	From #TbLock TL
	Left Outer Join #TbLock T2
	On T2.Processo = TL.BloqPor
	Order By TL.GrpBloq, TL.SeqBloq
--@Opcao = 1
Else
Select 
	TL.GrpBloq
	,TL.SeqBloq
	,TL.Processo,0 'Processo Bloqueado'
	,IsNull(T2.Processo,0) 'Processo Bloqueador'
	,TL.Aplicativo 'Aplicativo Parado'
	,IsNull(T2.Aplicativo,'Não Bloqueado') 'Aplicativo Bloqueador'
	,E1.client_net_address 'Ip Conexao Parada'
	,IsNull(E2.client_net_address,'-') 'Ip Conexao Bloqueadora'
	,SB.Text ScriptConexaoParada
	,IsNull(SP.Text, '-') ScriptConexaoBloqueadora
	,TL.Usuario 'Usuario Parado'
	,IsNull(T2.Usuario,'-') 'Usuario Bloqueador'
	,TL.Status 'Status Conexao Parada'
	,IsNull(T2.Status,'-') 'Status Conexao Bloqueadora'
	,TL.TipoComando 'Tipo Comando Parado'
	,IsNull(T2.TipoComando,'-') 'Tipo Comando Bloqueador'
	,TL.Login_time 'Login Time Conexao Parada'
	,IsNull(T2.Login_time,0) 'Login Time Conexao Bloqueadora'
	,TL.EsperaMiliSeg 'Espera Conexao Parada'
	,IsNull(T2.EsperaMiliSeg,0) 'Espera Conexao Bloqueadora'
	From #TbLock TL
	Left Outer Join #TbLock T2
	On T2.Processo = TL.BloqPor
	Left Outer Join sys.dm_exec_connections E1 ON E1.session_id = TL.Processo
	Left Outer Join sys.dm_exec_connections E2 ON E2.session_id = TL.BloqPor
	Outer Apply sys.dm_exec_sql_text(E1.most_recent_sql_handle) AS SB
	Outer Apply sys.dm_exec_sql_text(E2.most_recent_sql_handle) AS SP
	Order By TL.GrpBloq, TL.SeqBloq