declare @tb_plantao table (id int primary key, nome varchar(100), telefone varchar(50))
insert into @tb_plantao values  (1,'dba1', '9-9999-9999'),
								(2,'dba2', '9-9999-9998'),
								(3,'dba3', '9-9999-9997'),
								(4,'dba4', '9-9999-9996'),
								(5,'dba5', '9-9999-9996');

if OBJECT_ID('tempdb..#plantao') is not null
	drop table #plantao
create table #plantao (Nome varchar(100), Telefone varchar(50), Inicio date, Fim date)

DECLARE @DATE DATE = GETDATE()
SET DATEFIRST 6
SELECT @DATE = DATEADD(D, 7 - DATEPART(DW, @DATE), @DATE)

DECLARE @ANO INT = YEAR(GETDATE())
WHILE @ANO+1 >= YEAR(@DATE)
BEGIN
	
	INSERT INTO #plantao 
	SELECT TOP 1 P.NOME, P.TELEFONE, @DATE AS INICIO, DATEADD(DAY,2,@DATE) AS FIM FROM @TB_PLANTAO P ORDER BY ID ASC
	SET @DATE = DATEADD(DAY, 7, @DATE)
	UPDATE TOP (1) @TB_PLANTAO SET ID = ID_A FROM (SELECT MAX(P.ID)+1 AS ID_A FROM @TB_PLANTAO P) AS TAB

END

select * from #plantao order by inicio
