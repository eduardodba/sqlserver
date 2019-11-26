--Retorna informações de sintaxe para o comando especificado DBCC.
DBCC HELP (TRACEON)
DBCC HELP (CHECKTABLE)
DBCC HELP (CHECKDB)

--Descarrega o procedimento armazenado estendido DLL especificado da memória
DBCC dllname (FREE)

--select * from sys.session
--https://docs.microsoft.com/pt-br/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql?view=sql-server-2017#examples
--Habilita os sinalizadores de rastreamento especificados
DBCC TRACEON 
--Rastreia sINALIZADOR 2528,3205
DBCC TRACEON  (2528, 3205);  
----Exibe o status de sinalizadores de rastreamento
DBCC TRACESTATUS
--O exemplo a seguir exibe o estado de todos os sinalizadores de rastreamento atuais habilitados globalmente.
DBCC TRACESTATUS(-1);  
GO 
--O exemplo a seguir exibe o status dos indicadores de rastreamento 2528 e 3205.
DBCC TRACESTATUS (2528, 3205);  
GO  
--Desabilita os sinalizadores de rastreamento especificados.
DBCC TRACEOFF 

--Desabilita sinalizadores de rastreamento 2528,3205
DBCC TRACEOFF  (2528, 3205);  
--apoio 


--Link apoio https://msdn.microsoft.com/pt-br/library/ms188796(v=sql.120).aspx
USE CURSO
DBCC HELP (PROCCACHE)
DBCC HELP (OPENTRAN)
DBCC HELP (SHOWCONTIG)
DBCC HELP (SHOW_STATISTICS)

--Exibe informações de fragmentação para os dados e índices da tabela ou exibição 
--especificada
DBCC SHOWCONTIG (PESSOA)

--UPDATE ESTATISTICS
UPDATE STATISTICS PESSOA
--Exibe as estatísticas de otimização de consulta atuais de uma tabela ou exibição indexada
--https://docs.microsoft.com/pt-br/sql/t-sql/database-console-commands/dbcc-show-statistics-transact-sql?view=sql-server-2017
DBCC SHOW_STATISTICS (PESSOA,PK_ID)
DBCC SHOW_STATISTICS (PESSOA,PK_ID)WITH HISTOGRAM
--19972
DBCC SHOW_STATISTICS (PESSOA,St_id_nome_1)
DBCC SHOW_STATISTICS (PESSOA,St_id_nome_1)WITH HISTOGRAM

DBCC SHOW_STATISTICS (PESSOA,St_id_nome_2)
DBCC SHOW_STATISTICS (PESSOA,St_id_nome_2)WITH HISTOGRAM

--Exibe informações em um formato de tabela sobre o cache de procedimento
DBCC PROCCACHE

--Ajuda a identificar as transações ativas que podem impedir o truncamento do log
BEGIN TRAN
UPDATE PESSOA SET ULTIMO_NOME='X' WHERE ID_PESSOA='1'
DBCC OPENTRAN (CURSO)
ROLLBACK




DBCC HELP (CHECKALLOC)
--Verifica a integridade lógica e física de todos os objetos do banco de 
--dados especificado com a execução das seguintes operações:
USE MASTER
ALTER DATABASE CURSO SET SINGLE_USER  

--use curso
--GERA INFORMAÇÕES
DBCC CHECKDB (curso)
DBCC CHECKDB (curso)WITH NO_INFOMSGS, ALL_ERRORMSGS
--EM CASO DE ERROS, COLOCAR O BANCO EM EMERGENCY E SINGLE_USER

--REPARAÇÃO RAPIDA SEM PERDER DADOS
DBCC CHECKDB (curso,REPAIR_FAST) WITH NO_INFOMSGS, ALL_ERRORMSGS
--REPARAÇÃO SEM PERDER DADOS
DBCC CHECKDB (curso,REPAIR_REBUILD) WITH NO_INFOMSGS, ALL_ERRORMSGS
--ATENÇÃO
--REPARAÇÃO COM PERDER DADOS
DBCC CHECKDB (curso,REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS


--Verifica a integridade de todas as páginas e estruturas 
--que compõem a tabela ou a exibição indexada
USE CURSO
DBCC CHECKTABLE (PESSOA)
--REPARAÇÃO RAPIDA SEM PERDER DADOS
DBCC CHECKTABLE (PESSOA,REPAIR_FAST )WITH NO_INFOMSGS, ALL_ERRORMSGS
--REPARAÇÃO SEM PERDER DADOS
DBCC CHECKTABLE (PESSOA,REPAIR_REBUILD )WITH NO_INFOMSGS, ALL_ERRORMSGS
--ATENÇÃO
--REPARAÇÃO COM PERDER DADOS
DBCC CHECKTABLE (PESSOA,REPAIR_ALLOW_DATA_LOSS )WITH NO_INFOMSGS, ALL_ERRORMSGS


--Inspeciona a integridade de uma restrição especificada ou de todas as 
--restrições em uma tabela especificada no banco de dados atual.

DBCC CHECKCONSTRAINTS

--Verifica a consistência de estruturas de alocação de espaço em disco
-- para um banco de dados especificado

DBCC CHECKALLOC 
DBCC CHECKALLOC (CURSO) WITH NO_INFOMSGS, ALL_ERRORMSGS


--REPARAÇÃO RAPIDA SEM PERDER DADOS
DBCC CHECKALLOC (curso,REPAIR_FAST) WITH NO_INFOMSGS, ALL_ERRORMSGS
--REPARAÇÃO SEM PERDER DADOS
DBCC CHECKALLOC (curso,REPAIR_REBUILD) WITH NO_INFOMSGS, ALL_ERRORMSGS
--ATENÇÃO
--REPARAÇÃO COM PERDER DADOS
DBCC CHECKALLOC (curso,REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS

--VOLTAR O BANCO MULTI_USER

ALTER  DATABASE CURSO SET MULTI_USER



--Link apoio https://msdn.microsoft.com/pt-br/library/ms188796(v=sql.120).aspx

--Recupera o espaço de colunas de comprimento variável descartadas 
--em tabelas ou exibições indexadas.
DBCC CLEANTABLE (CURSO,PESSOA)  
WITH NO_INFOMSGS; 
--VERIFICANDO A TABELA
USE CURSO
SELECT * FROM PESSOA

--Reduz o tamanho dos arquivos de dados e de log do banco de dados especificado.
--PERMITE 10% ESPACO LIVRE
DBCC SHRINKDATABASE (CURSO, 10);  
--seguir reduz os arquivos de dados e de log no banco de dados de exemplo 
--até a última extensão atribuída.
DBCC SHRINKDATABASE (CURSO, TRUNCATEONLY);
--As tabelas do sistema de banco de dados são verificadas nessa fase.

--Reduz o tamanho do arquivo de log ou dos dados 
USE CURSO;  
GO  
--REDUZ ARQUIVO DE LOG PARA 10 MB
DBCC SHRINKFILE (CURSO_log, 10);  
GO  

--Fornece estatísticas de uso do espaço do log de transações para todos os bancos de dados
DBCC SQLPERF(LOGSPACE);  
GO
--https://docs.microsoft.com/pt-br/sql/t-sql/database-console-commands/dbcc-clonedatabase-transact-sql?view=sql-server-2017#examples
--Gera um clone somente de esquema de um banco de dados usando--
DBCC CLONEDATABASE (CURSO, CURSO_CLONE_1); 
GO 

USE CURSO_CLONE_1
SELECT * FROM PESSOA
--
--Gera um clone somente de esquema de um banco de dados usando SEM ESTATISTICAS
DBCC CLONEDATABASE (CURSO, CURSO_CLONE_2) WITH NO_STATISTICS;    
GO 

--Limpa cache de procedures
DBCC FREEPROCCACHE

--
--Para reiniciar a numeração de uma coluna Identiy de uma tabela do SQL Server, utilize o comando:
DBCC CHECKIDENT('TAB_3', RESEED, 0)

--CRIANDO TABELA
USE CURSO
CREATE TABLE TAB_3
   (ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NOME VARCHAR(10)
	)
--INSERE REGISTROS
INSERT INTO TAB_3 VALUES ('A')
INSERT INTO TAB_3 VALUES ('B')

--VERIFICA REGISTROS 
SELECT * FROM TAB_3

--DELETE FROM REGISTROS
DELETE FROM TAB_3

--INSERINDO NOVOS REGISTROS
INSERT INTO TAB_3 VALUES ('C')
INSERT INTO TAB_3 VALUES ('D')

--VERIFICA REGISTROS 
SELECT * FROM TAB_3

--DELETE FROM REGISTROS
DELETE FROM TAB_3
--REINICIA CHAVE
DBCC CHECKIDENT('TAB_3', RESEED, 0)--REINICIA DO 0
DBCC CHECKIDENT('TAB_3', RESEED, 10)--REINICIA DO 10

