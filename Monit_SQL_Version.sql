DECLARE @tab as Table (result varchar(100), servidor varchar(100), instancia varchar(100), versao varchar(100))
DECLARE @cmd nvarchar(2000)
DECLARE @name VARCHAR(50) 

DECLARE nodes CURSOR FOR 
	SELECT NodeName FROM sys.dm_os_cluster_nodes
OPEN nodes  
FETCH NEXT FROM nodes INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN 
	set @cmd = 'powershell.exe -command Invoke-Command -ComputerName '+@name+' -ScriptBlock { foreach ($Install in (Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'').InstalledInstances){write-host $Install $((Get-ItemProperty ^"^"^"HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$((Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'').$Install)\Setup""^")).Version}}'
	insert into @tab (result)
	exec xp_cmdshell @cmd
	update @tab set servidor = @name where servidor is null
	FETCH NEXT FROM nodes INTO @name 
END 
CLOSE nodes  
DEALLOCATE nodes 

SELECT
    servidor,
    LEFT(result, CHARINDEX(' ', result) - 1) AS instancia,
    RIGHT(result, LEN(result) - CHARINDEX(' ', result)) AS versao
FROM (SELECT * from @tab AS ValorOriginal) AS t
where result is not null



