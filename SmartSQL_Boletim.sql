USE smartsql
GO


CREATE OR ALTER PROCEDURE TopTables @servidor varchar(100) = null, @cargaFull int = 0 as
BEGIN

   
    DECLARE @nServidor varchar(100) = CASE 
                                      WHEN CHARINDEX(' - ', @servidor) > 0 
                                      THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                      ELSE @servidor END
    
    
    IF @cargaFull = 1
    BEGIN

        drop table if exists dba..TopTableAtual
        drop table if exists dba..DatabaseSizeAtual

        --Pega tamanho da ultima coleta
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                TABLE_DS, 
                SUM(TBL_ROWS) TBL_ROWS, 
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA
        into dba..TopTableAtual
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND NM_SERVIDOR like '%db%'
        GROUP BY NM_SERVIDOR,
                 TABLE_DS, 
                 DATA,
                 DATABASE_DS
        
        
        
        SELECT	dba.[DW].[dim_tempo].NM_SERVIDOR,
                dba.[DW].[dim_database].DATABASE_DS,
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB
        into dba..DatabaseSizeAtual
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        INNER JOIN dba..TopTableAtual tta
            ON tta.DATABASE_DS = dba.[DW].[dim_database].DATABASE_DS and tta.TABLE_DS = dba.[DW].[dim_table].TABLE_DS
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND dba.[DW].[dim_tempo].NM_SERVIDOR like '%db%'
        GROUP BY dba.[DW].[dim_tempo].NM_SERVIDOR,
                 dba.[DW].[dim_database].DATABASE_DS
    END
    
    

    --Top Tabelas
    select top 5 
           tb.database_ds [Database],
           tb.table_ds [Tabela],
           tb.TBL_ROWS [Linhas],
           tb.RESERVED_IN_GB [Size GB],
           CAST(CAST(tb.RESERVED_IN_GB as decimal(10,2)) / CAST(db.RESERVED_IN_GB as decimal(10,2)) * 100 AS DECIMAL(15,2)) AS [% da Base]
    from dba..TopTableAtual tb
    inner join dba..DatabaseSizeAtual db
        on tb.Nm_Servidor = db.Nm_Servidor and
           tb.DATABASE_DS = db.DATABASE_DS
    where tb.Nm_Servidor = @servidor
    order by 4 desc


END





exec smartsql..TopTables @cargaFull = 1 --CargaFull
exec smartsql..TopTables @servidor = 'PANFDBP4001B' --Busca por servidor


GO


USE smartsql
GO
CREATE OR ALTER PROCEDURE TopDatabases @servidor varchar(100) as
BEGIN

DECLARE @nServidor varchar(100) = CASE 
                                  WHEN CHARINDEX(' - ', @servidor) > 0 
                                  THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                  ELSE @servidor END




--Pega tamanho da ultima coleta
declare @atual as table (DATABASE_DS varchar(100), TBL_ROWS bigint, RESERVED_IN_GB bigint, coleta date)
insert into @atual
SELECT	DATABASE_DS,
        SUM(TBL_ROWS) TBL_ROWS, 
        SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
        DATA
FROM dba.[DW].[fato_table_volume]
INNER JOIN dba.[DW].[dim_tempo]
    ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
INNER JOIN dba.[DW].[dim_database]
    ON [fato_table_volume].sk_database = [dim_database].sk_database
INNER JOIN dba.[DW].[dim_table]
    ON [dim_table].sk_table = [fato_table_volume].sk_table
WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS) AND 
      NM_SERVIDOR = @nServidor
GROUP BY DATA,
         DATABASE_DS


--Top Tabelas
select top 5 
       database_ds [Database],
       TBL_ROWS [Linhas],
       RESERVED_IN_GB [Size GB]
from @atual 
order by 3 desc

END


exec smartSQL.dbo.TopDatabases @servidor = 'PANFDBP4001B'


GO





USE smartsql
GO
CREATE OR ALTER PROCEDURE TopTableGrowth @servidor varchar(100) = null, @cargaFull int = 0 as
BEGIN
	
	DECLARE @nServidor varchar(100) = CASE 
                                  WHEN CHARINDEX(' - ', @servidor) > 0 
                                  THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                  ELSE @servidor END

    IF @cargaFull = 1
    BEGIN
        
        drop table if exists dba..cargaAtual;
        drop table if exists dba..cargaPassado;
        drop table if exists dba..topGrowthTables;
        drop table if exists dba..MaxSkTempoPorDia;
        drop table if exists dba..VolumePorDia;
        drop table if exists dba..PrimeiraData;
        drop table if exists dba..VolumeComInicial;
        
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                TABLE_DS, 
                SUM(TBL_ROWS) TBL_ROWS, 
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA
        into dba..cargaAtual
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND NM_SERVIDOR like '%DB%'
        GROUP BY NM_SERVIDOR, 
                 TABLE_DS, 
                 DATA,
                 DATABASE_DS
        
        
        
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                TABLE_DS, 
                SUM(TBL_ROWS) TBL_ROWS, 
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA
        into dba..cargaPassado
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS and data <= DATEADD(DAY,-30,GETDATE())) AND NM_SERVIDOR like '%DB%'
        GROUP BY NM_SERVIDOR,
                 TABLE_DS, 
                 DATA, 
                 DATABASE_DS
        
        
        
        --Tabelas que mais cresceram nos ultimos 30 dias
        ;WITH DadosComRanking AS (
            SELECT  
                a.NM_SERVIDOR,
                a.DATABASE_DS AS [Database],
                a.TABLE_DS AS [Tabela], 
                a.RESERVED_IN_GB - p.RESERVED_IN_GB AS [Aumento_xGB], 
                ROW_NUMBER() OVER (ORDER BY a.RESERVED_IN_GB - p.RESERVED_IN_GB DESC) AS [TopGrowth],
                ROW_NUMBER() OVER (PARTITION BY a.NM_SERVIDOR ORDER BY a.RESERVED_IN_GB - p.RESERVED_IN_GB DESC) AS [TopPorServidor]
            FROM dba..cargaAtual a
            INNER JOIN dba..cargaPassado p
                ON a.TABLE_DS = p.TABLE_DS 
                AND a.DATABASE_DS = p.DATABASE_DS
                AND a.NM_SERVIDOR = p.NM_SERVIDOR
            WHERE CAST((CAST(a.RESERVED_IN_GB - p.RESERVED_IN_GB AS decimal)) / (a.RESERVED_IN_GB + 1) * 100 AS NUMERIC(15,2)) > 0
        )
        SELECT *
        into dba..topGrowthTables
        FROM DadosComRanking
        WHERE TopPorServidor < 6;
        
        
        
        -- Etapa 0: Obter o maior sk_tempo por dia
        SELECT 
            NM_SERVIDOR,
            CONVERT(DATE, data) AS Dia,
            MAX(sk_tempo) AS sk_tempo
        INTO dba..MaxSkTempoPorDia
        FROM dba.DW.dim_tempo
        WHERE data >= DATEADD(DAY, -30, GETDATE()) AND NM_SERVIDOR like '%DB%' 
        GROUP BY NM_SERVIDOR, CONVERT(DATE, data);
        
        
        
        -- Etapa 1: Tamanho da tabela por dia (usando apenas o maior sk_tempo de cada dia)
        SELECT
            tgt.NM_SERVIDOR,
            DATABASE_DS,
            TABLE_DS,
            SUM(TBL_ROWS) AS TBL_ROWS,
            CAST(SUM(RESERVED_IN_KB) / 1024.0 / 1024.0 AS INT) AS RESERVED_IN_GB,
            DATA,
            tgt.TopGrowth
        INTO dba..VolumePorDia
        FROM dba.DW.fato_table_volume
        INNER JOIN dba.DW.dim_tempo
            ON fato_table_volume.sk_tempo = dim_tempo.sk_tempo
        INNER JOIN dba.DW.dim_database
            ON fato_table_volume.sk_database = dim_database.sk_database
        INNER JOIN dba.DW.dim_table
            ON dim_table.sk_table = fato_table_volume.sk_table
        INNER JOIN dba..topGrowthTables tgt
            ON dba.DW.dim_tempo.NM_SERVIDOR = tgt.Nm_Servidor and tgt.[Database] = DATABASE_DS AND tgt.[Tabela] = TABLE_DS
        INNER JOIN dba..MaxSkTempoPorDia maxDia
            ON dim_tempo.sk_tempo = maxDia.sk_tempo
        GROUP BY tgt.NM_SERVIDOR, 
                 TABLE_DS, 
                 DATA, 
                 DATABASE_DS, 
                 tgt.TopGrowth;
        
        
        -- Etapa 2: Primeira data por tabela
        SELECT
            NM_SERVIDOR,
            DATABASE_DS,
            TABLE_DS,
            MIN(DATA) AS PRIMEIRA_DATA
        INTO dba..PrimeiraData
        FROM dba..VolumePorDia
        GROUP BY NM_SERVIDOR, 
                 DATABASE_DS, 
                 TABLE_DS;
        
        
        
        
        -- Etapa 3: Volume da primeira data
        SELECT
            vpd.NM_SERVIDOR,
            vpd.DATABASE_DS,
            vpd.TABLE_DS,
            vpd.DATA,
            vpd.RESERVED_IN_GB,
            vpd.TopGrowth,
            pd.PRIMEIRA_DATA,
            vi.RESERVED_IN_GB AS RESERVED_IN_GB_INICIAL
        INTO dba..VolumeComInicial
        FROM dba..VolumePorDia vpd
        INNER JOIN dba..PrimeiraData pd
            ON vpd.NM_SERVIDOR = pd.NM_SERVIDOR AND vpd.DATABASE_DS = pd.DATABASE_DS AND vpd.TABLE_DS = pd.TABLE_DS
        INNER JOIN dba..VolumePorDia vi
            ON vi.NM_SERVIDOR = pd.NM_SERVIDOR AND vi.DATABASE_DS = pd.DATABASE_DS AND vi.TABLE_DS = pd.TABLE_DS AND vi.DATA = pd.PRIMEIRA_DATA;
    END    
    
    -- Etapa 4: Resultado final com cálculo da porcentagem
    SELECT
        NM_SERVIDOR,
        DATABASE_DS,
        TABLE_DS,
        RESERVED_IN_GB,
        DATA,
        TopGrowth,
        CAST(
            CASE 
                WHEN DATA = PRIMEIRA_DATA THEN 0
                WHEN RESERVED_IN_GB_INICIAL = 0 THEN 0
                ELSE ((RESERVED_IN_GB - RESERVED_IN_GB_INICIAL) * 100.0 / RESERVED_IN_GB_INICIAL)
            END AS INT
        ) AS PERCENTUAL_CRESCIMENTO
    FROM dba..VolumeComInicial
    WHERE NM_SERVIDOR = @nServidor

END





exec smartsql..TopTableGrowth @cargaFull = 1 --CargaFull
exec smartsql..TopTableGrowth @servidor = 'PANFDBP4001B' --Busca por servidor














USE smartsql
GO
CREATE OR ALTER PROCEDURE UnusedTables @servidor varchar(100) = null, @cargaFull int = 0 as
BEGIN

    DECLARE @nServidor varchar(100) = CASE 
                                      WHEN CHARINDEX(' - ', @servidor) > 0 
                                      THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                      ELSE @servidor END
    
    IF @cargaFull = 1
    BEGIN

        drop table if exists dba..UnusedTables
        --Consolida tabelas sem leitura / escrita
        SELECT 
            ut.[ServerName],
            ut.[ServiceName],
            ut.[DatabaseName],
            ut.[Tabela],
            ut.[Ultima_alteracao],
            ut.[Ultima_leitura]
        INTO #UltimoUsoTable
        FROM [dba].[ControlBD].[UsageTable] ut
        WHERE  (ISNULL(ut.[Ultima_alteracao], '2000-01-01') < GETDATE() - 30 
               AND ISNULL(ut.[Ultima_leitura], '2000-01-01') < GETDATE() - 30)
          AND CAST(ut.dtcoleta AS DATE) = (
              SELECT CAST(MAX(aux.dtcoleta) AS DATE)
              FROM [dba].[ControlBD].[UsageTable] aux 
              WHERE aux.[ServerName] = ut.[ServerName]);
        
        
        --Pega o Tamanho das tabelas sem uso
        SELECT
            ddb.DATABASE_DS,
            dt.TABLE_DS, 
            SUM(ftv.TBL_ROWS) AS TBL_ROWS, 
            SUM(ftv.RESERVED_IN_KB) / 1024 AS RESERVED_IN_GB, 
            dtp.DATA
        INTO #VolumeTabela
        FROM dba.[DW].[fato_table_volume] ftv
        INNER JOIN dba.[DW].[dim_tempo] dtp 
            ON ftv.sk_tempo = dtp.sk_tempo
        INNER JOIN dba.[DW].[dim_database] ddb
            ON ftv.sk_database = ddb.sk_database
        INNER JOIN dba.[DW].[dim_table] dt 
            ON dt.sk_table = ftv.sk_table
        WHERE dtp.sk_tempo = 
                  (SELECT MAX(sk_tempo) 
                  FROM dba.dw.dim_tempo 
                  WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND NM_SERVIDOR like '%db%'
        GROUP BY dt.TABLE_DS, dtp.DATA, ddb.DATABASE_DS;
        
        
       
    
        --Mostra tabelas e tamanho
        SELECT 
            u.[ServerName],
            u.[ServiceName],
            u.[DatabaseName],
            u.[Tabela],
            u.[Ultima_alteracao],
            u.[Ultima_leitura],
            ISNULL(v.RESERVED_IN_GB, 0) AS RESERVED_IN_GB,
            ISNULL(v.TBL_ROWS, 0) AS TBL_ROWS
        into dba..UnusedTables
        FROM #UltimoUsoTable u
        LEFT JOIN #VolumeTabela v
            ON u.DatabaseName = v.DATABASE_DS AND 
               u.Tabela = v.TABLE_DS
        

    END

    SELECT * FROM dba..UnusedTables WHERE ServerName = @nServidor ORDER BY 7 DESC, DatabaseName;


END






exec smartsql..UnusedTables @cargaFull = 1 --CargaFull
exec smartsql..UnusedTables @servidor = 'PANFDBP4001B' --Busca por servidor




















USE smartsql
GO
CREATE OR ALTER PROCEDURE UnusedIndexes @servidor varchar(100) = null, @cargaFull int = 0 as
BEGIN

    
    DECLARE @nServidor varchar(100) = CASE 
                                      WHEN CHARINDEX(' - ', @servidor) > 0 
                                      THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                      ELSE @servidor END

    IF @cargaFull = 1
    BEGIN
        
        drop table if exists dba..UnusedIndexes
        
        --Pega o tamanho dos indices sem leitura nos ultimos 30 dias
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                TABLE_DS, 
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA,
                [INDEX_DS]
        INTO #VolumeIndex
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND NM_SERVIDOR like '%db%'
        GROUP BY NM_SERVIDOR,
                 TABLE_DS, 
                 DATA,
                 DATABASE_DS,
                 [INDEX_DS]
        
        
        --Consolida index sem leitura nos ultimos 30 dias
        SELECT [ServerName]
              ,[ServiceName]
              ,[DatabaseName]
              ,[TableName]
              ,[IndexName]
              ,[seeks_30]
              ,[scans_30]
              ,[updates_3]
        INTO #UltimoUsoIndex
        FROM [dba].[ControlBD].[UsageIndex]
        WHERE --[ServerName] like @servidorNew + '%' AND
              ([seeks_30] = 0 AND [scans_30] = 0)
        
        
       
        
        
        
        --Mostra index e tamanho
        SELECT DISTINCT
            NM_SERVIDOR AS [ServerName],
            u.[DatabaseName],
            u.[TableName],
            u.[IndexName],
            ISNULL(v.RESERVED_IN_GB, 0) AS RESERVED_IN_GB
        into dba..UnusedIndexes
        FROM #UltimoUsoIndex u
        LEFT JOIN #VolumeIndex v
            ON u.DatabaseName = v.DATABASE_DS AND 
               u.[TableName] = v.TABLE_DS AND 
               u.[IndexName] = v.[INDEX_DS]
        ORDER BY 5 DESC, u.DatabaseName;

    END


     SELECT * FROM dba..UnusedIndexes WHERE ServerName like CASE 
                WHEN RIGHT(@nServidor, 1) COLLATE Latin1_General_BIN IN ('A','B','C','D','E','F','G','H') 
                    THEN LEFT(@nServidor, LEN(@nServidor) - 1)
                ELSE @nServidor
            END + '%' ORDER BY 5 DESC, DatabaseName;


END



exec smartsql..UnusedIndexes @cargaFull = 1 --CargaFull
exec smartsql..UnusedIndexes @servidor = 'PANFDBP4001B' --Busca por servidor


GO








USE smartsql
GO

CREATE OR ALTER PROCEDURE DatabaseGrowth @servidor varchar(100) = null, @cargaFull int = 0 as
BEGIN

    DECLARE @nServidor varchar(100) = CASE 
                                  WHEN CHARINDEX(' - ', @servidor) > 0 
                                  THEN LEFT(@servidor, CHARINDEX(' - ', @servidor) - 1)
                                  ELSE @servidor END

    IF @cargaFull = 1
    BEGIN

        drop table if exists dba..cargaAtualDatabase
        drop table if exists dba..cargaPassadoDatabase
        drop table if exists dba..topGrowthDatabases
        drop table if exists dba..MaxSkTempoPorDiaDatabase
        drop table if exists dba..VolumePorDiaDatabase
        drop table if exists dba..PrimeiraDataDatabase
        drop table if exists dba..VolumeComInicialDatabase
        
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA
        into dba..cargaAtualDatabase
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS AND DATA_HORA > GETDATE()-30) AND NM_SERVIDOR like '%db%'
        GROUP BY NM_SERVIDOR,
                 DATA,
                 DATABASE_DS
        
        
        
        
        SELECT	NM_SERVIDOR,
                DATABASE_DS,
                SUM(RESERVED_IN_KB) / 1024 / 1024 RESERVED_IN_GB, 
                DATA
        into dba..cargaPassadoDatabase
        FROM dba.[DW].[fato_table_volume]
        INNER JOIN dba.[DW].[dim_tempo]
            ON [fato_table_volume].sk_tempo = [dim_tempo].sk_tempo
        INNER JOIN dba.[DW].[dim_database]
            ON [fato_table_volume].sk_database = [dim_database].sk_database
        INNER JOIN dba.[DW].[dim_table]
            ON [dim_table].sk_table = [fato_table_volume].sk_table
        WHERE [dim_tempo].sk_tempo = (SELECT MAX(sk_tempo) FROM dba.dw.dim_tempo WHERE Nm_Servidor = INSTANCE_DS and data <= DATEADD(MONTH,-6,GETDATE())) AND NM_SERVIDOR like '%db%' 
        GROUP BY NM_SERVIDOR,
                 DATA, 
                 DATABASE_DS
        
        
        
        --Databases que mais cresceram nos ultimos 6 meses
        ;WITH DadosComRanking AS (
            SELECT  
                a.NM_SERVIDOR,
                a.DATABASE_DS AS [Database],
                a.RESERVED_IN_GB - p.RESERVED_IN_GB AS [Aumento_xGB], 
                ROW_NUMBER() OVER (ORDER BY a.RESERVED_IN_GB - p.RESERVED_IN_GB DESC) AS [TopGrowth],
                ROW_NUMBER() OVER (PARTITION BY a.NM_SERVIDOR ORDER BY a.RESERVED_IN_GB - p.RESERVED_IN_GB DESC) AS [TopPorServidor]
            FROM dba..cargaAtualDatabase a
            INNER JOIN dba..cargaPassadoDatabase p
                ON a.DATABASE_DS = p.DATABASE_DS
                AND a.NM_SERVIDOR = p.NM_SERVIDOR
            WHERE CAST((CAST(a.RESERVED_IN_GB - p.RESERVED_IN_GB AS decimal)) / (a.RESERVED_IN_GB + 1) * 100 AS NUMERIC(15,2)) > 0
        )
        SELECT *
        into dba..topGrowthDatabases
        FROM DadosComRanking
        WHERE TopPorServidor < 6;
        
        
        
        -- Etapa 0: Obter o maior sk_tempo por dia
        SELECT 
            NM_SERVIDOR,
            CONVERT(DATE, data) AS Dia,
            MAX(sk_tempo) AS sk_tempo
        INTO dba..MaxSkTempoPorDiaDatabase
        FROM dba.DW.dim_tempo
        WHERE data >= DATEADD(MONTH, -6, GETDATE()) AND NM_SERVIDOR like '%DB%'
        GROUP BY NM_SERVIDOR, 
                 CONVERT(DATE, data);
        
        
        
        
        -- Etapa 1: Tamanho da database por dia (usando apenas o maior sk_tempo de cada dia)
            SELECT
                tgt.NM_SERVIDOR,
                DATABASE_DS,
                CAST(SUM(RESERVED_IN_KB) / 1024.0 / 1024.0 AS INT) AS RESERVED_IN_GB,
                DATA,
                tgt.TopGrowth
            INTO dba..VolumePorDiaDatabase
            FROM dba.DW.fato_table_volume
            INNER JOIN dba.DW.dim_tempo
                ON fato_table_volume.sk_tempo = dim_tempo.sk_tempo
            INNER JOIN dba.DW.dim_database
                ON fato_table_volume.sk_database = dim_database.sk_database
            INNER JOIN dba.DW.dim_table
                ON dim_table.sk_table = fato_table_volume.sk_table
            INNER JOIN dba..topGrowthDatabases tgt
                ON dba.DW.dim_tempo.NM_SERVIDOR = tgt.Nm_Servidor and tgt.[Database] = DATABASE_DS 
            INNER JOIN dba..MaxSkTempoPorDiaDatabase maxDia
                ON dim_tempo.sk_tempo = maxDia.sk_tempo
            GROUP BY tgt.NM_SERVIDOR, 
                     DATA, 
                     DATABASE_DS, 
                     tgt.TopGrowth;
            
        
        
        
        
        -- Etapa 2: Primeira data por Database
          SELECT
              NM_SERVIDOR,
              DATABASE_DS,
              MIN(DATA) AS PRIMEIRA_DATA
          INTO dba..PrimeiraDataDatabase
          FROM dba..VolumePorDiaDatabase
          GROUP BY NM_SERVIDOR, 
                   DATABASE_DS;
          
        
        
        
        -- Etapa 3: Volume da primeira data
        SELECT
            vpd.NM_SERVIDOR,
            vpd.DATABASE_DS,
            vpd.DATA,
            vpd.RESERVED_IN_GB,
            vpd.TopGrowth,
            pd.PRIMEIRA_DATA,
            vi.RESERVED_IN_GB AS RESERVED_IN_GB_INICIAL
        INTO dba..VolumeComInicialDatabase
        FROM dba..VolumePorDiaDatabase vpd
        INNER JOIN dba..PrimeiraDataDatabase pd
            ON vpd.NM_SERVIDOR = pd.NM_SERVIDOR AND vpd.DATABASE_DS = pd.DATABASE_DS 
        INNER JOIN dba..VolumePorDiaDatabase vi
            ON vi.NM_SERVIDOR = pd.NM_SERVIDOR AND vi.DATABASE_DS = pd.DATABASE_DS  AND vi.DATA = pd.PRIMEIRA_DATA;
    END


    -- Etapa 4: Resultado final com cálculo da porcentagem
    SELECT
        NM_SERVIDOR,
        DATABASE_DS,
        RESERVED_IN_GB,
        DATA,
        TopGrowth,
        CAST(
            CASE 
                WHEN DATA = PRIMEIRA_DATA THEN 0
                WHEN RESERVED_IN_GB_INICIAL = 0 THEN 0
                ELSE ((RESERVED_IN_GB - RESERVED_IN_GB_INICIAL) * 100.0 / RESERVED_IN_GB_INICIAL)
            END AS INT
        ) AS PERCENTUAL_CRESCIMENTO
    FROM dba..VolumeComInicialDatabase
    WHERE NM_SERVIDOR = @nServidor;
END


exec smartsql..DatabaseGrowth @cargaFull = 1 --CargaFull
exec smartsql..DatabaseGrowth @servidor = 'PANFDBP4001B' --Busca por servidor





GO



