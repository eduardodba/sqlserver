USE master
GO

ALTER DATABASE dbCockpit 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE
GO

EXEC master..sp_renamedb 'dbCockpit','dbCockpit_old'
GO

ALTER DATABASE dbCockpit_old 
SET MULTI_USER 
GO



USE master
GO

/* Identify Database File Names */
SELECT 
name AS [Logical Name], 
physical_name AS [DB File Path],
type_desc AS [File Type],
state_desc AS [State] 
FROM sys.master_files
WHERE database_id = DB_ID(N'dbCockpit_old')
GO



/* Set Database as a Single User */
ALTER DATABASE dbCockpit_old SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

/* Change Logical File Names */
ALTER DATABASE dbCockpit_old MODIFY FILE (NAME=N'dbCockpit', NEWNAME=N'dbCockpit_old')
GO

ALTER DATABASE dbCockpit_old MODIFY FILE (NAME=N'dbCockpit _log', NEWNAME=N'dbCockpit_old_log')
GO



/* Detach Current Database */
USE [master]
GO

EXEC master.dbo.sp_detach_db @dbname = N'dbCockpit_old'
GO



/* Rename Physical Files */



/* Attach Renamed ProductsDB Database Online */
USE [master]
GO

CREATE DATABASE dbCockpit_old ON 
( FILENAME = N'I:\_data\dbCockpit2_old.mdf' ),
( FILENAME = N'I:\_data\dbCockpit2_old.ldf' )
FOR ATTACH
GO




/* Set Database to Multi User*/
ALTER DATABASE dbCockpit_old SET MULTI_USER 
GO



USE master
GO

/* Identify Database File Names */
SELECT 
name AS [Logical Name], 
physical_name AS [DB File Path],
type_desc AS [File Type],
state_desc AS [State] 
FROM sys.master_files
WHERE database_id = DB_ID(N'dbCockpit_old')
GO
