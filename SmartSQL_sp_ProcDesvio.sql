USE [SmartSQL]
GO
/****** Object:  StoredProcedure [dbo].[sp_ProcDesvio]    Script Date: 17/06/2025 13:59:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_ProcDesvio] @dataAtual DATE, @dataComparado DATE AS 
BEGIN

    
    drop table if exists dba..ProcsVariacao
    
    -- Captura a última hora com dados disponíveis na data atual
    DECLARE @horaLimite TIME;
    
    SELECT TOP 1 @horaLimite = CAST(dtcoleta as TIME)
    FROM dba..Baseline_Procstats
    WHERE dtcoleta >= @dataAtual AND dtcoleta < DATEADD(DAY, 1, @dataAtual)
    ORDER BY dtcoleta DESC;


    DECLARE @dataHoraComparada DATETIME;
    SET @dataHoraComparada = CAST(@dataComparado AS DATETIME) + CAST(@horaLimite AS DATETIME);


    
    
    WITH Atual AS (
        SELECT DbName, 
               ObjectName, 
               AVG(AvgTimeMs) AS AvgTimeMs, 
               SUM(ExecCount) AS ExecCount
        FROM dba..Baseline_Procstats
        WHERE dtcoleta >= @dataAtual 
          AND dtcoleta < DATEADD(DAY, 1, @dataAtual)
          --AND AvgTimeMs > 1000
        GROUP BY DbName, ObjectName
        --HAVING SUM(ExecCount) > 50
    ),
    Comparada AS (
        SELECT DbName, 
               ObjectName, 
               AVG(AvgTimeMs) AS AvgTimeMs, 
               SUM(ExecCount) AS ExecCount
        FROM dba..Baseline_Procstats
        WHERE dtcoleta >= @dataComparado 
          AND dtcoleta < @dataHoraComparada
          --AND AvgTimeMs > 1000
        GROUP BY DbName, ObjectName
        --HAVING SUM(ExecCount) > 50
    )
    
    SELECT 
        A.DbName,
        A.ObjectName,
        A.AvgTimeMs AS AvgTimeAtual,
        ISNULL(C.AvgTimeMs,0) AS AvgTimeAnterior,
        A.ExecCount AS ExecAtual,
        ISNULL(C.ExecCount,0) AS ExecAnterior,
        CASE 
            WHEN C.ObjectName IS NULL OR C.AvgTimeMs = 0 OR C.ExecCount = 0 THEN 'Novo'
            WHEN ABS(A.AvgTimeMs - C.AvgTimeMs) / C.AvgTimeMs > 0.7 THEN 'Variação AvgTime'
            WHEN ABS(A.ExecCount - C.ExecCount) / C.ExecCount > 0.7 THEN 'Variação ExecCount'
        END AS TipoMudanca
    into dba..ProcsVariacao
    FROM Atual A
    LEFT JOIN Comparada C
        ON A.DbName = C.DbName AND A.ObjectName = C.ObjectName
    WHERE 
        C.ObjectName IS NULL
        OR (C.AvgTimeMs > 0 AND ABS(A.AvgTimeMs - C.AvgTimeMs) / C.AvgTimeMs > 0.7)
        OR (C.ExecCount > 0 AND ABS(A.ExecCount - C.ExecCount) / C.ExecCount > 0.7)
    ORDER BY 7;
    
    
    alter table dba..ProcsVariacao add create_date datetime
    alter table dba..ProcsVariacao add modify_date datetime
    
    delete from dba..ProcsVariacao where AvgTimeAtual < 1000 or ExecAtual < 50
    
    DECLARE @dbName varchar(100), @objName varchar(200), @cmd nvarchar(max)
    
    DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
        select distinct DbName, ObjectName from dba..ProcsVariacao
    OPEN c
    
    FETCH NEXT FROM c INTO @dbName, @objName ;
    
    
    WHILE @@fetch_status = 0  
    BEGIN  
       
      SET @cmd = '
      UPDATE a
      SET 
          a.create_date = b.create_date, 
          a.modify_date = b.modify_date
      FROM dba..ProcsVariacao a
      INNER JOIN (
          SELECT ''' + @dbName + ''' AS dbName, 
                 ''' + @objName + ''' AS objName, 
                 create_date, 
                 modify_date 
          FROM ' + QUOTENAME(@dbName) + '.sys.procedures 
          WHERE name = ''' + @objName + '''
      ) b
      ON a.dbName = b.dbName 
      AND a.ObjectName = b.objName;
      ';
    
        -- Executa o comando
        EXEC sp_executesql @cmd;
    
        FETCH NEXT FROM c INTO @dbName, @objName;
    
    END
    CLOSE C  
    DEALLOCATE c
    
    select * from dba..ProcsVariacao 
	order by TipoMudanca, create_date desc, modify_date desc

END



