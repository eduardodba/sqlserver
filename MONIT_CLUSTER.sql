
CREATE OR ALTER PROCEDURE MONIT_CLUSTER AS
BEGIN

declare @minMemory int
	   ,@maxMemory int
	   ,@physical int
	   ,@inst int
	   ,@nodes int
	   ,@atual int

SELECT
	   @physical = 16000 - 4096 --> 4GB para o SO
	  ,@inst = 2
	  ,@nodes = 2
	  ,@atual = 2
	  



IF ( (SELECT DATEDIFF(MINUTE,sqlserver_start_time,getdate()) as Minutos FROM sys.dm_os_sys_info) < 60)		--> Se o SQL está a menos de 60 min online 
BEGIN
	select 'restart'
	--Encaminha o Alerta
	--SEND POST
END



IF (@inst between 1 and 2 and @nodes > 1 and @atual > 1) OR (@inst > 2 and @nodes > 1 and @atual > 2)		--> 1 ou 2 instâncias e mais de 1 nó = aceitavel 1 instância por nó
BEGIN																										--> Mais de 2 Instâncias e mais de 1 nó = aceitavel 2 instâncias por nó
	select @nodes as nodes, @inst as instancias, @atual as atual, 'PROBLEMA NO BALANCEAMENTO' as situacao
	
	GOTO ajustaMemoria;
	
	--Encaminha o Alerta
	--SEND POST

END
ELSE IF (@nodes = 1)																						--> Somente um nó ativo
BEGIN
	select @nodes as nodes, @inst as instancias, @atual as atual, 'PROBLEMA EM UM NODE' as situacao
	
	GOTO ajustaMemoria;
	
	--Encaminha o Alerta
	--SEND POST
END



ajustaMemoria:
BEGIN

	select @maxMemory = @physical/@atual																	--> Calcula max e min Server Memory
		  ,@minMemory = @maxMemory - (@maxMemory * 0.2)

    
	EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE							--> Ajusta memória
	EXEC sys.sp_configure N'min server memory (MB)', @minMemory
	EXEC sys.sp_configure N'max server memory (MB)', @maxMemory
	RECONFIGURE WITH OVERRIDE
	EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
END
END
