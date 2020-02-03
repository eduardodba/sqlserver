--Listar SYNONYMS
select base_object_name, name, create_date, * from sys.synonyms order by create_date desc


--Dropar um SYNONYM
DROP SYNONYM [dbo].[Titular_conjuge]


--Criar um SYNONYM
USE [platrelac]
GO
CREATE SYNONYM [dbo].[Tb_Parametro] FOR [BRCSFCBDVSQL005].[ManutencaodeCredito].[dbo].[TB_Parametro]
GO





