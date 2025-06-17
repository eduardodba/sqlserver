USE [SmartSQL]
GO
/****** Object:  StoredProcedure [dbo].[sp_PerfCounters]    Script Date: 17/06/2025 13:59:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER     PROCEDURE [dbo].[sp_PerfCounters] @counterName VARCHAR(50), @dataAtual DATE, @dataComparado DATE
AS
BEGIN
    ;WITH Base AS (
        SELECT 
            DtColeta,
            DATEPART(HOUR, DtColeta) AS Hora,
            Valor
        FROM [DBA].[dbo].[Baseline_PerfMonData]
        WHERE counterName = @counterName
    ),
    DatasComparadas AS (
        SELECT 
            Hora,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataAtual THEN Valor END) AS MediaAtual,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataComparado THEN Valor END) AS MediaComparada
        FROM Base
        WHERE CAST(DtColeta AS DATE) IN (@dataAtual, @dataComparado)
        GROUP BY Hora
    )
SELECT 
    'Hora' AS HoraColeta,
    Hora,
    CAST(MediaAtual AS INT) AS MediaAtual,
    CAST(MediaComparada AS INT) AS MediaComparada,
    CASE 
        WHEN CAST(MediaAtual AS INT) = 0 AND CAST(MediaComparada AS INT) = 0 THEN 0.00
        ELSE CAST(ROUND((
            CAST(MediaAtual AS INT) - 
            CASE WHEN CAST(MediaComparada AS INT) = 0 THEN 1 ELSE CAST(MediaComparada AS INT) END
        ) * 100.0 / 
        CASE WHEN CAST(MediaComparada AS INT) = 0 THEN 1 ELSE CAST(MediaComparada AS INT) END, 2) AS DECIMAL(10,2))
    END AS VariacaoPercentual
FROM DatasComparadas
WHERE MediaAtual IS NOT NULL
ORDER BY Hora;




END
