

--Depois
  ALTER view [dbo].[vw_database_new]    
as 
select     
 Host SERVIDOR_FISICO    
 ,'\' + ISNULL(Instance,'') INSTANCIA    
 ,ServeName CONNECTION    
 ,case             
 when ServeName like '%PANFDBP3047%' then 'PROD'            
 when ServeName like '%SDR%' then 'DR'            
 when ServeName like '%DBA%' then 'DBA'            
 when ServeName like '%TESTE%' then 'TESTE'            
 when ServeName like '%PANFDBP304%' then 'DEP'            
 when ServeName like '%PANVDBP304%' then 'DEP'         
 when ServeName like '%dbd%' then 'DEV'            
 when ServeName like '%DBQ%' then 'QA'            
 when ServeName like '%FRESH%' then 'RESTORE'            
 when ServeName like '%DBH%' then 'HML'            
 when ServeName like '%DBP%' then 'PROD'            
 ELSE '' END AMBIENTE    
 ,CASE WHEN startup_type_desc = 'Automatic' THEN 'AUTO' else 'MANUAL' end [START]    
 ,case when isnull(coleta,'2001-01-01') < GETDATE() - 20 then 'STOPPED' else 'RUNNING' end  [STATUS]    
 , upper(service_account) CONTA    
     , dbo.fn_MajorVersion(vw.[Version]) [MAJOR_VERSION]    
  ,vw.[VERSION]    
  ,vw.[EDITION]    
  ,PRODUCTLEVEL PRODUCT_LEVEL    
  ,ServerType SERVER_TYPE    
  ,ATIVO    
  ,Physical_CPUs Num_Proc    
  ,Server_Physical_MB / 1024 Memoria_em_GB    
  ,cores_per_socket Proc_of_Core    
  ,'' Modelo    
  ,DomainName Dominio    
  ,collation_name COLLATION_NAME    
  ,coleta CADASTRO    
  ,TcpPort PORTA    
  ,NULL IP_INSTANCE    
  ,b.[Release Date]            
  ,[Build_Atual]            
  ,[Release_Atual]            
  ,DATEDIFF(d, dbo.fn_build(vw.[VERSION]),GETDATE()) as [Build_Desatualizado_Dias]          
  ,DATEDIFF(m, dbo.fn_build(vw.[VERSION]),GETDATE()) as [Build_Desatualizado_Meses]          
  ,CASE WHEN DATEDIFF(d, dbo.fn_build(vw.[VERSION]),GETDATE()) > 91 THEN 'Desatualizado' Else 'Atualizado' END [Build_Situacao]          
  ,[Cumulative Update or Security ID] as [CU_Instancia]          
  ,[Cu_atual] as Last_CU       
 ,case when DomainName = 'PAN-MATRIZ' then 0 else 1 end sql_authentication     
from     
 dba.[ControlBD].[InfoSQL] vw    
   left join     
    Builds_SQLServer b            
     on     
      b.[Build number] = vw.[Version]     
   left join     
    (     
     select a.[Version] as [Version_Atual], a.[Build number] as [Build_Atual], a.[Release Date] as [Release_Atual] , a.[Cumulative Update or Security ID] as Cu_atual          
     from     
      Builds_SQLServer a            
     where     
      a.[Build number] =     
           (    
            select     
             max(b.[Build number])     
            from     
             Builds_SQLServer b where a.[Version] = b.[Version]    
           )            
     group by     
      a.[Version],     
      a.[Build number],     
      a.[KB number],     
      a.[Release Date],     
      a.[Cumulative Update or Security ID]    
     ) Build_Atual           
     on     
       dbo.fn_MajorVersion(vw.[Version])  = [Version_Atual]         
where ativo = 1 








  
ALTER FUNCTION [dbo].[fn_build](@Build nvarchar(510))   
RETURNS varchar(30)   
as  
begin  
  
DECLARE @Retorno date
DECLARE @temp as table ([Version] varchar(12), [Build number] nvarchar(510), [Release Date] date, RowNum int, [Release Date Seq] date)

    insert into @temp
    SELECT
        [Version],
        [Build number], 
        [Release Date],
        ROW_NUMBER() OVER (PARTITION BY [Version] ORDER BY [Release Date] DESC) AS RowNum,
        IIF(
            LAG([Release Date], 1, 0) OVER (PARTITION BY [Version] ORDER BY [Release Date] DESC) = '1900-01-01 00:00:00.000', [Release Date],
            LAG([Release Date], 1, 0) OVER (PARTITION BY [Version] ORDER BY [Release Date] DESC)
        ) AS [Release Date Seq]
    FROM 
        Builds_SQLServer
    ORDER BY 
        [Release Date] DESC;


    select @Retorno = CASE WHEN RowNum = 1 THEN GETDATE() ELSE [Release Date Seq] END from @temp where [Build number] = @Build


RETURN @Retorno   
  
END
