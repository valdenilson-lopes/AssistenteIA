-- Start of DDL Script for View MARMORE.BI_ESTOQUE_FLYGESTOR
-- Generated 19-set-2024 10:35:22 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_estoque_flygestor (
   codfilial,
   filial,
   codlocal,
   local,
   codfabr,
   codprodutofabr,
   fabricante,
   codgrupo,
   grupo,
   codproduto,
   produto,
   codncm,
   sittributaria,
   sittributariapis,
   sittributariacofins,
   mesanoest,
   tipoprod,
   totpesobruto,
   sdofisico,
   prateleira,
   sdofinanc,
   sdopedidofor,
   sdofinancusto,
   sdofinanccustocm,
   rentabilidade,
   custocompra,
   precovenda,
   unidade,
   idempresa )
AS
SELECT CAST(E.codfilial  AS NUMBER)                    AS CODFILIAL,

         CAST(SUBSTR(FL.filial,1,30) AS VARCHAR2(30) )         AS FILIAL,

         CAST(D.codepto AS VARCHAR2(4))                      AS codlocal,

         CAST(D.departamento AS VARCHAR2(30))                  AS local,

         CAST(PF.codfornec AS VARCHAR2(12))                    AS codfabr,

         CAST(PF.codprodfor AS VARCHAR2(20))                   AS codprodutofabr,

         CAST( REPLACE(F.fornecedor,';',',') AS VARCHAR2(50))                    AS fabricante,

         CAST(D.codepto AS VARCHAR2(15))                       AS codgrupo,

         CAST(REPLACE(D.departamento,';',',')  AS VARCHAR2(50))                 AS grupo,

         CAST(P.codprod AS VARCHAR2(20))                       AS codproduto,

         CAST(REPLACE(P.descricao,';',',') AS VARCHAR2(50))                     AS produto,

         CAST(P.cod_ncm  AS VARCHAR2(20))                      AS codncm,

         CAST(P.sittributcomp AS VARCHAR2(4))                 AS sittributaria,

         P.cstpis                        AS sittributariapis,

         P.cstcofins                     AS sittributariacofins,

         To_char (E.dtultent, 'MM/YYYY') AS mesanoest,

         CAST(CASE

           WHEN p.tipoprod = 'MR'

                 OR p.tipoprod IS NULL THEN 'MERCADORIA PARA REVENDA'

           WHEN p.tipoprod = 'SE' THEN 'SERVIÇOS'

           WHEN p.tipoprod = 'PA' THEN 'PRODUTO ACABADO'

           WHEN p.tipoprod = 'UC' THEN 'USO E CONSUMO'

           WHEN p.tipoprod = 'MP' THEN 'MATÉRIA PRIMA'

           WHEN p.tipoprod = 'SP' THEN 'SUB-PRODUTO'

           WHEN p.tipoprod = 'AI' THEN 'ATIVO IMOBILIZADO'

           WHEN p.tipoprod = 'OT' THEN 'OUTROS'

           WHEN p.tipoprod = 'OI' THEN 'OUTROS INSUMOS'

           WHEN p.tipoprod = 'EP' THEN 'PRODUTO EM PROCESSO'

           WHEN p.tipoprod = 'EM' THEN 'EMBALAGENS'

           WHEN p.tipoprod = 'PI' THEN 'PRODUTO INTERMEDIARIO'

           ELSE 'A DEFINIR'

         END  AS VARCHAR2(13))                           AS tipoprod,

         P.pesobruto                     AS totpesobruto,

         E.qtestger                      AS sdofisico,

         CAST('' AS VARCHAR2(20))                              AS prateleira,

         CAST('' AS VARCHAR2(17))                             AS sdofinanc,

         CAST(0 AS VARCHAR(9))                              AS sdopedidofor,

         CAST(E.custoreal AS NUMBER (18,6))                     AS sdofinancusto,

         CAST(0 AS NUMBER (17))                              AS sdofinanccustocm,

         ROUND(EM.PVENDA-E.CUSTOREAL,2)                             AS rentabilidade,

         CAST(E.custoultent AS NUMBER(18,6))                  AS custocompra,

         CAST(EM.pvenda AS NUMBER (18,6))                      AS precovenda,

         CAST(trim(EM.unidade) AS VARCHAR2(4))                AS unidade,

         CAST(E.codfilial AS NUMBER)                     AS IDEMPRESA

  FROM   estoque E

         inner join filial FL

                 ON E.codfilial = FL.codfilial

         inner join produto P

                 ON E.codprod = P.codprod

         left join prodfornec PF

                ON P.codprod = PF.codprod

         inner join depto D

                 ON P.codepto = D.codepto

         left join fornecedor F

                 ON PF.codfornec = F.codfornec

         inner join embalagemregiao EM

                 ON P.codbarra = Em.codbarra

                 and p.codprod=em.codprod

                 and em.numregiao=1
/


-- End of DDL Script for View MARMORE.BI_ESTOQUE_FLYGESTOR

