
set rowcount 4000
declare @datacorte datetime
select @datacorte = getdate() -364

BEGIN
;
with A 
as
(select top (4000) DH_INCL from [TB_CONTA_FATURA] with (nolock) where  DH_INCL <= @datacorte order by dh_incl desc)
delete A
END