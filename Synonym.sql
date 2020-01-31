--Listar SYNONYMS
select base_object_name, name, create_date, * from sys.synonyms order by create_date desc


--Dropar um SYNONYM
DROP SYNONYM [dbo].[Titular_conjuge]


--Criar um SYNONYM
CREATE SYNONYM [dbo].[Titular_conjuge] FOR BRCSFCBDVSQL005.ExcellerWeb.dbo.Titular_conjuge






