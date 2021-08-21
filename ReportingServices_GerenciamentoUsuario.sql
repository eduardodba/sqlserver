-- ============================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: CRIACAO DO SCHEMA SECMONIT
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'secmonit')
BEGIN
 EXEC SP_EXECUTESQL N'CREATE SCHEMA [secmonit] AUTHORIZATION [dbo]'
END



-- ============================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: CRIACAO DAS TABELAS DE AUDITORIA
-- ============================================================

IF OBJECT_ID(N'secmonit.seg_audit_users', N'U') IS NOT NULL  
   DROP TABLE secmonit.seg_audit_users;  
GO

create table secmonit.seg_audit_users (
                Nm_Database sysname not null,
                Tp_Atualizacao varchar(20) not null, -- Create , Drop
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                ) WITH (DATA_COMPRESSION = PAGE);
GO 

IF OBJECT_ID(N'secmonit.seg_audit_login', N'U') IS NOT NULL  
   DROP TABLE secmonit.seg_audit_login;  
GO

create table secmonit.seg_audit_login (
                Tp_Login varchar(20)  not null , -- Sql ou Windows
                Tp_Atualizacao varchar(20) not null, -- Create , Drop
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                ) WITH (DATA_COMPRESSION = PAGE);
GO         

IF OBJECT_ID(N'secmonit.seg_audit_acessos', N'U') IS NOT NULL  
   DROP TABLE secmonit.seg_audit_acessos;  
GO  

create table secmonit.seg_audit_acessos (
                Nm_Database sysname not null,
                Tp_Acesso varchar(20) not null, -- Leitura , Insert, Update, Exec...
                Desc_Comando_Executado varchar(500) not null,
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                ) WITH (DATA_COMPRESSION = PAGE);		
GO





-- ============================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA CRIACAO DE USUARIO
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.usuario_acesso'))
   exec('CREATE PROCEDURE secmonit.usuario_acesso AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE secmonit.usuario_acesso @user nvarchar(max), @pass nvarchar(max), @database nvarchar(max), @acesso nvarchar(max), @execpor nvarchar(max) AS    
	DECLARE @statement   nvarchar(max)    
     
	IF SUSER_ID(@user) IS NULL    
	BEGIN    
		IF @user like '%\%'    
		BEGIN    
			insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao) select 'WINDOWS' as Tp_Login, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
			SELECT @statement =   'CREATE LOGIN ['+@user+ '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'    
			exec sp_executesql @statement    
        END
		ELSE    
		BEGIN       
			insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao) select 'SQL' as Tp_Login, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
			SELECT @statement = 'CREATE LOGIN [' +@user+ '] WITH PASSWORD=N'''+@pass+''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON'    
			exec sp_executesql @statement    
         END    
	END    
      
    EXECUTE AS LOGIN = 'SA'
      
	if (@acesso = 'R')    
	BEGIN      
		SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'    
		exec sp_executesql @statement    
     
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE LEITURA' AS STATUS    
    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
					 WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
	END    
     
	ELSE IF (@acesso = 'RW')    
	BEGIN     
		SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'    
		exec sp_executesql @statement    
                   
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datawriter'', [' +@user+ '];'    
		exec sp_executesql @statement    
     
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE ESCRITA' AS STATUS    
    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
					 WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
	END    
     
	ELSE IF (@acesso = 'DDL')    
	BEGIN    
		SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'    
		exec sp_executesql @statement    
                   
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datawriter'', [' +@user+ '];'    
		exec sp_executesql @statement    
       
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_ddladmin'', [' +@user+ '];'    
		exec sp_executesql @statement    
     
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE LEITURA, ESCRITA E DDL ADMIN' AS STATUS    
    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
					 WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
	END    
     
	ELSE IF (@acesso = 'EXECUTE')    
	BEGIN    
		SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use '+@database +';' + 'grant execute to [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE EXECUTE' AS STATUS    
    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
		             WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
	END    
     
	ELSE IF (@acesso = 'AGENT')    
    BEGIN    
     
		SELECT @statement = 'use msdb;' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use msdb;' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'    
		exec sp_executesql @statement    
		 
		SELECT @statement = 'use msdb;' + 
							'ALTER ROLE [ServerGroupAdministratorRole] ADD MEMBER [' +@user+ '];' +    
							'ALTER ROLE [ServerGroupReaderRole] ADD MEMBER [' +@user+ '];' +
							'ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [' +@user+ '];' +    
							'ALTER ROLE [SQLAgentReaderRole] ADD MEMBER [' +@user+ '];' +
							'ALTER ROLE [SQLAgentUserRole] ADD MEMBER [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO NO AGENT' AS STATUS    
    
        
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
		             WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao     
	END    
     
     
	ELSE IF (@acesso = 'SUSTENTACAO')    
	BEGIN    

     	SELECT @statement = 'use master;' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use master;' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement =	'use master;' +
							'grant VIEW SERVER STATE to [' + @user + ']    
							 grant execute on sp_who2 to [' + @user + ']    
							 grant execute on sp_who3 to [' + @user + ']    
							 GRANT VIEW DEFINITION to [' + @user + ']    
							 grant alter trace to       [' + @user + ']
							 grant execute on sp_helptext to [' + @user + ']
							 grant execute on sp_help to [' + @user + ']' 
		BEGIN TRY
			exec sp_executesql @statement    
        END TRY
		BEGIN CATCH
		END CATCH
		

		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE SUSTENTACAO' AS STATUS    
    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
					WHEN @acesso = 'AGENT' THEN 'msdb'    
		ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
     
	END    
                   
	ELSE IF (@acesso = 'OWNER')    
	BEGIN    
		SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_owner'', [' +@user+ '];'    
		exec sp_executesql @statement    
		
		SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE OWNER' AS STATUS    
    
        --LOG USER    
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
		select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
				     WHEN @acesso = 'AGENT' THEN 'msdb'    
				ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao    
	END    
      
	IF(@statement is not null)  
	BEGIN  
  
	insert into DBA.secmonit.seg_audit_acessos(Nm_Database, Tp_Acesso, Desc_Comando_Executado, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)    
    select	CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'    
				 WHEN @acesso = 'AGENT' THEN 'msdb'    
			ELSE @database END Nm_Database,    
			CASE WHEN @acesso = 'R' THEN 'Leitura'    
                 WHEN @acesso = 'RW' THEN 'Gravacao'    
            ELSE @acesso END Tp_Acesso,    
			@statement as Desc_Comando_Executado,    
			@user as Nm_Login,    
			getdate() as Data_Atualizacao,    
			@execpor as Nm_Login_Alteracao    
	END
GO




-- ===============================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA LISTAR AS PERMISSOES APOS A CRIACAO
-- ===============================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.sp_ListaPermissoes'))
   exec('CREATE PROCEDURE secmonit.sp_ListaPermissoes AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE secmonit.sp_ListaPermissoes @user varchar(100) AS  
	CREATE TABLE #RolesMembers (  
		[Database] sysname,  
		RoleName sysname,  
		MemberName sysname
	)  
	EXEC dbo.sp_MSforeachdb 'insert into #RolesMembers select ''[?]'', r.name ,  m.name   
								FROM [?].sys.database_role_members rm  
								INNER JOIN [?].sys.database_principals r ON rm.role_principal_id = r.principal_id  
								INNER JOIN [?].sys.database_principals m ON rm.member_principal_id = m.principal_id  
								INNER JOIN [?].sys.database_permissions e ON e.grantee_principal_id=m.principal_id';  
	SELECT * FROM #RolesMembers  
    WHERE MemberName = @user
	ORDER BY [Database], [RoleName]
GO



-- =====================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA LISTAR AS PERMISSOES DE ROLE EM DATABASE
-- =====================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.sp_acessos_roleDatabase'))
   exec('CREATE PROCEDURE secmonit.sp_acessos_roleDatabase AS BEGIN SET NOCOUNT ON; END')
GO
	ALTER PROCEDURE secmonit.sp_acessos_roleDatabase @user nvarchar(max) AS
	EXECUTE AS LOGIN='SA'
	declare @cmd varchar(max), @db varchar(256)
	if OBJECT_ID('tempdb..#tempRoleUserDB') is not null
	    drop table #tempRoleUserDB
	CREATE TABLE #tempRoleUserDB (
	    [DBName] [nvarchar](128) NULL,
	    [UsrName] [sysname] NOT NULL,
	    [RoleName] [sysname] NOT NULL
	)
	declare cursorDB cursor fast_forward for
	select name	from sys.databases where  state_desc = 'online' and source_database_id is null
	open cursorDB
	fetch next from cursorDB into @db
	while @@FETCH_STATUS <> -1
	begin
	    set @cmd = 'use '+@db+' ' + '
					SELECT	db_name() as DBName
							,perm.state_desc as Tipo
							,perm.[permission_name] as Permissao
							,perm.class_desc as DescricaoPermissao
							,case when perm.class_desc = ''SCHEMA'' then schema_name(perm.major_id)
							else null end as GrantOnScheme
							,case when perm.class_desc = ''OBJECT_OR_COLUMN'' then schema_name(obj.schema_id)
							else null end as ObjectSchemaName
							,case
							when perm.class_desc = ''OBJECT_OR_COLUMN'' then obj.name 
							else null
							end as ObjectName
							,case when perm.class_desc = ''OBJECT_OR_COLUMN'' then obj.type_desc 
							else null end as ObjectType
							,dest.name as DestName
							,dest.type_desc as DescType
					FROM sys.database_permissions AS perm
					left join sys.objects AS obj on perm.major_id = obj.[object_id]
					inner join sys.database_principals AS dest on perm.grantee_principal_id = dest.principal_id
					left join sys.columns AS cl on cl.column_id = perm.minor_id and cl.[object_id] = perm.major_id'
	    set @cmd =  'use '+@db+' ' + 
					'select db_name() as DBName 
							,usr.name as UsrName
							,rol.name as RoleName
					from sys.database_principals rol
					inner join sys.database_role_members drm on rol.principal_id = drm.role_principal_id
					inner join sys.database_principals usr on usr.principal_id = drm.member_principal_id'
	    insert into #tempRoleUserDB
	    exec (@cmd)
	    fetch next from cursorDB into @db
	end
	close cursorDB
	deallocate cursorDB
	select * from #tempRoleUserDB where UsrName = @user order by UsrName, RoleName
GO



-- ========================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA LISTAR AS PERMISSOES Explicitas em DATABASE
-- ========================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.sp_acessos_expDatabase'))
   exec('CREATE PROCEDURE secmonit.sp_acessos_expDatabase AS BEGIN SET NOCOUNT ON; END')
GO
--PROCEDURE PARA LISTAR AS PERMISSOES Explicitas em DATABASE
ALTER PROCEDURE secmonit.sp_acessos_expDatabase @user nvarchar(max) AS
	EXECUTE AS LOGIN = 'SA'
	declare @cmd varchar(max), @db varchar(256)
	if OBJECT_ID('tempdb..#tempPermExpDB') is not null
	    drop table #tempPermExpDB
	
	CREATE TABLE #tempPermExpDB (
	    [DBName] [nvarchar](128) NULL,
	    [Tipo] [nvarchar](60) NULL,
	    [Permissao] [nvarchar](128) NULL,
	    [DescricaoPermissao] [nvarchar](60) NULL,
	    [GrantOnScheme] [nvarchar](128) NULL,
	    [ObjectSchemaName] [nvarchar](128) NULL,
	    [ObjectName] [nvarchar](128) NULL,
	    [ObjectType] [nvarchar](60) NULL,
	    [DestName] [sysname] NULL,
	    [DescType] [nvarchar](60) NULL
	)
	
	declare cursorDB cursor fast_forward for
	select name	from sys.databases where state_desc = 'online' and source_database_id is null
	open cursorDB
	fetch next from cursorDB into @db
	while @@FETCH_STATUS <> -1
	begin
		    set @cmd =  'use '+@db+' ' + 
						'SELECT db_name() as DBName
								,perm.state_desc as Tipo
								,perm.[permission_name] as Permissao
								,perm.class_desc as DescricaoPermissao
								,case when perm.class_desc = ''SCHEMA'' then schema_name(perm.major_id)
								else null end as GrantOnScheme
								,case when perm.class_desc = ''OBJECT_OR_COLUMN'' then schema_name(obj.schema_id)
								else null end as ObjectSchemaName
								,case when perm.class_desc = ''OBJECT_OR_COLUMN'' then obj.name 
								else null end as ObjectName
								,case when perm.class_desc = ''OBJECT_OR_COLUMN'' then obj.type_desc 
								else null end as ObjectType
								,dest.name as DestName
								,dest.type_desc as DescType
						FROM sys.database_permissions AS perm
						left join sys.objects AS obj on perm.major_id = obj.[object_id]
						inner join sys.database_principals AS dest on perm.grantee_principal_id = dest.principal_id
						left join sys.columns AS cl on cl.column_id = perm.minor_id and cl.[object_id] = perm.major_id'
	    insert into #tempPermExpDB
	    exec (@cmd)
	    set @cmd =  'use '+@db+' ' + 
					'select db_name() as DBName 
							,usr.name as UsrName
							,rol.name as RoleName
					from sys.database_principals rol
					inner join sys.database_role_members drm on rol.principal_id = drm.role_principal_id
					inner join sys.database_principals usr
					on usr.principal_id = drm.member_principal_id'
	    
	    fetch next from cursorDB into @db
	end
	close cursorDB
	deallocate cursorDB
	select DBName, Permissao, GrantOnScheme, ObjectSchemaName, ObjectName, DestName from #tempPermExpDB where DestName = @user order by DBName, ObjectName, Tipo, Permissao
GO



-- =====================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA LISTAR AS PERMISSOES ROLE EM INSTANCIA
-- =====================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.sp_acessos_roles'))
   exec('CREATE PROCEDURE secmonit.sp_acessos_roles AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE secmonit.sp_acessos_roles @user nvarchar(max) AS
	select usr.name as LoginName
			,rol.name as RoleName
	from sys.server_principals rol
	inner join sys.server_role_members srm on rol.principal_id = srm.role_principal_id
	inner join sys.server_principals usr on usr.principal_id = srm.member_principal_id
	WHERE usr.name = @user
	order by usr.name, rol.name
GO

 
-- ========================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA LISTAR AS PERMISSOES EXPLICITAS NA INSTANCIA
-- ========================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.sp_acessos_expInstancia'))
   exec('CREATE PROCEDURE secmonit.sp_acessos_expInstancia AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE secmonit.sp_acessos_expInstancia @user nvarchar(max) AS
	select serv_princ.name as LoginRoleNome
		,serv_perm.permission_name as PermissaoNome
		,serv_princ.type_desc as LoginRoleTipo
		,case serv_princ.is_disabled
		when 0 then 'Ativo'
		when 1 then 'Inativo'
		end as LoginRoleStatus
	from sys.server_permissions serv_perm   
	inner join sys.server_principals serv_princ on serv_perm.grantee_principal_id = serv_princ.principal_id
	where serv_princ.name = @user  
	order by serv_princ.name, serv_perm.state_desc, serv_perm.permission_name
GO



-- ========================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 29/07/2021
-- Description: PROCEDURE PARA REVOGAR ACESSO
-- ========================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('secmonit.usuario_revoke'))
   exec('CREATE PROCEDURE secmonit.usuario_revoke AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE secmonit.usuario_revoke @user nvarchar(max), @database nvarchar(max), @execpor nvarchar(max), @tipo nvarchar(max) AS        
        
	DECLARE @statement   nvarchar(max)        
	DECLARE @kill varchar(8000) = '';          
	      
	IF OBJECT_ID(N'tempdb..#resultados_procedure') IS NOT NULL      
	BEGIN      
		DROP TABLE #resultados_procedure      
	END      
	      
	create table #resultados_procedure ([Database] sysname, [RoleName] sysname,[MemberName] sysname)        
	insert into #resultados_procedure ([Database], [RoleName],[MemberName])        
	exec dba.secmonit.sp_ListaPermissoes @user      
	        
	if exists(select 'X' from master.dbo.syslogins where loginname=@user) AND @database is NULL AND @tipo = 'Revogar'    
	BEGIN         
	 
		EXECUTE AS LOGIN = 'SA'

		BEGIN TRY  
			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
			FROM sys.dm_exec_sessions
			WHERE login_name = UPPER(@user)
			EXEC(@kill);
		END TRY 
		BEGIN CATCH
		END CATCH; 
	
	
		DECLARE @db nvarchar(max)        
		DECLARE datafiles_cursor CURSOR FAST_FORWARD        
		FOR select DISTINCT([Database]) from #resultados_procedure        
		OPEN datafiles_cursor;        
		FETCH NEXT FROM datafiles_cursor INTO @db;        
		WHILE @@fetch_status = 0        
		BEGIN        
			SELECT @statement = 'use '+@db +';' + 'DROP USER ['+@user+']'        
			exec (@statement)        
	                 
			insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)        
			select @db AS Nm_Database, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao        
	   
			FETCH NEXT FROM datafiles_cursor INTO @db        
		END;        
		CLOSE datafiles_cursor;        
		DEALLOCATE datafiles_cursor;        
	         
		SELECT @statement = 'use master;' + 'DROP LOGIN ['+@user+']'        
		EXEC (@statement)        
	              
	    insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)         
	    select CASE WHEN @user like '%\%' THEN 'WINDOWS' ELSE 'SQL' END Tp_Login, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao        
	   
		SELECT 'PERMISSIONAMENTO REMOVIDO' AS STATUS        
	        
	END        
	        
	        
	ELSE IF exists(select 'X' from master.dbo.syslogins where loginname=@user) AND @database IS NOT NULL AND (select COUNT(DISTINCT([Database])) from #resultados_procedure where [MemberName]=@user)>0 AND @tipo = 'Revogar'      
	BEGIN 

		EXECUTE AS LOGIN = 'SA'

		BEGIN TRY
			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
			FROM sys.dm_exec_sessions
			WHERE database_id  = db_id(@database) and login_name = UPPER(@user)
			EXEC (@kill)
		END TRY 
		BEGIN CATCH
		END CATCH;  
	
		SELECT @statement = 'use '+@database +';' + 'DROP USER ['+@user+']'        
		EXEC (@statement)        
	              
		insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)        
	    select @database AS Nm_Database, 'Drop' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao        
		  
		SELECT 'PERMISSIONAMENTO REMOVIDO' AS STATUS        
	        
	END
	
	ELSE IF (@tipo = 'Desabilitar')
	BEGIN

		EXECUTE AS LOGIN = 'SA'
	
		BEGIN TRY  
			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
			FROM sys.dm_exec_sessions
			WHERE login_name = UPPER(@user)
			EXEC(@kill);
		END TRY 
		BEGIN CATCH
		END CATCH;  
		 
		SELECT @statement = 'use master;' + 'ALTER LOGIN ['+@user+'] DISABLE'        
		exec (@statement)
		 
		insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)         
	    select CASE WHEN @user like '%\%' THEN 'WINDOWS' ELSE 'SQL' END Tp_Login, 'Disable' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao
	
		SELECT 'USUARIO DESABILITADO' AS STATUS   
	
	END
	
	ELSE IF (@tipo = 'Habilitar')
	BEGIN
	
		SELECT @statement = 'use master;' + 'ALTER LOGIN ['+@user+'] ENABLE'        
		exec (@statement)  
		 
		insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)         
	    select CASE WHEN @user like '%\%' THEN 'WINDOWS' ELSE 'SQL' END Tp_Login, 'Enable' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao
	
		SELECT 'USUARIO HABILITADO' AS STATUS  
	
	END


	ELSE IF (@tipo = 'Reset')
	BEGIN
		IF @user like '%\%'
			SELECT 'ALTERACAO DE SENHA SO PODE SER FEITA EM USUARIOS SQL AUTENTICATION' as STATUS
		ELSE
		BEGIN
			declare @letras varchar(max) = 'abcdefghijklmnopqrstuwvxzABCDEFGHIJKLMNOPQRSTUWVXZ1234567890@!$#()_@#$%', @pass nvarchar(13)
			;with cte as (
			    select 1 as contador,
						substring(@letras, 1 + (abs(checksum(newid())) % len(@letras)), 1) as letra
			    union all
			    select  contador + 1,
						substring(@letras, 1 + (abs(checksum(newid())) % len(@letras)), 1)
			    from cte where contador < 12)
			select @pass=(
			    select '' + letra from cte
			    for xml path(''), type, root('txt')).value ('/txt[1]', 'varchar(max)')
			option (maxrecursion 0)

			SELECT @statement ='ALTER LOGIN [' +@user+ '] WITH PASSWORD= N'''+@pass+''''
			exec sp_executesql @statement

			insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)         
			select CASE WHEN @user like '%\%' THEN 'WINDOWS' ELSE 'SQL' END Tp_Login, 'Reset' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao

			SELECT 'SENHA DO USUARIO '+@user+ ' ALTERADA PARA ' +@pass as STATUS
		END
	END

GO



-- ====================================
-- Description: Permissões necessárias
-- ====================================
USE [MASTER]
GO
GRANT IMPERSONATE ANY LOGIN TO [USR_SECURITY]


USE DBA
GO
GRANT EXECUTE ON DBA.SECMONIT.SP_LISTAPERMISSOES TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.SP_ACESSOS_ROLEDATABASE TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.SP_ACESSOS_EXPDATABASE TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.SP_ACESSOS_ROLES TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.SP_ACESSOS_EXPINSTANCIA TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.USUARIO_ACESSO TO [USR_SECURITY]
GRANT EXECUTE ON DBA.SECMONIT.USUARIO_REVOKE TO [USR_SECURITY]



-- ============================
-- Description: TESTE
-- ============================


select * from dba.secmonit.seg_audit_login order by 4 desc
select * from dba.secmonit.seg_audit_users order by 4 desc
select * from dba.secmonit.seg_audit_acessos order by 5 desc


exec dba.secmonit.usuario_acesso 'DOMINIO\USUARIO', NULL, 'DBA', 'R', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'R', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'RW', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'DDL', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'AGENT', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'SUSTENTACAO', 'EXECUTADO_POR_EDUARDO'
exec dba.secmonit.usuario_acesso 'USUARIO_TESTE', 'SENHA_TESTE123', 'DBA', 'OWNER', 'EXECUTADO_POR_EDUARDO'


exec dba.secmonit.sp_ListaPermissoes 'USUARIO_TESTE'
exec dba.secmonit.sp_acessos_roleDatabase 'USUARIO_TESTE'
exec dba.secmonit.sp_acessos_expDatabase 'USUARIO_TESTE'
exec dba.secmonit.sp_acessos_roles 'USUARIO_TESTE'
exec dba.secmonit.sp_acessos_expInstancia 'USUARIO_TESTE'


exec dba.secmonit.usuario_revoke 'DOMINIO\USUARIO', 'DBA', 'EXECUTADO_POR_EDUARDO', 'Revogar'
exec dba.secmonit.usuario_revoke 'USUARIO_TESTE', 'DBA', 'EXECUTADO_POR_EDUARDO', 'Revogar'
exec dba.secmonit.usuario_revoke 'USUARIO_TESTE', NULL, 'EXECUTADO_POR_EDUARDO', 'Revogar'
exec dba.secmonit.usuario_revoke 'USUARIO_TESTE', NULL, 'EXECUTADO_POR_EDUARDO', 'Desabilitar'
exec dba.secmonit.usuario_revoke 'USUARIO_TESTE', NULL, 'EXECUTADO_POR_EDUARDO', 'habilitar'
exec dba.secmonit.usuario_revoke 'USUARIO_TESTE', NULL, 'EXECUTADO_POR_EDUARDO', 'Reset'





-- ========================================================================================
-- Author     : Eduardo R Barbieri
-- Create date: 21/08/2021
-- Description: Consulta para auditoria de logins e usuários criados por fora da procedure
-- ========================================================================================


--Inserir caso o login nao exista na tabela de auditoria e caso tenha sido modificado ou criado nos ultimos 7 dias
--create table dba.secmonit.auditoria_logins ([Login] sysname, [Status] varchar(20), [Data_Criacao] datetime, [Data_Modificacao] datetime)
INSERT INTO  dba.secmonit.auditoria_logins
SELECT tabela.[Login], tabela.[Status], tabela.[Data_Criacao], tabela.[Data_Modificacao] from ( 
SELECT	 s.name [Login]
		,CASE WHEN s.is_disabled = 1 THEN 'Desabilitado' ELSE 'Habilitado' End [Status]
		,CONVERT(varchar, s.create_date, 120) [Data_Criacao]
		,CONVERT(varchar, s.modify_date, 120) [Data_Modificacao]
FROM  sys.server_principals s left join dba.secmonit.seg_audit_login l
on (s.name = l.Nm_Login and CONVERT(varchar, s.modify_date, 23) = CONVERT(varchar, l.Data_Atualizacao, 23))
where l.Data_Atualizacao is null AND (CONVERT(varchar, s.modify_date, 23) > CONVERT(varchar, getdate() - 7, 23))) as tabela left join dba.secmonit.auditoria_logins l
ON tabela.Login = l.Login and tabela.Data_Criacao = l.Data_Criacao and tabela.Data_Modificacao=l.Data_Modificacao WHERE l.Data_Modificacao is null

select * from dba.secmonit.auditoria_logins order by 4 desc






--Inserir caso o usuario nao exista na tabela de auditoria e caso tenha sido modificado ou criado nos ultimos 7 dias
--create table dba.secmonit.auditoria_usuarios ([Usuario] sysname, [Database] sysname, [Data_Criacao] datetime, [Data_Modificacao] datetime)
DECLARE @dbname NVARCHAR(255), @sql NVARCHAR(max)
DECLARE c CURSOR FORWARD_ONLY READ_ONLY FAST_FORWARD for
SELECT name FROM sys.databases 
WHERE state_desc = 'ONLINE';
OPEN c
FETCH NEXT FROM c INTO @dbname ;

WHILE @@fetch_status = 0
BEGIN
    set @sql =
    'use '+@dbname+'
	insert into dba.secmonit.auditoria_usuarios
    SELECT tabela.[Usuario], tabela.[Database], tabela.[Data_Criacao], tabela.[Data_Modificacao] FROM (
    select	s.name [Usuario]
			,'''+@dbname+''' [Database]
			,CONVERT(varchar, s.createdate, 120) [Data_Criacao]
			,CONVERT(varchar, s.updatedate, 120) [Data_Modificacao]
    from sys.sysusers s left join dba.secmonit.seg_audit_users u
	on (s.name = u.nm_login and CONVERT(varchar, s.updatedate, 23) = CONVERT(varchar, u.Data_Atualizacao, 23)) 
	where u.Nm_Login is null and (CONVERT(varchar, s.updatedate, 23) > CONVERT(varchar, getdate() - 7, 23))
	and s.name not in (''public'', ''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'', ''##MS_PolicyEventProcessingLogin##'', ''##MS_AgentSigningCertificate##'') and s.name not like ''db_%''
	and CONVERT(varchar, s.updatedate, 23) > CONVERT(varchar, getdate() - 7, 23)) tabela left join dba.secmonit.auditoria_usuarios a
	ON tabela.Usuario=a.Usuario and tabela.[Database]=a.[Database] and tabela.Data_Criacao=a.Data_Criacao and tabela.Data_Modificacao=a.Data_Modificacao WHERE a.Data_Modificacao is null';
    exec (@sql);
    FETCH NEXT FROM c INTO @dbname;
END
CLOSE C
DEALLOCATE c

select * from dba.secmonit.auditoria_usuarios order by 4 desc





