-- Start of DDL Script for View MARMORE.BI_FILIAL_FLYGESTOR
-- Generated 19-set-2024 10:35:38 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_filial_flygestor (
   idfilial,
   nome,
   razaosocial,
   cnpj,
   codcidade,
   cidade,
   estado,
   logradouro,
   numero,
   bairro,
   complemento,
   cep )
AS
SELECT CAST(codfilial AS NUMBER)    AS IDFILIAL,

         nomefantasia AS NOME,

         filial       AS RAZAOSOCIAL,

         cpfcnpj      AS CNPJ,

         codmunicipio AS CODCIDADE,

         cidade,

         estado,

         endereco     AS LOGRADOURO,

         numero,

         bairro,

         complemento,

         cep

  FROM   filial
/


-- End of DDL Script for View MARMORE.BI_FILIAL_FLYGESTOR

