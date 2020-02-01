--HABILITANDO O BPE (BUFFER POOL EXTENSION)
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON
(FILENAME = 'F:\SSDBUFFERPOOL.BPE',
SIZE = 50 GB)



--Retornando informações de configuração do Buffer Pool extension
SELECT path, file_id, state, state_description, current_size_in_kb  
FROM sys.dm_os_buffer_pool_extension_configuration;  



--Retornando o número de páginas armazenadas em cache do arquivo de extensão do Buffer Pool extension
SELECT COUNT(*) AS cached_pages_count  
FROM sys.dm_os_buffer_descriptors  
WHERE is_in_bpool_extension <> 0;  



