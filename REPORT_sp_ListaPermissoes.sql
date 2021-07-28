--exec dba.dbo.sp_ListaPermissoes 'USR_TESTE1'   


create   proc sp_ListaPermissoes @user varchar(100) AS  
CREATE TABLE #RolesMembers (  
    [Database] sysname,  
    RoleName sysname,  
    MemberName sysname)  
EXEC dbo.sp_MSforeachdb 'insert into #RolesMembers select ''[?]'', ''['' + r.name + '']'', ''['' + m.name + '']''  
FROM [?].sys.database_role_members rm  
INNER JOIN [?].sys.database_principals r ON rm.role_principal_id = r.principal_id  
INNER JOIN [?].sys.database_principals m ON rm.member_principal_id = m.principal_id  
INNER JOIN [?].sys.database_permissions e ON e.grantee_principal_id=m.principal_id';  
SELECT * FROM #RolesMembers  
WHERE MemberName like '%'+@user+'%'  
ORDER BY [Database], [RoleName]
