--Deixa OFFLINE e derruba todos as conex�es
USE MASTER
GO
ALTER DATABASE curso SET OFFLINE WITH ROLLBACK IMMEDIATE

�
----Colocar  ONLINE
USE MASTER
GO
ALTER DATABASE curso SET ONLINE 

--BD modo unico usuario�
USE MASTER;
GO
ALTER DATABASE curso SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

--BD modo de leitura
ALTER DATABASE curso SET READ_ONLY;
GO
--BD modo nultusuario
ALTER DATABASE curso SET MULTI_USER;
GO
--BD leitura e gravacao
ALTER DATABASE curso SET READ_WRITE;
GO
