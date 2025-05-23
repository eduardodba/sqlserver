USE DBA
GO


	/**************************************************************** 
	--------------------------- DESCRICAO ---------------------------
	Procedure para gerar a coleta do painel de TOP QUERY
	Coleta dados do baseline Procstats, AdhocStats e CPU
	Depois consolida as informações no panvdba02

	--------------------------- HISTORICO ---------------------------
	-- 23/05/2025 - Eduardo Barbieri - Criacao da Procedure

	****************************************************************/


CREATE OR ALTER PROCEDURE sp_CargaTopQuery @DtIni DATE AS
BEGIN
    /* CARREGA VALORES TOP QUERY ONLINE */
    
    SET NOCOUNT ON
    -- Verificar se a tabela existe e criar se não existir
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'baseline_tuning')
        DROP TABLE baseline_tuning
        
    CREATE TABLE baseline_tuning (
            DtColeta DATETIME,
            RunDateTime DATETIME,
            DbName varchar(255),
            ObjectName varchar(max),
            ExecCount bigint,
            TotalTimeMs bigint,
            TotalLogicalReads bigint,
            TotalWorkerTimeMs bigint,
            TotalPhysicalReads bigint,
            TimePeriod VARCHAR(20),
            CollectionType varchar(100),
            query_hash varchar(255)
    );
    
    
    DECLARE @OrderColumn NVARCHAR(50);
    DECLARE @CollectionType NVARCHAR(50);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @QTD INT
    DECLARE @Aux bit = 0
    DECLARE @DtFim DATE = @DtIni
    
    -- Cursor para iterar sobre as colunas de ordenação
    DECLARE OrderColumns CURSOR FOR
    SELECT '6', 'AvgLogicalReads' UNION ALL
    SELECT '5', 'AvgTimeMs' UNION ALL
    SELECT '7', 'AvgWorkerTimeMs' UNION ALL
    --SELECT '8', 'AvgPhysicalReads' UNION ALL
    SELECT '4', 'ExecCount';
    
    OPEN OrderColumns;
    FETCH NEXT FROM OrderColumns INTO @OrderColumn, @CollectionType;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construir a consulta dinâmica
        SET @SQL = '
        WITH CombinedStats AS (
            SELECT 
                [DtColeta],
                [DbName],
                [ObjectName],
                [ExecCount],
                [AvgTimeMs] * [ExecCount] [TotalTimeMs],
                [AvgLogicalReads] * [ExecCount] [TotalLogicalReads],
                [AvgWorkerTimeMs] * [ExecCount] [TotalWorkerTimeMs],
                [AvgPhysicalReads] * [ExecCount] [TotalPhysicalReads],
                [AvgLogicalWrites] * [ExecCount] [TotalLogicalWrites],
                null [Text],
                null AS query_hash
            FROM [DBA].[dbo].[Baseline_ProcStats]
            WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, '''+convert(varchar, @DtIni, 23)+''')) + ''07:30:00''
             AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, '''+convert(varchar, @DtFim, 23)+''')) + ''20:00:00'' 
            UNION ALL
            SELECT 
                [DtColeta],
                [DbName],
                [ObjectName],
                [ExecCount],
                [AvgTimeMs] * [ExecCount] [TotalTimeMs],
                [AvgLogicalReads] * [ExecCount] [TotalLogicalReads],
                [AvgWorkerTimeMs] * [ExecCount] [TotalWorkerTimeMs],
                [AvgPhysicalReads] * [ExecCount] [TotalPhysicalReads],
                [AvgLogicalWrites] * [ExecCount] [TotalLogicalWrites],
                [Text],
                query_hash
            FROM [DBA].[dbo].[Baseline_AdhocStats]
            WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, '''+convert(varchar, @DtIni, 23)+''')) + ''07:30:00''
             AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, '''+convert(varchar, @DtFim, 23)+''')) + ''20:00:00''
        ),
        SummedTotals AS (
        SELECT 
            [DbName],
            [ObjectName],
            ISNULL(CONVERT(VARCHAR(1000), query_hash, 1), LEFT(ObjectName, 500)) AS query_hash,
            [Text],
            MAX([Dtcoleta]) AS [Dtcoleta],
            SUM([ExecCount]) AS [TotalExecCount],
            SUM([TotalTimeMs]) AS [TotalTimeMs],
            SUM([TotalLogicalReads]) AS [TotalLogicalReads],
            SUM([TotalWorkerTimeMs]) AS [TotalWorkerTimeMs],
            SUM([TotalPhysicalReads]) AS [TotalPhysicalReads],
            SUM([TotalLogicalWrites]) AS [TotalLogicalWrites]
        FROM CombinedStats
        GROUP BY [DbName], [ObjectName], [query_hash], [Text]
        ),
        DistinctQueries AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY query_hash ORDER BY [TotalWorkerTimeMs] DESC) AS rn_hash
        FROM SummedTotals
        )
       INSERT INTO baseline_tuning (
            DtColeta,
            DbName,
            ObjectName,
            ExecCount,
            TotalTimeMs,
            TotalLogicalReads,
            TotalWorkerTimeMs,
            TotalPhysicalReads,
            RunDateTime,
            CollectionType,
            TimePeriod,
            query_hash
        )
       SELECT TOP 5 
        [Dtcoleta],
        [DbName],
        CASE WHEN [ObjectName] = ''AdHoc'' THEN [Text] ELSE [ObjectName] end [ObjectName],
        [TotalExecCount],
        [TotalTimeMs],
        [TotalLogicalReads],
        [TotalWorkerTimeMs],
        [TotalPhysicalReads],
        '''+convert(varchar, @DtIni, 23)+''' AS [RunDateTime],
        REPLACE(''' + @CollectionType + ''',''Avg'',''Total'') AS CollectionType,
        ''Online'',
        query_hash
        FROM DistinctQueries
        WHERE rn_hash = 1
        ORDER BY ' + @OrderColumn + ' DESC;';
    
        -- Executar a consulta dinâmica
        EXEC sp_executesql @SQL;
    
        FETCH NEXT FROM OrderColumns INTO @OrderColumn, @CollectionType;
    END;
    
    CLOSE OrderColumns;
    DEALLOCATE OrderColumns;
    
    
    
    SELECT @QTD = Count(*)
    FROM [DBA].[dbo].[Baseline_ProcStats]
    WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, @DtIni)) + '07:30:00' AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, @DtFim)) + '20:00:00'
    --print CAST(@QTD as VARCHAR(50)) + ' Registros na Baseline Procstats Online'
    
    
    SELECT @QTD = Count(*)
    FROM [DBA].[dbo].[Baseline_AdhocStats]
    WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, @DtIni)) + '07:30:00' AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, @DtFim)) + '20:00:00'
    --print CAST(@QTD as VARCHAR(50)) + ' Registros na Baseline AdhocStats Online'
    
    
    SELECT @QTD = Count(*) from dba..baseline_tuning
    --print CAST(@QTD as VARCHAR(50)) + ' Registros Processados na coleta Online'
    

    --execute as login = 'Kerfisstjori'
    
    /* CARREGA VALORES CPU ONLINE */

    delete from DBA.DBA.DBO.Baseline_TuningCPU_Consolidado where Servidor = CAST(@@SERVERNAME AS VARCHAR(100)) 
    
    insert into dba.dba.dbo.Baseline_TuningCPU_Consolidado
    select 	 @@SERVERNAME Servidor
        ,CAST(DATEADD(MINUTE, (DATEDIFF(MINUTE, '20000101', dtcoleta) / 1440)*1440, '20000101') AS DATETIME) DIA
        ,AVG(SQL_CPU)  SQL_CPU
        ,100*SUM((CASE WHEN SQL_CPU > 89 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 90'
        ,100*SUM((CASE WHEN SQL_CPU BETWEEN 70 AND 89 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 70 e < 80'
        ,100*SUM((CASE WHEN SQL_CPU BETWEEN 40 AND 69 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 40 e < 60'
        ,100*SUM((CASE WHEN SQL_CPU < 39 THEN 1 ELSE 0 END))/count(SQL_CPU) '< 30'
        ,'Online' TimePeriod
    from dba.[dbo].[Baseline_CPU]
    Where dtcoleta > GETDATE()-30 and (CONVERT(TIME, dtcoleta) >= '07:30:00' AND CONVERT(TIME, dtcoleta) < '20:00:00') 
    GROUP BY DATEADD(MINUTE, (DATEDIFF(MINUTE, '20000101', dtcoleta) / 1440)*1440, '20000101')
    
    
    
    IF (@QTD > 0)
        SET @Aux = 1
    
    SET @DtIni = DATEADD(day, -1, @DtIni)
    
    
    
    
    /* CARREGA VALORES TOP QUERY NOTURNO */
    
    DECLARE OrderColumns CURSOR FOR
        SELECT '6', 'AvgLogicalReads' UNION ALL
        SELECT '5', 'AvgTimeMs' UNION ALL
        SELECT '7', 'AvgWorkerTimeMs' UNION ALL
        --SELECT '8', 'AvgPhysicalReads' UNION ALL
        SELECT '4', 'ExecCount';
    OPEN OrderColumns;
    FETCH NEXT FROM OrderColumns INTO @OrderColumn, @CollectionType;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construir a consulta dinâmica
        SET @SQL = '
        WITH CombinedStats AS (
            SELECT 
                [DtColeta],
                [DbName],
                [ObjectName],
                [ExecCount],
                [AvgTimeMs] * [ExecCount] [TotalTimeMs],
                [AvgLogicalReads] * [ExecCount] [TotalLogicalReads],
                [AvgWorkerTimeMs] * [ExecCount] [TotalWorkerTimeMs],
                [AvgPhysicalReads] * [ExecCount] [TotalPhysicalReads],
                [AvgLogicalWrites] * [ExecCount] [TotalLogicalWrites],
                null [Text],
                null AS query_hash
            FROM [DBA].[dbo].[Baseline_ProcStats]
            WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, '''+CAST(@Dtini as varchar(10))+''')) + ''20:00:00''
             AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, '''+CAST(@DtFim as varchar(10))+''')) + ''07:30:00''
            UNION ALL
            SELECT 
                [DtColeta],
                [DbName],
                [ObjectName],
                [ExecCount],
                [AvgTimeMs] * [ExecCount] [TotalTimeMs],
                [AvgLogicalReads] * [ExecCount] [TotalLogicalReads],
                [AvgWorkerTimeMs] * [ExecCount] [TotalWorkerTimeMs],
                [AvgPhysicalReads] * [ExecCount] [TotalPhysicalReads],
                [AvgLogicalWrites] * [ExecCount] [TotalLogicalWrites],
                [Text],
                query_hash
            FROM [DBA].[dbo].[Baseline_AdhocStats]
            WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, '''+CAST(@Dtini as varchar(10))+''')) + ''20:00:00''
             AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, '''+CAST(@DtFim as varchar(10))+''')) + ''07:30:00''
        ),
        SummedTotals AS (
        SELECT 
            [DbName],
            [ObjectName],
            ISNULL(CONVERT(VARCHAR(1000), query_hash, 1), LEFT(ObjectName, 500)) AS query_hash,
            [Text],
            MAX([Dtcoleta]) AS [Dtcoleta],
            SUM([ExecCount]) AS [TotalExecCount],
            SUM([TotalTimeMs]) AS [TotalTimeMs],
            SUM([TotalLogicalReads]) AS [TotalLogicalReads],
            SUM([TotalWorkerTimeMs]) AS [TotalWorkerTimeMs],
            SUM([TotalPhysicalReads]) AS [TotalPhysicalReads],
            SUM([TotalLogicalWrites]) AS [TotalLogicalWrites]
        FROM CombinedStats
        GROUP BY [DbName], [ObjectName], [query_hash], [Text]
        ),
        DistinctQueries AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY query_hash ORDER BY [TotalWorkerTimeMs] DESC) AS rn_hash
        FROM SummedTotals
        )
       INSERT INTO baseline_tuning (
            DtColeta,
            DbName,
            ObjectName,
            ExecCount,
            TotalTimeMs,
            TotalLogicalReads,
            TotalWorkerTimeMs,
            TotalPhysicalReads,
            RunDateTime,
            CollectionType,
            TimePeriod,
            query_hash
        )
       SELECT TOP 5 
        [Dtcoleta],
        [DbName],
        CASE WHEN [ObjectName] = ''AdHoc'' THEN [Text] ELSE [ObjectName] end [ObjectName],
        [TotalExecCount],
        [TotalTimeMs],
        [TotalLogicalReads],
        [TotalWorkerTimeMs],
        [TotalPhysicalReads],
        '''+convert(varchar, DATEADD(day, +1, @DtIni), 23)+''' AS [RunDateTime],
        REPLACE(''' + @CollectionType + ''',''Avg'',''Total'') AS CollectionType,
        ''Norturno'',
        query_hash
        FROM DistinctQueries
        WHERE rn_hash = 1
        ORDER BY ' + @OrderColumn + ' DESC;';
    
        -- Executar a consulta dinâmica
        EXEC sp_executesql @SQL;
        FETCH NEXT FROM OrderColumns INTO @OrderColumn, @CollectionType;
    END;
    
    CLOSE OrderColumns;
    DEALLOCATE OrderColumns;
    
    
    
    
    
    SELECT @QTD = Count(*)
    FROM [DBA].[dbo].[Baseline_ProcStats]
    WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, @DtIni)) + '20:00:00' AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, @DtFim)) + '07:30:00'
    --print CAST(@QTD as VARCHAR(50)) + ' Registros na Baseline Procstats Noturno'
    
    
    SELECT @QTD = Count(*)
    FROM [DBA].[dbo].[Baseline_AdhocStats]
    WHERE dtcoleta >= CONVERT(DATETIME, CONVERT(DATE, @DtIni)) + '20:00:00' AND  dtcoleta < CONVERT(DATETIME, CONVERT(DATE, @DtFim)) + '07:30:00'
    --print CAST(@QTD as VARCHAR(50)) + ' Registros na Baseline AdhocStats Noturno'
    
    
    SELECT @QTD = Count(*) from dba..baseline_tuning where TimePeriod = 'Norturno'
    --print CAST(@QTD as VARCHAR(50)) + ' Registros Processados na coleta Noturno'
    
    
    IF (@QTD > 0)
        SET @Aux = 1
    
    
    IF (@Aux = 1)
    BEGIN
        delete from DBA.DBA.DBO.Baseline_Tuning_Consolidado where cAST(dtcoleta as DATE) = DATEADD(day, +1, @DtIni) and Servidor = CAST(@@SERVERNAME AS VARCHAR(100)) 
    
        insert into DBA.DBA.DBO.Baseline_Tuning_Consolidado
        select	Dtcoleta,
                CAST(@@SERVERNAME AS VARCHAR(100)) [Servidor],
                RunDateTime, 
                DbName,
                ObjectName,
                ExecCount,
                TotalTimeMs,
                TotalLogicalReads,
                TotalWorkerTimeMs,
                TotalPhysicalReads,
                CollectionType, 
                TimePeriod,
                query_hash
        from dba..baseline_tuning

        --print 'Registros carregados para o PANVDBA02'
    END
    
    
    
    
    
    /* CARREGA VALORES CPU NOTURNO */
        
    insert into dba.dba.dbo.Baseline_TuningCPU_Consolidado
    select 	 @@SERVERNAME Servidor
        ,CAST(DATEADD(MINUTE, (DATEDIFF(MINUTE, '20000101', dtcoleta) / 1440)*1440, '20000101') AS DATETIME) DIA
        ,AVG(SQL_CPU)  SQL_CPU
        ,100*SUM((CASE WHEN SQL_CPU > 89 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 90'
        ,100*SUM((CASE WHEN SQL_CPU BETWEEN 70 AND 89 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 70 e < 80'
        ,100*SUM((CASE WHEN SQL_CPU BETWEEN 40 AND 69 THEN 1 ELSE 0 END))/count(SQL_CPU) '> 40 e < 60'
        ,100*SUM((CASE WHEN SQL_CPU < 39 THEN 1 ELSE 0 END))/count(SQL_CPU) '< 30'
        ,'Noturno' TimePeriod
    from dba.[dbo].[Baseline_CPU]
    Where dtcoleta > GETDATE()-30 and 
                ((CONVERT(TIME, DTCOLETA) >= '20:00:00' AND CONVERT(TIME, DTCOLETA) <= '23:59:59') OR (CONVERT(TIME, DTCOLETA) >= '00:00:00' AND CONVERT(TIME, DTCOLETA) < '07:30:00'))
    GROUP BY DATEADD(MINUTE, (DATEDIFF(MINUTE, '20000101', dtcoleta) / 1440)*1440, '20000101')
    


    
    
    
    /* AJUSTA VALORES TOP QUERY */
    
    UPDATE dba.dba.dbo.baseline_tuning_consolidado
    SET 
        ExecCount = CASE WHEN ExecCount < 1 THEN ExecCount * -1 ELSE ExecCount END,
        TotalTimeMs = CASE WHEN TotalTimeMs < 1 THEN TotalTimeMs * -1 ELSE TotalTimeMs END,
        TotalLogicalReads = CASE WHEN TotalLogicalReads < 1 THEN TotalLogicalReads * -1 ELSE TotalLogicalReads END,
        TotalWorkerTimeMs = CASE WHEN TotalWorkerTimeMs < 1 THEN TotalWorkerTimeMs * -1 ELSE TotalWorkerTimeMs END,
        TotalPhysicalReads = CASE WHEN TotalPhysicalReads < 1 THEN TotalPhysicalReads * -1 ELSE TotalPhysicalReads END,
        Servidor = CASE WHEN Servidor = 'PANVDBP373' THEN 'PANFDBP373CLA' 
                        WHEN Servidor = 'PANFDBH356TMP\SQLB' THEN 'PANFDBH356'
                        WHEN Servidor = 'PANVDBH2572\SQLC' THEN 'PANFDBH2572'
                        WHEN Servidor = 'AWSDBP11852\SQLA' THEN 'AWSDBP11852'
                        ELSE Servidor END
    WHERE CAST(dtcoleta AS DATE) = DATEADD(day, +1, @DtIni)
    
    --print 'Valores Ajustados no PANVDBA02'
    
    
    
    
    /* AJUSTA VALORES CPU */
    
    UPDATE dba.dba.dbo.baseline_TuningCpu_Consolidado
    SET 
     Servidor = CASE WHEN Servidor = 'PANVDBP373' THEN 'PANFDBP373CLA' 
                        WHEN Servidor = 'PANFDBH356TMP\SQLB' THEN 'PANFDBH356'
                        WHEN Servidor = 'PANVDBH2572\SQLC' THEN 'PANFDBH2572'
                        WHEN Servidor = 'AWSDBP11852\SQLA' THEN 'AWSDBP11852'
                        ELSE Servidor END
    WHERE CAST(DIA AS DATE) = CAST(DIA AS DATE)
    
    
    
    
    update dba.dba.dbo.servidores_tuning_rotina set sucesso = 1 where servidor = @@SERVERNAME

END
GO



USE [msdb]
GO

-- Remove o job se já existir
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'DBA_CargaTopQuery')
    EXEC msdb.dbo.sp_delete_job @job_name = N'DBA_CargaTopQuery'
GO

-- Cria o job
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job 
    @job_name = N'DBA_CargaTopQuery', 
    @enabled = 1, 
    @notify_level_eventlog = 0, 
    @notify_level_email = 2, 
    @notify_level_page = 2, 
    @delete_level = 0, 
    @category_name = N'[Uncategorized (Local)]', 
    @owner_login_name = N'Kerfisstjori', 
    @job_id = @jobId OUTPUT
GO

-- Define o servidor
DECLARE @server VARCHAR(255)
SELECT @server = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(255))

-- Adiciona o job ao servidor
EXEC msdb.dbo.sp_add_jobserver @job_name = N'DBA_CargaTopQuery', @server_name = @server


-- Adiciona o passo do job
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'DBA_CargaTopQuery', 
    @step_name = N'Coleta', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2, 
    @retry_attempts = 0, 
    @retry_interval = 0, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
        EXECUTE AS LOGIN = ''Kerfisstjori'';
        DECLARE @dtcoleta DATE = GETDATE() - 1;
        EXEC sp_CargaTopQuery @dtcoleta;
    ', 
    @database_name = N'DBA', 
    @flags = 0


-- Atualiza o job
EXEC msdb.dbo.sp_update_job 
    @job_name = N'DBA_CargaTopQuery', 
    @enabled = 1, 
    @start_step_id = 1, 
    @notify_level_eventlog = 0, 
    @notify_level_email = 2, 
    @notify_level_page = 2, 
    @delete_level = 0, 
    @description = N'', 
    @category_name = N'[Uncategorized (Local)]', 
    @owner_login_name = N'Kerfisstjori'


-- Gera horário aleatório baseado no nome do servidor
DECLARE @horaInicio INT, @horaFim INT;

IF @server LIKE '%dbp%'
BEGIN
    SET @horaInicio = 20;
    SET @horaFim = 22;
END
ELSE IF @server LIKE '%dbh%'
BEGIN
    SET @horaInicio = 17;
    SET @horaFim = 17;
END
ELSE IF @server LIKE '%dbd%'
BEGIN
    SET @horaInicio = 18;
    SET @horaFim = 18;
END
ELSE
BEGIN
    -- Default para 20:00
    SET @horaInicio = 20;
    SET @horaFim = 20;
END

DECLARE @hora INT = @horaInicio + ABS(CHECKSUM(NEWID())) % (1 + @horaFim - @horaInicio);
DECLARE @minuto INT = (ABS(CHECKSUM(NEWID())) % 12) * 5;

-- Ajusta limites
IF @server LIKE '%dbp%' AND @hora = 22 AND @minuto > 30
    SET @minuto = 30;
IF @server LIKE '%dbh%' AND @minuto > 55
    SET @minuto = 55;
IF @server LIKE '%dbd%' AND @minuto > 30
    SET @minuto = 30;

-- Converte para HHMMSS
DECLARE @active_start_time INT = @hora * 10000 + @minuto * 100;

-- Cria o agendamento
DECLARE @schedule_id INT;
EXEC msdb.dbo.sp_add_jobschedule 
    @job_name = N'DBA_CargaTopQuery', 
    @name = N'Diario_Aleatorio', 
    @enabled = 1, 
    @freq_type = 4,  -- Diário
    @freq_interval = 1, 
    @active_start_date = 20250523, 
    @active_end_date = 99991231, 
    @active_start_time = @active_start_time,
    @schedule_id = @schedule_id OUTPUT;

-- Exibe o horário gerado
SELECT @server AS Servidor, @hora AS Hora, @minuto AS Minuto, @active_start_time AS HorarioFormatado, @schedule_id;
