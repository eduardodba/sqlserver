-- ===============================================================
--      expurgo logs SSISDB
-- ===============================================================

declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[executions] 
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[executions])
    goto deleteMore	
GO	

declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[executable_statistics]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[executable_statistics])
    goto deleteMore	
GO	

declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[execution_component_phases]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[execution_component_phases])
    goto deleteMore	
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[execution_data_statistics] 
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[execution_data_statistics])
    goto deleteMore	
GO

declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[execution_data_taps] 
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[execution_data_taps])
    goto deleteMore
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[execution_parameter_values]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[execution_parameter_values])
    goto deleteMore	
GO	
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[execution_property_override_values]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[execution_property_override_values])
    goto deleteMore	
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[extended_operation_info]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[extended_operation_info])
    goto deleteMore	
GO	
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[operation_messages]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[operation_messages])
    goto deleteMore	
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[event_messages]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[event_messages])
    goto deleteMore	
GO

declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[event_message_context]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[event_message_context])
    goto deleteMore	
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[operation_os_sys_info]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[operation_os_sys_info])
    goto deleteMore	
GO	
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[operation_permissions]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[operation_permissions])
    goto deleteMore		
GO
	
declare @contador int
set @contador = 0 
deleteMore:
DELETE TOP(5000)  FROM [internal].[validations]
set @contador = @contador + 1
print 'rodada ' + cast(@contador as varchar(10)) + '- 5000 registros excluídos'
IF EXISTS(SELECT top 1 * FROM [internal].[validations])
    goto deleteMore		
GO	



EXEC SSISDB.internal.cleanup_server_log
GO
EXEC SSISDB.catalog.configure_catalog @property_name='SERVER_OPERATION_ENCRYPTION_LEVEL', @property_value='2'
GO
ALTER DATABASE SSISDB SET MULTI_USER
GO
EXEC SSISDB.internal.Cleanup_Server_execution_keys @cleanup_flag = 1
GO
