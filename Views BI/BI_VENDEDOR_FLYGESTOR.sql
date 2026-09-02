-- Start of DDL Script for View MARMORE.BI_VENDEDOR_FLYGESTOR
-- Generated 19-set-2024 10:36:22 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_vendedor_flygestor (
   idvendedor,
   vendedor,
   nomecompleto,
   cidade,
   telefone1,
   telefone2,
   cpf,
   dtcadastro,
   codfilial,
   inativo,
   tipo )
AS
SELECT CAST(V.codvend AS NUMBER(6))    AS IDVENDEDOR,

         CAST(V.nome AS VARCHAR2(70))      AS VENDEDOR,

         CAST(V.nome AS VARCHAR2(70))       AS NOMECOMPLETO,

         CAST(V.cidade

         ||'/'

         ||V.estado AS VARCHAR2(70))  AS CIDADE,

         CAST(V.telefone  AS VARCHAR2(20))  AS TELEFONE1,

         CAST(V.telefone2 AS VARCHAR2(20))  AS TELEFONE2,

         CAST(V.cpf AS VARCHAR2(20))    AS CPF,

         V.dtadmissao AS DTCADASTRO,

         CAST(F.CODFILIAL AS NUMBER ) AS CODFILIAL ,

         CASE WHEN V.DTDEMISSAO IS NOT NULL THEN 'S' ELSE 'N' END AS INATIVO,

         'V' AS TIPO

  FROM   vendedor V , FILIAL F
/


-- End of DDL Script for View MARMORE.BI_VENDEDOR_FLYGESTOR

