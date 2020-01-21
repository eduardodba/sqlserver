--Ver tudo que tem no plan cache
SELECT *
FROM sys.dm_exec_cached_plans AS cplan
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
ORDER BY cplan.usecounts DESC 




-- Remove the specific plan from the cache.  
DBCC FREEPROCCACHE (0x060006001ECA270EC0215D05000000000000000000000000);   -- Inserir o plan_handle para limpar
GO  


--Recompilar plano de execução
EXEC sp_recompile 'Person.Address';  -- Nome do objeto
GO


--Localizar um plano no cache
SELECT *
FROM sys.dm_exec_cached_plans AS cplan
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
where qtext.text like 'use Financeiro_Devops 
select * from HI_STATUS_BOLETO_MANUAL;'

