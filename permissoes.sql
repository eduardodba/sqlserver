--Listar Permissoes de usuario
USE DATABASE
GO
SELECT sys.schemas.name 'Schema'
,sys.objects.name Object
,sys.database_principals.name username
--,sys.database_permissions.type permissions_type
,sys.database_permissions.permission_name
--,sys.database_permissions.state permission_state
,sys.database_permissions.state_desc
,state_desc + ' ' + permission_name + ' on ['+ sys.schemas.name + '].[' + sys.objects.name + '] to [' + sys.database_principals.name + ']' COLLATE LATIN1_General_CI_AS as Command
FROM sys.database_permissions 
JOIN sys.objects ON sys.database_permissions.major_id =sys.objects.object_id 
JOIN sys.schemas ON sys.objects.schema_id = sys.schemas.schema_id 
JOIN sys.database_principals ON sys.database_permissions.grantee_principal_id =sys.database_principals.principal_id 
--WHERE sys.objects.name like '%Endereco%'
ORDER BY 1, 3, 5




--Listar por base as Roles e seus usuarios
CREATE TABLE ##RolesMembers (
    [Database] sysname,
    RoleName sysname,
    MemberName sysname)
EXEC dbo.sp_MSforeachdb 'insert into ##RolesMembers select ''[?]'', ''['' + r.name + '']'', ''['' + m.name + '']'' 
FROM [?].sys.database_role_members rm 
INNER JOIN [?].sys.database_principals r ON rm.role_principal_id = r.principal_id
INNER JOIN [?].sys.database_principals m ON rm.member_principal_id = m.principal_id
-- where r.name = ''db_owner'' and m.name != ''dbo'' -- you may want to uncomment this line';
SELECT * FROM ##RolesMembers
ORDER BY [Database], [RoleName]
DROP TABLE ##RolesMembers




--Listar usuarios sysadmin
SELECT   name,type_desc,is_disabled
FROM     master.sys.server_principals 
WHERE    IS_SRVROLEMEMBER ('sysadmin',name) = 1
ORDER BY name

