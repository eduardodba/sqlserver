--Tamanho dos datafiles
select b.dbid, a.name as 'dbname', b.size/128 as 'Size MB', 
b.fileid, growth/128 as 'GROWTH',a.name as 'Logic Name', b.filename from master..sysdatabases a 
left join master..sysaltfiles b on a.dbid = b.dbid
--where b.fileid <> 1
order by 3 desc


--select * from sysaltfiles


/*
--ldf+mdf
select a.name as 'dbname', SUM(b.size/128) as 'Size MB'from master..sysdatabases a 
left join master..sysaltfiles b on a.dbid = b.dbid
--where a.name NOT IN ('master','model','msdb','tempdb','DBA')
group by a.name order by 1 
*/