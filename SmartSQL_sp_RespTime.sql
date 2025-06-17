USE [SmartSQL]
GO
/****** Object:  StoredProcedure [dbo].[sp_RespTime]    Script Date: 17/06/2025 13:59:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER     PROCEDURE [dbo].[sp_RespTime]
    @dataAtual DATE,
    @dataComparado DATE
AS
BEGIN
    ;WITH Base AS (
        SELECT 
            DtColeta,
            DATEPART(HOUR, DtColeta) AS Hora,
            P90_Ms,
            P99_Ms,
            QtdPlans
        FROM [DBA].[dbo].[Baseline_RespTime]
    ),
    DatasComparadas AS (
        SELECT 
            Hora,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataAtual THEN P90_Ms END) AS MediaAtual_P90,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataAtual THEN P99_Ms END) AS MediaAtual_P99,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataAtual THEN QtdPlans END) AS MediaAtual_QtdPlans,

            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataComparado THEN P90_Ms END) AS MediaComparada_P90,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataComparado THEN P99_Ms END) AS MediaComparada_P99,
            AVG(CASE WHEN CAST(DtColeta AS DATE) = @dataComparado THEN QtdPlans END) AS MediaComparada_QtdPlans
        FROM Base
        WHERE CAST(DtColeta AS DATE) IN (@dataAtual, @dataComparado)
        GROUP BY Hora
    )
    SELECT 
        'Hora' AS HoraColeta,
        Hora,
        MediaAtual_P90,
        MediaComparada_P90,
        CAST(
            CASE 
                WHEN MediaComparada_P90 = 0 THEN NULL
                ELSE ROUND(((CAST(MediaAtual_P90 AS FLOAT) - CAST(MediaComparada_P90 AS FLOAT)) / CAST(MediaComparada_P90 AS FLOAT)) * 100.0, 2)
            END AS DECIMAL(10,2)
        ) AS VariacaoPercentual_P90,

        MediaAtual_P99,
        MediaComparada_P99,
        CAST(
            CASE 
                WHEN MediaComparada_P99 = 0 THEN NULL
                ELSE ROUND(((CAST(MediaAtual_P99 AS FLOAT) - CAST(MediaComparada_P99 AS FLOAT)) / CAST(MediaComparada_P99 AS FLOAT)) * 100.0, 2)
            END AS DECIMAL(10,2)
        ) AS VariacaoPercentual_P99,

        MediaAtual_QtdPlans,
        MediaComparada_QtdPlans,
        CAST(
            CASE 
                WHEN MediaComparada_QtdPlans = 0 THEN NULL
                ELSE ROUND(((CAST(MediaAtual_QtdPlans AS FLOAT) - CAST(MediaComparada_QtdPlans AS FLOAT)) / CAST(MediaComparada_QtdPlans AS FLOAT)) * 100.0, 2)
            END AS DECIMAL(10,2)
        ) AS VariacaoPercentual_QtdPlans

    FROM DatasComparadas
    WHERE MediaAtual_P90 IS NOT NULL
    ORDER BY Hora;
END


