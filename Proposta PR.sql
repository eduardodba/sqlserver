use credito
		select p.NU_PROP, p.NU_PROCINSTNEGOC, P.DH_CRIAC,p.CD_MODALPROP, d.DS_VLDOMIN, P.NM_LOJAPROP, p.CD_STATUSPROP, T.NU_CPFTIT
		from credito.dbo.TB_Proposta P with (nolock)
		Inner Join credito.dbo.TB_TITULAR_DETALHE T on  p.ID_TITDET = T.ID_TITDET
		Inner Join corporativo.dbo.TB_VALOR_DOMINIO D on CONVERT(varchar,p.CD_STATUSPROP) = d.CD_VLDOMIN
		Left Join pr..TB_PROCESD_CONTROLE pd on pd.NU_PROPTIT = p.NU_PROP
		where (p.CD_STATUSPROP in (9, 10, 11, 12, 13, 17, 18, 19, 27, 28, 29, 33, 30)
		and p.DH_ALT <= DATEADD(SECOND,-180,GETDATE()) and d.CD_TPDOMIN = 4)
		and p.DH_Criac >= '2017-09-27'
		order by p.DH_CRIAC 