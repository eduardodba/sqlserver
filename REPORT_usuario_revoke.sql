--EXECUCAO
--exec dba.dbo.usuario_revoke 'USR_TESTE1',NULL, 'EDU'  --REVOGAR TODOS OS ACESSOS
--exec dba.dbo.usuario_revoke 'USR_TESTE1','DBA', 'EDU' --REVOGAR APENAS UM ACESSOS


CREATE OR ALTER PROCEDURE usuario_revoke @user nvarchar(max), @database nvarchar(max), @execpor nvarchar(max) AS

DECLARE @statement   nvarchar(max)

create table #resultados_procedure ([Database] sysname, [RoleName] sysname,[MemberName] sysname)
insert into #resultados_procedure ([Database], [RoleName],[MemberName])
		exec dba.dbo.sp_ListaPermissoes @user

if exists(select 'X' from master.dbo.syslogins where loginname=@user) AND @database is NULL
BEGIN	
			
	DECLARE @db nvarchar(max)
	DECLARE datafiles_cursor CURSOR FAST_FORWARD
	FOR select DISTINCT([Database]) from #resultados_procedure
	OPEN datafiles_cursor;
	FETCH NEXT FROM datafiles_cursor INTO @db;
	WHILE @@fetch_status = 0
	BEGIN
		SELECT @statement = 'use '+@db +';' + 'DROP USER ['+@user+']'
			exec (@statement)
			
			-- LOG USER	
			insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)
            select @db AS Nm_Database, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao
			FETCH NEXT FROM datafiles_cursor INTO @db
	    END;
	CLOSE datafiles_cursor;
	DEALLOCATE datafiles_cursor;
	
	SELECT @statement = 'use '+@db +';' + 'DROP LOGIN ['+@user+']'
	EXEC (@statement)

	--LOG LOGIN
    insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao) 
	select 'WINDOWS' as Tp_Login, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao
   
		
	SELECT 'PERMISSIONAMENTO REMOVIDO'

END


ELSE IF exists(select 'X' from master.dbo.syslogins where loginname=@user) AND @database IS NOT NULL AND (select COUNT(DISTINCT([Database])) from #resultados_procedure where [MemberName]='['+@user+']')>1
BEGIN
	SELECT @statement = 'use '+@database +';' + 'DROP USER ['+@user+']'
	EXEC (@statement)

	-- LOG USER	
	insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)
    select @database AS Nm_Database, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao

	SELECT 'PERMISSIONAMENTO REMOVIDO'

END
