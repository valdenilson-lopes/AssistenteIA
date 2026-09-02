-- Start of DDL Script for View MARMORE.BI_EMPRESA_FLYGESTOR
-- Generated 19-set-2024 10:35:04 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_empresa_flygestor (
   idempresa,
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
SELECT

                       CAST(filial.codfilial AS NUMBER) AS idempresa,

                       CAST(filial.nomefantasia AS VARCHAR2(70))         AS nome,

                       CAST(filial.filial AS VARCHAR2(70))              AS razaosocial,

                       CAST(filial.cpfcnpj  AS VARCHAR2(70))             AS cnpj,

                       CAST(filial.codmunicipio AS VARCHAR2(70))         AS codcidade,

                       CAST(filial.cidade AS VARCHAR2(70)) AS CIDADE,

                       CAST(filial.estado AS VARCHAR(2)) AS ESTADO,

                       CAST(filial.endereco AS VARCHAR2(70))AS logradouro,

                       CAST(filial.numero AS VARCHAR2(20)) AS NUMERO,

                       CAST(filial.bairro AS VARCHAR2(70)) AS BAIRRO,

                       CAST(filial.complemento AS VARCHAR2(70)) AS COMPLEMENTO,

                       CAST(filial.cep AS VARCHAR2(20)) AS CEP

FROM                   filial
/


-- End of DDL Script for View MARMORE.BI_EMPRESA_FLYGESTOR

