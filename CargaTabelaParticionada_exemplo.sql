--PRE-PROD

USE [crivoveic]
GO

--DROP PARTITION SCHEME [PartRangeMes_NEW]
CREATE PARTITION FUNCTION [FnPartRangeMes_NEW](int) AS RANGE LEFT FOR VALUES (35,36,37,38,41,42,43,44,
																			  45,46,47,48,51,52,53,54,
																			  55,56,57,58,59,60,61,62,
																			  63,64,65,66,67,68,69,70)
GO

--DROP PARTITION FUNCTION [FnPartRangeMes_NEW]
CREATE PARTITION SCHEME [PartRangeMes_NEW] AS PARTITION [FnPartRangeMes_NEW] ALL TO ([PRIMARY]) 
GO


--drop table [LogParametro_NEW]


CREATE TABLE [dbo].[LogParametro_NEW](
	[ID_logparametro] [bigint] IDENTITY(1,1) NOT NULL,
	[Data] [datetime] NULL,
	[ID_log] [int] NOT NULL,
	[Parametro] [varchar](255) NOT NULL,
	[Valor] [varchar](500) NOT NULL,
	[ValorLimpo]  AS (replace(replace(replace([Valor],'.',''),'/',''),'-','')),
	[id_TipoParametro] [int] NOT NULL,
	[OrdemAtribuicao] [int] NULL,
	[DataPartition]  AS ((datepart(month,[Data])*(10)+((1)+abs(checksum([ID_logparametro]))%(8)))+case when datepart(day,[Data])<=(15) then (0) else (4) end) PERSISTED NOT NULL,
 CONSTRAINT [PK_LogParametro_NEW] PRIMARY KEY NONCLUSTERED 
(
	[ID_logparametro] ASC,
	[DataPartition] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PartRangeMes_NEW]([DataPartition]),
 CONSTRAINT [IX_LogParametro_NEW] UNIQUE CLUSTERED 
(
	[ID_log] DESC,
	[Parametro] ASC,
	[Valor] ASC,
	[ID_logparametro] ASC,
	[DataPartition] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PartRangeMes_NEW]([DataPartition])
) ON [PartRangeMes_NEW]([DataPartition])




--Script de carga
--CARGA

/*

USE CRIVOVEIC
GO


ALTER procedure sp_carrega_logparametro as
BEGIN
-- ***** -- Tabela de log
DROP TABLE IF EXISTS ##log_carga_logparametro
CREATE TABLE ##log_carga_logparametro ( iteracao int identity(1,1), dt_execucao datetime default getdate(), qtd_alteracoes int, idPart int) 

DECLARE @trowcount int = 1 , @idMin bigint, @idMax bigint, @part int, @isFirist int = 0

SET IDENTITY_INSERT logparametro_new ON

--Cursor para cada DataPartition que precisa ser carregado (últimos 4)
DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
	SELECT DISTINCT CAST(rv.value as int)
	FROM sys.partitions p
	INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
	INNER JOIN sys.objects o ON p.object_id = o.object_id
	INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id
	INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
	INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id
	INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
	INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
	LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
	WHERE o.object_id = OBJECT_ID('logparametro') and p.rows > 0 order by 1 asc
OPEN c
FETCH NEXT FROM c INTO @part ;

WHILE @@fetch_status = 0  
BEGIN
	-- ***** -- Se nao tem registro ainda na tabela nova, pega o min e max da tabela antiga
	IF NOT EXISTS(select 1 from logparametro_new)
	BEGIN
		select @idMin = min(ID_logparametro)-1 FROM logparametro where DataPartition = @part OPTION (RECOMPILE)
		select @idMax = max(ID_logparametro) FROM logparametro where DataPartition = @part OPTION (RECOMPILE)
	END
	ELSE
	-- ***** -- Se ja foi carregado algo na tabela nova, pega o min e max dela
	BEGIN
		select @idMin = max(ID_logparametro) FROM logparametro_new
		select @idMax=@idMin+400000
	END
	
	
	WHILE (@trowcount>0)    
	BEGIN
		-- ***** -- Insere 100.000 registros (400.000/4 particoes = 100.000)
	    insert into logparametro_new (ID_logparametro, Data, ID_log, Parametro, Valor, id_TipoParametro, OrdemAtribuicao)
	    select TOP 400000 p.ID_logparametro, 
					      p.Data, 
					      p.ID_log, 
					      p.Parametro, 
					      p.Valor, 
					      p.id_TipoParametro, 
					      p.OrdemAtribuicao
		from logparametro p
		left join logparametro_new n
			on p.ID_log = n.ID_log and 
			   p.Parametro = n.Parametro and
			   p.Valor = n.Valor and
			   p.ID_logparametro = n.ID_logparametro 
		where p.ID_logparametro > @idMin and 
			  p.ID_logparametro <= @idMax and
			  p.DataPartition = @part and
			  n.ID_logparametro is null
		Order by ID_logparametro
		OPTION(RECOMPILE)
	
		SET @trowcount = @@ROWCOUNT 
	
		-- ***** -- Valida se a execução foi com o min e max da tabela antiga
		-- ***** -- Se sim, pega o min e max da logparametro_new
		if @isFirist = 0
		begin
			select @idMin = max(ID_logparametro) FROM logparametro_new
			select @idMax=@idMin+400000
			select @isFirist = 1
		end
		else
		-- ***** -- Senão pega o min e max com base no calculo abaixo
		begin
			select @idMin = @idMax
			select @idMax+=400000
		end
	
		INSERT INTO ##log_carga_logparametro (qtd_alteracoes, idPart) VALUES (@trowcount, @part)
	
	END    
	
	
	    FETCH NEXT FROM c INTO @part;
	
END
CLOSE C  
DEALLOCATE c

SET IDENTITY_INSERT logparametro_new OFF


END

*/



exec crivoveic..sp_carrega_logparametro





--estimar o tempo

--ACOMPANHAMENTO

/*
CREATE OR ALTER PROCEDURE sp_acompanhaCarga_logparametro AS
BEGIN

    -- Cria a tabela temporária para armazenar a média do tempo de execução por iteração
    DROP TABLE IF EXISTS #AvgTempoSec;

    -- Calcula a média do tempo de execução por iteração
    ;WITH IterationTimes AS (
        SELECT iteracao,
               dt_execucao,
               IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', dt_execucao, LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)) AS prev_dt_execucao,
               qtd_alteracoes,
               DATEDIFF(SECOND, IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', dt_execucao, LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)), dt_execucao) AS tempo_sec,
               idPart
        FROM ##log_carga_logparametro
        WHERE dt_execucao > DATEADD(minute, -10, GETDATE())
    )

    -- Calcula a média do tempo de execução por iteração
    SELECT AVG(tempo_sec) AS avg_tempo_sec INTO #AvgTempoSec
    FROM IterationTimes;

    -- Calcula o total de alterações
    DECLARE @total_iterations_New BIGINT;
    DECLARE @logparametro_info_New TABLE (
        name NVARCHAR(128),
        rows BIGINT,
        reserved NVARCHAR(128),
        data NVARCHAR(128),
        index_size NVARCHAR(128),
        unused NVARCHAR(128)
    );

    INSERT INTO @logparametro_info_New
    EXEC sp_spaceused 'logparametro_New';

    SELECT @total_iterations_New = rows FROM @logparametro_info_New;

    -- Obtém o número total de linhas da tabela logparametro usando sp_spaceused
    DECLARE @total_iterations BIGINT;
    DECLARE @logparametro_info TABLE (
        name NVARCHAR(128),
        rows BIGINT,
        reserved NVARCHAR(128),
        data NVARCHAR(128),
        index_size NVARCHAR(128),
        unused NVARCHAR(128)
    );

    INSERT INTO @logparametro_info
    EXEC sp_spaceused 'logparametro';

    SELECT @total_iterations = rows - @total_iterations_New FROM @logparametro_info;

    -- Calcula o total de iterações
    DECLARE @total_iterations_count BIGINT = @total_iterations / 100000;

    -- Define a média de tempo por iteração
    DECLARE @avg_tempo_sec FLOAT;

    ;WITH Temp AS (
        SELECT 
            DATEDIFF(SECOND, 
                IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', 
                    dt_execucao, 
                    LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)), 
                dt_execucao) AS tempo_sec
        FROM 
            ##log_carga_logparametro
    )
    SELECT 
        @avg_tempo_sec = AVG(tempo_sec)
    FROM 
        Temp;

    -- Estima o tempo total em segundos
    DECLARE @estimated_total_time_sec BIGINT;
    SELECT @estimated_total_time_sec = @total_iterations_count * @avg_tempo_sec;

    -- Converte o tempo total para horas e minutos
    DECLARE @estimated_total_time_hours FLOAT = @estimated_total_time_sec / 3600.0;
    DECLARE @estimated_total_time_minutes INT = CAST((@estimated_total_time_hours * 60) AS INT) % 60;
    DECLARE @estimated_total_time_hours_only INT = CAST(@estimated_total_time_hours AS INT);

    DECLARE @processed_time_sec BIGINT;
    SELECT @processed_time_sec = SUM(tempo_sec)
    FROM (
        SELECT DATEDIFF(SECOND, IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', dt_execucao, LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)), dt_execucao) AS tempo_sec
        FROM ##log_carga_logparametro
    ) tabela;

    -- Converte o tempo total para horas e minutos
    DECLARE @processed_time_hours FLOAT = @processed_time_sec / 3600.0;
    DECLARE @processed_time_minutes INT = CAST((@processed_time_hours * 60) AS INT) % 60;
    DECLARE @processed_time_hours_only INT = CAST(@processed_time_hours AS INT);

    -- Calcula o tempo restante em segundos
    DECLARE @remaining_time_sec BIGINT;
    SELECT @remaining_time_sec = @estimated_total_time_sec - @processed_time_sec;

    -- Converte o tempo restante para horas e minutos
    DECLARE @remaining_time_hours FLOAT = @remaining_time_sec / 3600.0;
    DECLARE @remaining_time_minutes INT = CAST((@remaining_time_hours * 60) AS INT) % 60;
    DECLARE @remaining_time_hours_only INT = CAST(@remaining_time_hours AS INT);

    -- Exibe o resultado em uma única coluna
    SELECT 
        CAST(@estimated_total_time_hours_only AS VARCHAR) + ' horas e ' + CAST(@estimated_total_time_minutes AS VARCHAR) + ' minutos' AS EstimatedTotalTime,
        CAST(@processed_time_hours_only AS VARCHAR) + ' horas e ' + CAST(@processed_time_minutes AS VARCHAR) + ' minutos' AS ProcessedTime,
        CAST(@remaining_time_hours_only AS VARCHAR) + ' horas e ' + CAST(@remaining_time_minutes AS VARCHAR) + ' minutos' AS RemainingTime,
        @avg_tempo_sec AS [AvgIterationTimeLast10Min];

    -- Exibe informações adicionais
    SELECT DISTINCT o.name as table_name, ps.name as PScheme, f.name as PFunction, rv.value as partition_range, fg.name as file_groupName, p.partition_number, p.rows as number_of_rows
    FROM sys.partitions p
    INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    INNER JOIN sys.objects o ON p.object_id = o.object_id
    INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id
    INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
    INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id
    INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
    INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
    WHERE o.object_id = OBJECT_ID('logparametro_new') and p.rows > 0;

    SELECT TOP 5 iteracao,
           dt_execucao,
           IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', dt_execucao, LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)) AS prev_dt_execucao,
           qtd_alteracoes,
           DATEDIFF(SECOND, IIF(LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao) = '1900-01-01 00:00:00.000', dt_execucao, LAG(dt_execucao, 1,0) OVER (ORDER BY dt_execucao)), dt_execucao) AS tempo_sec,
           idPart
    FROM ##log_carga_logparametro
    ORDER BY 1 DESC;
END


*/

exec crivoveic..sp_acompanhaCarga_logparametro



