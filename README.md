# Coleção de Scripts SQL
Este repositório contém uma coleção de scripts SQL para administração, monitoramento e diversas outras utilidades para SQL Server. Abaixo você encontrará uma lista dos scripts e uma breve descrição do propósito de cada um.

## Acive_requests_linkedserver.sql
LISTAR O STATUS DAS REQUISICOES EM EXECUCAO. CHECAR STATUS DE BLOQUEIOS.

## Active Request - Count.sql
Contabiliza sessões ativas por base, hostname e procedure.

## Active session.sql
Verifica a quantidade de sessoes por login, quais estão ativas, e o que uma sessão específica está executando.

## ActiveRequests.sql
Lista requisições ativas com opções de filtro detalhadas, como por nome do banco, login, hostname, programa, texto SQL, nome do objeto e ID da sessão. Permite opcionalmente incluir o plano de execução.

## Backups.sql
Monitora e gerencia backups de banco de dados, incluindo histórico, progresso, atrasos e tipos de backup.

## Baseline_UsageIndex.sql
Coleta informações de linha de base sobre o uso de índices (seeks, scans, updates, tamanho).

## Baseline_querystore.sql
Coleta métricas de desempenho agregadas do Query Store, como duração média, tempo de CPU, I/O, DOP e uso de memória por consulta.

## Bufeer_cache.sql
Permite visualizar o conteúdo do plan cache, remover planos específicos, recompilar planos de execução, localizar planos e verificar o uso do buffer cache por banco de dados.

## Buffer_Pool_Extension.sql
Script para habilitar e configurar a extensão do Pool de Buffers (BPE), e verificar suas informações e páginas em cache.

## CargaTabelaParticionada_exemplo.sql
Exemplo de script para criar uma tabela particionada, carregar dados em lotes de uma tabela existente, e acompanhar o processo de carga. Inclui DDL, função e esquema de partição.

## Consulta blocked, wait, CPU.sql
Localiza consultas atualmente em execução, identificando bloqueios, esperas, instruções, procedimentos e consumo de CPU.

## DBA_REPLICA_OBJ.sql
Replica objetos como linked servers, logins e jobs em ambientes com Always On Availability Groups, e sincroniza jobs.

## DMVs Alwayson.sql
Conjunto de consultas a DMVs (Dynamic Management Views) para monitorar e diagnosticar ambientes Always On.

## Datafiles.sql
Consulta o tamanho dos datafiles das bases de dados.

## Dependencia_obj.sql
Verifica objetos referenciados em uma view, procedure, etc., e também exibe objetos que dependem ou dos quais uma tabela depende.

## Estatistica.sql
Exibe estatísticas de tabelas e índices, e fornece comandos para atualizar estatísticas em nível de banco, tabela ou índice.

## Historico_cpu.sql
Apresenta o histórico de consumo de CPU do SQL Server.

## IO, MEM, CPU.sql
Fornece consultas para verificar I/Os pendentes, uso de CPU por processo e sessões ativas.

## IO_Usage.sql
Analisa o uso de I/O, exibindo tempo de leitura/escrita por datafile e consultas com maior I/O lógico.

## Informacoes.sql
Coleta diversas informações sobre a instância do SQL Server, como versão, edição, caminhos padrão, status do Always On, e informações de sessão.

## Jobs.sql
Conjunto de scripts para monitorar e gerenciar SQL Server Agent Jobs, incluindo visualização de status, histórico, steps em execução, jobs com falha e parada de jobs.

## Linked_server.sql
Fornece scripts para verificar, criar, gerenciar logins, consultar e manipular dados, e excluir Linked Servers.

## Lock.sql
Identifica e detalha processos envolvidos em situações de lock (bloqueio), mostrando a cadeia de bloqueios e os scripts em execução.

## Login Change.sql
Mostra todos os logins que tiveram a senha alterada há mais de um número X de dias especificado.

## MONIT_CLUSTER.sql
Monitora um ambiente de cluster SQL Server, alertando sobre reinícios ou desbalanceamento de nós, e opcionalmente ajusta configurações de memória.

## MONIT_REPLICACAO_OBJ.sql
Valida se jobs e linked servers estão sincronizados entre os nós de um Always On Availability Group (AG).

## Memory.sql
Conjunto de scripts para analisar diversos aspectos do uso de memória no SQL Server, incluindo concessões de memória, objetos de memória, pool de buffers, procedures e queries ad-hoc de alto consumo, e informações sobre a condição da memória do SO.

## Migracao_datafiles.sql
Gera comandos para auxiliar na migração de datafiles para outro disco, incluindo scripts de backup, detach, cópia de arquivos e attach.

## Mirror.sql
Verifica o status de sincronização do Database Mirroring e fornece comando para realizar failover.

## MonitoracaoDisco.sql
Monitora o espaço em disco, verificando drives com pouco espaço livre ou que hospedam arquivos de banco de dados com autogrowth e espaço limitado.

## Monitoramento.sql
Fornece scripts para monitorar ambientes Always On, incluindo status de sincronização, identificação de réplica primária, réplicas não saudáveis e backups atrasados.

## Pages in buffer.sql
Mostra páginas no buffer pool (total, sujas, limpas), e fornece comandos para CHECKPOINT, DBCC DROPCLEANBUFFERS e localizar objetos por página.

## Password generator.sql
Gerador de senhas ou texto aleatório.

## Proc_hist_executions.sql
Lista o histórico de execução de procedures, mostrando a data da última execução.

## Proposta PR.sql
Consulta o número de propostas paradas em cada ponto do processo e lista detalhes dessas propostas.

## QueriesWith200kReads.sql
Cria, inicia e consulta uma sessão de Eventos Estendidos para coletar queries com mais de 200.000 leituras lógicas.

## Query Store.sql
Script para estudo e demonstração das funcionalidades do Query Store, incluindo criação de banco de dados de exemplo, tabelas, procedures e manipulação de planos de execução.

## Rename_database.sql
Script para renomear um banco de dados, incluindo alteração do nome lógico, arquivos lógicos, detach, e attach (requer renomeação manual dos arquivos físicos).

## Replicar Criação de datafiles entre dois ambientes.sql
Replica a criação de datafiles de um ambiente original para um ambiente de réplica, gerando os comandos necessários.

## Reporting Services Table Size.sql
Exibe o tamanho de bancos de dados e tabelas, incluindo o número de linhas, espaço usado por dados e índices, percentual do banco, e datas da última alteração e leitura.

## ReportingServices_GerenciamentoUsuario.sql
Gerencia usuários e auditoria de segurança, incluindo criação de schema, tabelas de auditoria e procedures para criação/revogação de usuários e listagem de permissões.

## Resource_governor.sql
Consulta informações sobre os pools de recursos do Resource Governor e seu mapeamento para bancos de dados.

## Restore.sql
Consulta o histórico de restores realizados na instância.

## SSISDB.sql
Realiza o expurgo de logs da base de dados SSISDB, removendo registros de tabelas internas em lotes.

## Sinc_obj_ad.sql
Sincroniza objetos de servidor (logins, jobs, linked servers) e gerencia o estado de jobs em ambientes Always On, com foco na replicação para uma réplica secundária específica.

## Statistics.sql
Demonstra o funcionamento das estatísticas no SQL Server, incluindo configuração, criação automática e manual, visualização, atualização e remoção.

## Synonym.sql
Fornece comandos para listar, remover (DROP) e criar SYNONYMs.

## Table size.sql
Calcula e exibe o espaço utilizado por tabelas e seus índices, incluindo espaço reservado, de dados, de índices e contagem de linhas.

## Temporal Table.sql
Demonstra o uso de Tabelas Temporais (Temporal Tables), incluindo criação, versionamento de tabelas existentes, consulta de histórico e limitações.

## Tlog.sql
Fornece comandos e consultas para gerenciar o log de transações (TLog), incluindo verificação de estado, informações, backup, truncate e leitura de conteúdo.

## Transaction.sql
Identifica transações em aberto, detalhando seu consumo no log de transações e as sessões associadas.

## Uteis.sql
Coleção de scripts e comandos úteis para administração e diagnóstico de SQL Server.

## Valida_VersaoFCI.sql
Script para verificar versões do SQL Server em um cluster e identificar se há nós com as mesmas versões.

## Wait.sql
Analisa estatísticas de espera (wait stats) para identificar os principais gargalos de desempenho na instância.

## datafile_size_all_databases.sql
Lista os datafiles de todas as bases de dados, incluindo tamanho e tipo.

## dbcc.sql
Demonstra e explica diversos comandos DBCC para manutenção, diagnóstico, checagem de integridade, gerenciamento de estatísticas, trace flags e clonagem de bancos de dados.

## dbcc_progress.sql
Monitora o progresso de comandos DBCC, BACKUP DATABASE e RESTORE DATABASE.

## dmvs.sql
Coletânea de consultas a DMVs (Dynamic Management Views) para obter informações sobre o SQL Server, incluindo estatísticas de log, VLFs, conexões, sessões, requisições, uso de índices e queries de alto custo.

## expurgo_job.sql
Realiza o expurgo de registros antigos da tabela `TB_CONTA_FATURA` em lotes.

## index.sql
Fornece scripts para gerenciamento de índices, incluindo verificação de fragmentação, sugestões de índices ausentes, listagem de índices recentes e comandos para reorganizar e reconstruir índices.

## mdf, ldf.sql
Script para verificar o caminho dos arquivos de dados (MDF) e logs (LDF) das databases.

## modos_manutencao.sql
Fornece comandos para alterar os modos de manutenção de um banco de dados (offline, online, single_user, multi_user, read_only, read_write).

## modos_recovery.sql
Demonstra cenários e comandos de recuperação de banco de dados, incluindo modo de emergência, DBCC CHECKDB e opções de reparo.

## monitoracao_wait_types.sql
Cria uma tabela e um job para coletar automaticamente estatísticas de espera (wait stats), filtrando tipos comuns.

## move datafiles.sql
Descreve os passos para mover arquivos de dados (MDF) e log (LDF) para um novo local, incluindo considerações para Always On AGs.

## permissoes.sql
Fornece scripts para listar permissões de usuários em objetos, roles e seus membros por base, e usuários com privilégios de sysadmin.

## plantonistas.sql
Gera uma escala de plantão para DBAs, distribuindo turnos em uma tabela temporária.

## spTempDBSizeInfo.sql
Cria uma procedure para coletar informações sobre o espaço livre e os principais consumidores do TempDB, enviando um resumo por e-mail.

## sp_configure.sql
Demonstra o uso de `sp_configure` para exibir e alterar opções de configuração do servidor, com exemplo para memória máxima.

## sp_help_revlogin.sql
Gera scripts T-SQL para recriar logins, incluindo SIDs e senhas (hash), facilitando a migração de logins entre servidores.

## sp_whoisactive.sql
Procedimento armazenado `sp_WhoIsActive` por Adam Machanic, uma ferramenta abrangente para monitorar a atividade no SQL Server.

## tempdb.sql
Analisa o uso do TempDB por sessão, mostrando o espaço alocado e queries em execução.

## trunc_log_homologacao.sql
Job para realizar backup e truncar logs de bancos de dados em ambiente de homologação, se o servidor for a réplica primária.

## volumetria.sql
Fornece scripts para verificar a volumetria de bancos de dados, tabelas e arquivos, incluindo espaço ocupado e número de registros.

## wait_type.sql
Mostra o tipo de espera de recurso, informações da sessão, e o batch/statement em execução.

## Outros Arquivos e Diretórios

- **Painel Top Query - Tuning.dtsx**: Painel do Integration Services para tuning de queries. (Adicionar descrição mais detalhada)
- **Proposta PR.sql**: Proposta de Pull Request. (Verificar conteúdo e adicionar descrição)
- **Treinamentos/**: Diretório contendo materiais de treinamento. (Adicionar descrição mais detalhada)
