-- ======================================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 20/10/2021
-- Description: Gerar comandos para auxiliar na migracao dos datafiles para outro disco
-- ======================================================================================

USE MASTER
SET NOCOUNT ON
GO

SELECT '---------------------------------     EXECUTAR ANTES DA MIGRACAO E GUARDAR OS VALORES     ---------------------------------'

SELECT '1) O RESULTADO ABAIXO, GERA UM BACKUP DO COMANDO DE ATTACH COM OS DATAFILES NOS LOCAIS ORIGINAIS, EM CASO DE UM POSSIVEL ROLLBACK' AS [PROCEDIMENTOS]

SELECT GERAR_ATTACH
FROM (
	SELECT 1 ID1,DBID ID2 ,0 ID3,'CREATE DATABASE ' + NAME + ' ON' GERAR_ATTACH FROM SYS.SYSDATABASES WHERE DBID > 4
UNION ALL
	SELECT 2,DBID,FILEID,  CASE WHEN  FILEID = 1 THEN ' ' ELSE ',' END + '(FILENAME = ' + '''' +   FILENAME + ''')'    FROM SYS.SYSALTFILES  WHERE DBID > 4
UNION ALL
	SELECT 4,DBID,0,'FOR ATTACH ' FROM SYS.SYSDATABASES  WHERE DBID > 4
UNION ALL
	SELECT 4,DBID,0,'GO ' FROM SYS.SYSDATABASES  WHERE DBID > 4) A
ORDER BY ID2,ID1,ID3 



SELECT '2) O RESULTADO ABAIXO, GERA UM BACKUP DO COMANDO DE ALTER PARA AS BASES DE SISTEMAS, EM CASO DE UM POSSIVEL ROLLBACK' AS [PROCEDIMENTOS]

SELECT 'ALTER DATABASE ' + db_name(database_id) + ' MODIFY FILE (NAME = ' + name + ', FILENAME = ''' + physical_name + ''');' AS [MODIFY BASES DE SISTEMA]
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');



SELECT '---------------------------------     EXECUTAR PARA REALIZAR A MIGRAÇÃO      ---------------------------------'

-- FORMULA EXCEL PARA GERAR O INSERT. UTILIZAR A PLANILHA Capacity_departamental.xlsx . COLAR A SAÍDA PARA ALIMENTAR A TABELA
-- =CONCAT("INSERT INTO @tab VALUES ('";A2;"','";E2;"')")

--ALTERAR A VARIAVEL mountPoint CONFORME DISCO CRIADO PELO TIME DE SERVIDORES

declare @mountPoint varchar(20) = 'R:\' 
declare @tab table (dbname varchar(100), disco varchar(100))

INSERT INTO @tab VALUES ('bi','_sqlbi_01')
INSERT INTO @tab VALUES ('consignado','_sqlconsignado_01')
INSERT INTO @tab VALUES ('crm_processo','_sqlcrm_01')
INSERT INTO @tab VALUES ('crm','_sqlcrm_01')
INSERT INTO @tab VALUES ('crm_ci','_sqlcrm_01')
INSERT INTO @tab VALUES ('crm_cartoes','_sqlcrm_01')
INSERT INTO @tab VALUES ('ic2','_sqldata_01')
INSERT INTO @tab VALUES ('estatistica','_sqldata_01')
INSERT INTO @tab VALUES ('db_canais_atend','_sqldb_canais_atend_01')
INSERT INTO @tab VALUES ('db_ods','_sqldb_ods_01')
INSERT INTO @tab VALUES ('db_ods_hist','_sqldb_ods_01')
INSERT INTO @tab VALUES ('dbComercial','_sqldbComercial_01')
INSERT INTO @tab VALUES ('dbEstudos','_sqldbEstudos_01')
INSERT INTO @tab VALUES ('digital','_sqldigital_01')
INSERT INTO @tab VALUES ('ESP_OLOS','_sqlESP_OLOS_01')
INSERT INTO @tab VALUES ('SSISDB','_sqlsistema_01')
INSERT INTO @tab VALUES ('DBA','_sqlsistema_01')
INSERT INTO @tab VALUES ('msdb','_sqlsistema_01')
INSERT INTO @tab VALUES ('master','_sqlsistema_01')
INSERT INTO @tab VALUES ('model','_sqlsistema_01')
INSERT INTO @tab VALUES ('Tempdb','_sqltemp1')

 
SELECT '3) O RESULTADO ABAIXO, GERA O COMMANDO DE DETTACH DAS BASES. EXECUTAR ANTES DE BAIXAR O SQL. EXECUTAR ANTES DE BAIXAR O SQL' AS [PROCEDIMENTOS]

DECLARE @database NVARCHAR(200) ,
    @cmd NVARCHAR(1000) ,
    @detach_cmd NVARCHAR(4000) ,
    @attach_cmd NVARCHAR(4000) ,
    @file NVARCHAR(1000) ,
    @i INT ,
    @DetachOrAttach BIT;
SET @DetachOrAttach = 1;
-- 1 Detach 0 - Attach
-- 1 Generates Detach Script
-- 0 Generates Attach Script
DECLARE dbname_cur CURSOR STATIC LOCAL FORWARD_ONLY
FOR
    SELECT  RTRIM(LTRIM([name]))
    FROM    sys.databases
    WHERE   database_id > 4;
-- No system databases
OPEN dbname_cur
FETCH NEXT FROM dbname_cur INTO @database
WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT  @i = 1;
        SET @attach_cmd = '-- ' + QUOTENAME(@database) + CHAR(10)
            + 'EXEC sp_attach_db @dbname = ''' + @database + '''' + CHAR(10);
      -- Change skip checks to false if you want to update statistics before you detach.
        SET @detach_cmd = '-- ' + QUOTENAME(@database) + CHAR(10)
            + 'EXEC sp_detach_db @dbname = ''' + @database
            + ''' , @skipchecks = ''true'';' + CHAR(10);
      -- Get a list of files for the database
        DECLARE dbfiles_cur CURSOR STATIC LOCAL FORWARD_ONLY
        FOR
            SELECT  physical_name
            FROM    sys.master_files
            WHERE   database_id = DB_ID(@database)
            ORDER BY [file_id];
        OPEN dbfiles_cur
        FETCH NEXT FROM dbfiles_cur INTO @file
        WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @attach_cmd = @attach_cmd + '    ,@filename'
                    + CAST(@i AS NVARCHAR(10)) + ' = ''' + @file + ''''
                    + CHAR(10);
                SET @i = @i + 1;
                FETCH NEXT FROM dbfiles_cur INTO @file
            END
        CLOSE dbfiles_cur;
        DEALLOCATE dbfiles_cur;
        IF ( @DetachOrAttach = 0 )
            BEGIN
            -- Output attach script
                PRINT @attach_cmd;
            END
        ELSE -- Output detach script
            PRINT @detach_cmd;
        FETCH NEXT FROM dbname_cur INTO @database
    END
CLOSE dbname_cur;
DEALLOCATE dbname_cur;



SELECT '4) O RESULTADO ABAIXO, GERA O COMMANDO DE ALTER PARA AS BASES DE SISTEMA APONTANDO PARA OS NOVOS DESTINOS. EXECUTAR ANTES DE BAIXAR O SQL' AS [PROCEDIMENTOS]

SELECT 'ALTER DATABASE ' + db_name(database_id) + ' MODIFY FILE (NAME = ' + name + ', FILENAME = ''' + @mountPoint + disco + '\' + replace(reverse(left(reverse(physical_name) , charindex('\', reverse(Physical_Name)))), '\', '') + ''');' AS [MODIFY BASES DE SISTEMA]
FROM sys.master_files 
INNER JOIN @tab on [DBNAME] = DB_NAME(database_id)
WHERE database_id < 4



SELECT '5) O RESULTADO ABAIXO GERA OS COMANDOS PARA COPIAR OS DATAFILES PARA OS NOVOS DESTINOS. EXECUTAR VIA CMD APÓS BAIXAR O SQL' AS [PROCEDIMENTOS]

SELECT 
	CASE WHEN groupid = 0 THEN 'COPY ' + filename + ' ' + @mountPoint+ '_sqllog1' + '\'
	ELSE 'COPY ' + filename + ' ' + @mountPoint+ t.disco + '\' END AS [GERAR SCRIPT PARA EXECUTAR NO PROMPT]
FROM sys.sysaltfiles 
INNER JOIN @tab t on t.[dbname] = DB_NAME(dbid)
where dbid > 4



SELECT '6) O RESULTADO ABAIXO GERA OS COMANDOS PARA ATTACHAR AS BASES NO NOVO DIRETÓRIO. EXECUTAR APÓS O SQL INICIAR' AS [PROCEDIMENTOS]

SELECT GERAR_ATTACH
FROM (
	SELECT 1 ID1, DBID ID2,0 ID3, 'CREATE DATABASE ' + NAME + ' ON' GERAR_ATTACH FROM SYS.SYSDATABASES WHERE DBID > 4
UNION ALL
	SELECT 
		2, DBID, FILEID,  
		CASE WHEN  fileid = 1 then ' ' else ',' end + '(FILENAME = ' + '''' +
		CASE WHEN groupid = 0 THEN @mountPoint + '_sqllog1' + '\' + replace(reverse(left(reverse(physical_name) , charindex('\', reverse(Physical_Name)))), '\', '')
		ELSE @mountPoint + disco + '\' + replace(reverse(left(reverse(physical_name) , charindex('\', reverse(Physical_Name)))), '\', '')   END AS SCRIPT_PROMPT
	FROM SYS.SYSALTFILES 
	INNER JOIN @tab T ON T.[DBNAME] = DB_NAME(DBID)
	INNER JOIN SYS.MASTER_FILES ON FILEID=[FILE_ID] AND DATABASE_ID=[DBID]
	WHERE [DBID] > 4
UNION ALL
	SELECT 4,DBID,0,'FOR ATTACH ' FROM SYS.SYSDATABASES  WHERE DBID > 4
UNION ALL
	SELECT 4,DBID,0,'GO ' FROM SYS.SYSDATABASES  WHERE DBID > 4) A
ORDER BY ID2,ID1,ID3 




 

