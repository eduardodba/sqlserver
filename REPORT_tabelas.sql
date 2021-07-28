USE [dba]
GO
CREATE SCHEMA [secmonit] AUTHORIZATION [dbo]
GO
 

create table secmonit.seg_audit_users (
                Nm_Database sysname not null,
                Tp_Atualizacao varchar(20) not null, -- Create , Drop
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                )
 
create table secmonit.seg_audit_login (
                Tp_Login varchar(20)  not null , -- Sql ou Windows
                Tp_Atualizacao varchar(20) not null, -- Create , Drop
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                )
               
create table secmonit.seg_audit_acessos (
                Nm_Database sysname not null,
                Tp_Acesso varchar(20) not null, -- Leitura , Insert, Update, Exec...
                Desc_Comando_Executado varchar(500) not null,
                Nm_Login sysname not null ,
                Data_Atualizacao smalldatetime not null ,
                Nm_Login_Alteracao sysname not null
                )
                
                
--CONSULTAS
select * from DBA.secmonit.seg_audit_login
select * from DBA.secmonit.seg_audit_users
select * from DBA.secmonit.seg_audit_acessos
