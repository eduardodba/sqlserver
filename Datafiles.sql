--Tamanho dos datafiles
select DB_NAME(b.dbid),b.dbid, a.name as 'dbname', b.size/128 as 'Size MB', 
b.fileid, growth/128 as 'GROWTH',a.name as 'Logic Name', b.filename from master..sysdatabases a 
left join master..sysaltfiles b on a.dbid = b.dbid
where b.filename like '%D:\%'
order by 4 desc


--select * from sysaltfiles


/*
--ldf+mdf
select a.name as 'dbname', SUM(b.size/128) as 'Size MB'from master..sysdatabases a 
left join master..sysaltfiles b on a.dbid = b.dbid
--where a.name NOT IN ('master','model','msdb','tempdb','DBA')
group by a.name order by 1 
*/
