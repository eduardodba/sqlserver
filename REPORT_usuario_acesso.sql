--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA','DDL','SA' 
--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA1','R','SA'
--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA2','RW','SA'
--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA2','AGENT','SA'
--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA2','SUSTENTACAO','SA'
--exec dba.dbo.usuario_acesso 'USR_TESTE1','P@ssw0rd@','DBA2','OWNER','SA'

CREATE OR ALTER PROCEDURE usuario_acesso @user nvarchar(max), @pass nvarchar(max), @database nvarchar(max), @acesso nvarchar(max), @execpor nvarchar(max) AS  
   
                DECLARE @statement   nvarchar(max)  
   
                IF SUSER_ID(@user) IS NULL  
                BEGIN  
                               IF @user like '%\%'  
                               BEGIN  
                                               --LOG LOGIN  
                                               insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao) select 'WINDOWS' as Tp_Login, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao  
                                               SELECT @statement =   'CREATE LOGIN ['+@user+ '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'  
                                               exec sp_executesql @statement  
                               END  
                               ELSE  
                               BEGIN  
                                               --LOG LOGIN  
                                               insert into DBA.secmonit.seg_audit_login (Tp_Login, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao) select 'SQL' as Tp_Login, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao, @execpor as Nm_Login_Alteracao  
                                               SELECT @statement = 'CREATE LOGIN [' +@user+ '] WITH PASSWORD=N'''+@pass+''' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON'  
                                               exec sp_executesql @statement  
                               END  
   
                                 
   
                END  
   
   
                if (@acesso = 'R')  
                BEGIN  
                               --GRANT READ  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE LEITURA' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
  
END  
   
                ELSE IF (@acesso = 'RW')  
                BEGIN  
   
                               --GRANT READ  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'  
                               exec sp_executesql @statement  
                 
                               --GRANT WRITER  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datawriter'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE ESCRITA' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
  
   
END  
   
                ELSE IF (@acesso = 'DDL')  
                BEGIN  
   
                               --GRANT READ  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'  
                               exec sp_executesql @statement  
                 
                               --GRANT WRITER  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datawriter'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               --GRANT DDL ADMIN  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_ddladmin'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE LEITURA, ESCRITA E DDL ADMIN' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
  
    END  
   
                ELSE IF (@acesso = 'EXECUTE')  
                BEGIN  
                                
                               --GRANT READ  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'grant execute to [' +@user+ '];'  
                               exec sp_executesql @statement  
                 
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE EXECUTE' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
   
END  
   
   
                ELSE IF (@acesso = 'AGENT')  
                BEGIN  
   
                               SELECT @statement = 'use msdb;' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'  
                               exec sp_executesql @statement  
                 
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use msdb;' + 'ALTER ROLE [ServerGroupAdministratorRole] ADD MEMBER [' +@user+ '];'+  
                               'ALTER ROLE [ServerGroupReaderRole] ADD MEMBER [' +@user+ '];'+'ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [' +@user+ '];'+  
                               'ALTER ROLE [SQLAgentReaderRole] ADD MEMBER [' +@user+ '];'+'ALTER ROLE [SQLAgentUserRole] ADD MEMBER [' +@user+ '];'  
                 
                               exec sp_executesql @statement  
                 
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO NO AGENT' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
   
END  
   
   
                ELSE IF (@acesso = 'SUSTENTACAO')  
                BEGIN  
   
                               SELECT @statement = 'use master;' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_datareader'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               set @statement =  
                                                                                  'use master;' +'grant VIEW SERVER STATE to [' + @user + ']  
                                                                                              grant execute on sp_who2 to [' + @user + ']  
                                                                                              grant execute on sp_who3 to [' + @user + ']  
                                                                                              GRANT VIEW DEFINITION to [' + @user + ']  
                                                                                              grant alter trace to       [' + @user + ']'  
   
                               exec sp_executesql @statement  
                 
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE SUSTENTACAO' AS STATUS  
  
        --LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
   
END  
                 
                ELSE IF (@acesso = 'OWNER' and @@SERVERNAME like '%PANFDBP304%')  
                BEGIN  
   
                               --GRANT READ  
                               SELECT @statement = 'use '+@database +';' + 'IF USER_ID('''+@user+''') IS NULL'+ CHAR(13) + 'CREATE USER [' +@user+ '] FOR LOGIN [' +@user+ '];'  
                               exec sp_executesql @statement  
                               SELECT @statement = 'use '+@database +';' + 'EXEC sp_addrolemember N''db_owner'', [' +@user+ '];'  
                               exec sp_executesql @statement  
   
                               SELECT 'USUARIO ' + UPPER(@user) + ' CRIADO COM ACESSO DE OWNER' AS STATUS  
  
								--LOG USER  
                               insert into DBA.secmonit.seg_audit_users (Nm_Database, Tp_Atualizacao, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
                               select CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database, 'Create' as Tp_Atualizacao, @user, GETDATE() as Data_Atualizacao,           @execpor as Nm_Login_Alteracao  
   
                END  
   
   
							if(@statement is not null)
							BEGIN
               					--LOG GRANT  
                               insert into DBA.secmonit.seg_audit_acessos(Nm_Database, Tp_Acesso, Desc_Comando_Executado, Nm_Login, Data_Atualizacao, Nm_Login_Alteracao)  
								select  CASE WHEN @acesso = 'SUSTENTACAO' THEN 'master'  
                                               WHEN @acesso = 'AGENT' THEN 'msdb'  
                               ELSE @database END Nm_Database,  
                               CASE WHEN @acesso = 'R' THEN 'Leitura'  
                                               WHEN @acesso = 'RW' THEN 'Gravacao'  
                               ELSE @acesso  
                               END Tp_Acesso,  
                               @statement as Desc_Comando_Executado,  
                               @user as Nm_Login,  
                               getdate() as Data_Atualizacao,  
                               @execpor as Nm_Login_Alteracao  
 							END
   
               
   
   
               
