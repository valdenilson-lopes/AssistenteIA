-- Start of DDL Script for View MARMORE.BI_VENDA_FLYGESTOR
-- Generated 19-set-2024 10:36:09 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_venda_flygestor (
   anovenda,
   mesvenda,
   semana,
   dia,
   datamovimento,
   codfilial,
   filial,
   codlocal,
   local,
   tipomovimento,
   idvendedor,
   vendedor,
   hora_oper,
   idfabricante,
   fabricante,
   idgrupo,
   grupo,
   natitem,
   bairro,
   cidade,
   nomeregiao,
   categoria,
   nomeclifor,
   codclifor,
   tipopessoa,
   condpag,
   pontovenda,
   codproduto,
   produto,
   codprodutofabr,
   idprecotabela,
   statusprod,
   percdesconto,
   dscstatusmov,
   idexpedicao,
   uniditemmov,
   qtitensvenda,
   cmv_a,
   totpesobruto,
   qtnaoatend,
   vrvenda,
   vroperacao,
   idmov,
   totmov,
   idtransportador,
   transportador,
   transportadorplaca,
   transportadorcidade,
   numerofrete,
   pesobruto,
   pesoliquido,
   dataentradasaida,
   observacoes,
   id_ambiente,
   desc_ambiente,
   id_servico,
   desc_servico,
   id_arquiteto,
   arquiteto,
   data_integracao,
   cliente_orcamento )
AS
(

  /* =========================================================================================================

   | IMPLEMENTADA POR.....: Gabriel Morais                                                                   |

   | DATA IMPLEMENTACAO...: 18/12/2019                                                                       |

   | VERSAO ATUAL.........: 20.03.13.01                                                                      |

   |---------------------------------------------------------------------------------------------------------|

   ===========================================================================================================

   |*******************************************| ALTERACOES |************************************************|

   ===========================================================================================================

   | * NR.TRF * | * ALTERADO POR * | * MODIFICADO EM * | * JUSTIFICATIVA *                                   |

   ===========================================================================================================

   |   #4201    |  Gabriel Morais  |    18/12/2019     |  Ajuste no join PARCINDICA e CABPEDAUX              |

   |---------------------------------------------------------------------------------------------------------|

   |   #4510    |  Gabriel Morais  |    13/02/2020     |  Ajuste para incluir cliente_orcamento              |

   |---------------------------------------------------------------------------------------------------------|

   |   #4701    |  Gabriel Morais  |    13/03/2020     |  Ajuste para retornoar corretamente fabricantes     |

   |---------------------------------------------------------------------------------------------------------|



   |***********************************| PROCEDURE UTILIZADA POR |*******************************************|

   ===========================================================================================================

   | * CODIGO * | * TELAS *                                                                                  |

   ===========================================================================================================

   |    9220    |  Views                                                                                     |

   ==========================================================================================================*/

 SELECT CAST(TO_CHAR(C.DTEMISSAO, 'YYYY') AS NUMBER(4, 0))                                          AS ANOVENDA,

         CAST(TO_CHAR(C.DTEMISSAO, 'MM') AS NUMBER(4, 0))                                            AS MESVENDA,

         CAST (TO_CHAR(C.DTEMISSAO, 'WW') AS NUMBER(4, 0))                                           AS SEMANA,

         CAST(TO_CHAR(C.DTEMISSAO, 'DD') AS NUMBER(4, 0))                                            AS DIA,

         C.DTEMISSAO                                                                                 AS DATAMOVIMENTO,

         CAST(C.CODFILIAL AS NUMBER)                                                                 AS CODFILIAL,

         SUBSTR(FL.FILIAL, 1, 30)                                                                    AS FILIAL,

         CAST(D.CODEPTO AS VARCHAR2(4))                                                              AS CODLOCAL,

         CAST(D.DEPARTAMENTO AS VARCHAR2(40))                                                        AS LOCAL,

         CAST(CASE

                WHEN C.POSICAO = 'O' THEN 'ORCAMENTO'

                WHEN C.POSICAO = 'F'

                     AND C.TIPO = '36' THEN 'VENDA PEDIDO'

                WHEN C.POSICAO = 'F'

                     AND C.TIPO = '35' THEN 'VENDA CONTRATO'

                ELSE 'OUTROS'

              END AS VARCHAR2(20))                                                                   AS TIPOMOVIMENTO,

         CAST(C.CODVEND AS VARCHAR2(10))                                                             AS IDVENDEDOR,

         CAST(V.NOME AS VARCHAR2(60))                                                                AS vendedor,

         CAST('' AS NUMBER (4, 0))                                                                   AS HORA_OPER,

         CAST(P.CODFORNECPRINC AS VARCHAR2(20))                                                      AS IDFABRICANTE,

         SUBSTR(F.FORNECEDOR, 1, 50)                                                                 AS FABRICANTE,

         CAST(D.CODEPTO AS NUMBER (4, 0))                                                            AS IDGRUPO,

         CAST(D.DEPARTAMENTO AS VARCHAR2(60))                                                        AS GRUPO,

         CAST('Venda de produção do estabelecimento' AS VARCHAR2(60))                                AS NATITEM,

         CAST(CL.BAIRRO AS VARCHAR2(20))                                                             AS BAIRRO,

         CAST(CL.CIDADE AS VARCHAR2(35))                                                             AS CIDADE,

         CAST(PR.DESCRICAO AS VARCHAR2(50))                                                          AS NOMEREGIAO,

         RA.RAMO                         AS CATEGORIA,

         CL.CLIENTE                                                                                  AS NOMECLIFOR,

         'C'

         || LPAD(CL.CODCLI, 6, '0')                                                                  AS CODCLIFOR,

         CAST(CASE

                WHEN CL.TIPOFJ = 'F' THEN 'Física'

                ELSE 'Jurídica'

              END AS VARCHAR2(8))                                                                    AS TIPOPESSOA,

         CAST(CASE

                WHEN C.CODPLPAG = 1 THEN 'VENDA A VISTA'

                ELSE 'VENDA A PRAZO'

              END AS VARCHAR2(50))                                                                   AS CONDPAG,

         CAST('' AS VARCHAR2(40))                                                                    AS PONTOVENDA,

         CAST(P.CODPROD AS VARCHAR2(20))                                                             AS codproduto,

         CAST(P.DESCRICAO AS VARCHAR2(150))                                                           AS PRODUTO,

         CAST(PF.CODPRODFOR AS VARCHAR2(20))                                                         AS CODPRODUTOFABR,

         CAST('PREÇO NORMAL' AS VARCHAR2(20))                                                       AS IDPRECOTABELA,

         CAST(CASE

                WHEN P.TIPOPROD = 'MR'

                      OR P.TIPOPROD IS NULL THEN 'MERCADORIA PARA REVENDA'

                WHEN P.TIPOPROD = 'SE' THEN 'SERVIÇOS'

                WHEN P.TIPOPROD = 'PA' THEN 'PRODUTO ACABADO'

                WHEN P.TIPOPROD = 'UC' THEN 'USO E CONSUMO'

                WHEN P.TIPOPROD = 'MP' THEN 'MATÉRIA PRIMA'

                WHEN P.TIPOPROD = 'SP' THEN 'SUB-PRODUTO'

                WHEN P.TIPOPROD = 'AI' THEN 'ATIVO IMOBILIZADO'

                WHEN P.TIPOPROD = 'OT' THEN 'OUTROS'

                WHEN P.TIPOPROD = 'OI' THEN 'OUTROS INSUMOS'

                WHEN P.TIPOPROD = 'EP' THEN 'PRODUTO EM PROCESSO'

                WHEN P.TIPOPROD = 'EM' THEN 'EMBALAGENS'

                WHEN P.TIPOPROD = 'PI' THEN 'PRODUTO INTERMEDIARIO'

                ELSE 'A DEFINIR'

              END AS VARCHAR2(30))                                                                   AS STATUSPROD,

         CAST(C.PERDESC AS FLOAT(25))                                                                AS PERCDESCONTO,

         CAST('' AS VARCHAR2(20))                                                                    AS DSCSTATUSMOV,

         CAST('' AS VARCHAR2(4))                                                                     AS IDEXPEDICAO,

         CAST(P.EMBALAGEM AS VARCHAR2(12))                                                           AS UNIDITEMMOV,

         CAST(I.QTPEDIDA AS NUMBER (18, 6))                                                          AS QTITENSVENDA,

         CAST(I.VLCUSTOREAL AS NUMBER (18, 6))                                                       AS CMV_A,

         CAST(I.QTPEDIDA * P.PESOBRUTO AS NUMBER (18, 6))                                            AS TOTPESOBRUTO,

         CAST (NVL(SUM(I.QTPEDIDA), 0) - (SELECT NVL(SUM(IT.QTPEDIDA), 0)

                                          FROM   ITEMPED IT,

                                                 CABPED C1

                                          WHERE  IT.NUMPED = C1.NUMPED

                                                 AND IT.CODPROD = I.CODPROD

                                                 AND IT.CODBARRA = I.CODBARRA

                                                 AND IT.SEQ = I.SEQ

                                                 AND C1.NUMPEDORIGREMENTFUT = I.NUMPED

                                                 AND C1.TIPO IN ( '24', '34', '36' )) AS NUMBER(17)) AS qtnaoatend,

         CAST (I.QTPEDIDA * I.PVENDA AS NUMBER(18, 6))                                               AS VRVENDA,

         CAST('' AS NUMBER(18, 6))                                                                   AS VROPERACAO,

         I.NUMPED                                                                                    AS IDMOV,

         CAST(CASE

                WHEN C.VLTOTAL = 0 THEN C.VLTOTCONT

                ELSE

                  CASE

                    WHEN C.VLTOTCONT = 0 THEN C.VLTOTAL

                    ELSE C.VLTOTAL

                  END

              END AS NUMBER(18, 6))                                                                  AS TOTMOV,

         CAST('' AS NUMBER (4))                                                                      AS IDTRANSPORTADOR,

         CAST('' AS VARCHAR2 (60))                                                                   AS TRANSPORTADOR,

         CAST('' AS VARCHAR2(10))                                                                    AS TRANSPORTADORPLACA,

         CAST(CL.CIDADEENT AS VARCHAR2(33))                                                          AS TRANSPORTADORCIDADE,

         CAST('' AS VARCHAR2(20))                                                                    AS NUMEROFRETE,

         CAST(C.TOTPESO AS NUMBER(9))                                                                AS PESOBRUTO,

         CAST(C.TOTPESOLIQ AS NUMBER(9))                                                             AS PESOLIQUIDO,

         C.DTPREVENT                                                                                 AS DATAENTRADASAIDA,

         REPLACE (C.OBS, ';', ',')                                                                   AS OBSERVACOES,

         I.CODAMBIENTE                                                                               AS id_ambiente,

         A.AMBIENTE                                                                                  AS desc_ambiente,

         CS.CODSERVICO                                                                               AS ID_SERVICO,

         CS.DESCRICAO                                                                                AS DESC_SERVICO,

         'A'

         || LPAD(C.CODPARIND, 6, '0')                                                                AS ID_ARQUITETO,

         PC.NOME                                                                                     AS ARQUITETO,

         SYSDATE                                                                                     AS DATA_INTEGRACAO,

         DECODE(C.POSICAO, 'O' , C.CLIENTE, '')                                                      AS CLIENTE_ORCAMENTO

  FROM   ITEMPED I,

         CABPED C,

         AMBIENTE A,

         PRODUTO P,

         FILIAL FL,

         DEPTO D,

         VENDEDOR V,

         FORNECEDOR F,

         PRODFORNEC PF,

         PRACA PR,

         CLIENTE CL,

         PARCINDICA PC,

         CADSERVICO CS,

         ramoativ ra

  WHERE  I.NUMPED = C.NUMPED

         AND C.POSICAO NOT IN ( 'C' )

         AND I.CODAMBIENTE = A.CODAMBIENTE(+)

         AND C.CODFILIAL = FL.CODFILIAL

         AND I.CODPROD = P.CODPROD

         AND P.CODEPTO = D.CODEPTO(+)

         AND C.CODVEND = V.CODVEND

         AND P.CODPROD = PF.CODPROD(+)

         AND P.CODFORNECPRINC = PF.CODFORNEC(+)

         AND P.CODFORNECPRINC = F.CODFORNEC(+)

         AND C.CODPRACA = PR.CODPRACA

         AND C.CODCLI = CL.CODCLI

         AND C.CODPARIND = PC.CODIGO(+)

         AND C.NUMPED NOT IN (SELECT CX.NUMPED

                              FROM   CABPEDAUX CX)

         AND I.CODSERVICO = CS.CODSERVICO(+)

         AND CL.CODATIV = RA.CODATIV(+)

  GROUP  BY C.DTEMISSAO,

            C.CODFILIAL,

            FL.FILIAL,

            D.CODEPTO,

            D.DEPARTAMENTO,

            I.CODPROD,

            C.POSICAO,

            C.TIPO,

            C.CODVEND,

            V.NOME,

            PF.CODPRODFOR,

            P.CODFORNECPRINC,

            I.NUMPED,

            I.CODBARRA,

            I.SEQ,

            F.FORNECEDOR,

            PR.DESCRICAO,

            CL.BAIRRO,

            CL.CIDADE,

            CL.CODPRACA,

            CL.CLIENTE,

            CL.CODCLI,

            CL.TIPOFJ,

            C.CODPLPAG,

            P.CODPROD,

            P.DESCRICAO,

            P.TIPOPROD,

            C.PERDESC,

            P.EMBALAGEM,

            I.QTPEDIDA,

            I.VLCUSTOREAL,

            P.PESOBRUTO,

            I.PVENDA,

            C.VLTOTAL,

            C.VLTOTCONT,

            CL.CIDADEENT,

            C.TOTPESO,

            C.TOTPESOLIQ,

            C.DTPREVENT,

            C.OBS,

            I.CODAMBIENTE,

            A.AMBIENTE,

            C.CODPARIND,

            PC.NOME,

            CS.CODSERVICO,

            CS.DESCRICAO,

            RA.RAMO,

            C.CLIENTE

   UNION ALL

  SELECT CAST(TO_CHAR(C.DTEMISSAO, 'YYYY') AS NUMBER(4, 0))                                           AS ANOVENDA,

          CAST(TO_CHAR(C.DTEMISSAO, 'MM') AS NUMBER(4, 0))                                             AS MESVENDA,

          CAST (TO_CHAR(C.DTEMISSAO, 'WW') AS NUMBER(4, 0))                                            AS SEMANA,

          CAST(TO_CHAR(C.DTEMISSAO, 'DD') AS NUMBER(4, 0))                                             AS DIA,

          C.DTEMISSAO                                                                                  AS DATAMOVIMENTO,

          CAST(C.CODFILIAL AS NUMBER)                                                                  AS CODFILIAL,

          SUBSTR(FL.FILIAL, 1, 30)                                                                     AS FILIAL,

          CAST(D.CODEPTO AS VARCHAR2(4))                                                               AS CODLOCAL,

          CAST(D.DEPARTAMENTO AS VARCHAR2(60))                                                         AS LOCAL,

          CAST(CASE

                 WHEN C.POSICAO = 'O' THEN 'ORCAMENTO'

                 WHEN C.POSICAO = 'F'

                      AND C.TIPO = '36' THEN 'VENDA PEDIDO'

                 WHEN C.POSICAO = 'F'

                      AND C.TIPO = '35' THEN 'VENDA CONTRATO'

                 ELSE 'OUTROS'

               END AS VARCHAR2(20))                                                                    AS TIPOMOVIMENTO,

          CAST(C.CODVEND AS VARCHAR2(12))                                                              AS IDVENDEDOR,

          CAST(V.NOME AS VARCHAR2(60))                                                                 AS vendedor,

          CAST('' AS NUMBER (4, 0))                                                                    AS HORA_OPER,

          CAST(P.CODFORNECPRINC AS VARCHAR2(20))                                                           AS IDFABRICANTE,

          SUBSTR(F.FORNECEDOR, 1, 50)                                                                  AS FABRICANTE,

          CAST(D.CODEPTO AS NUMBER (4, 0))                                                             AS IDGRUPO,

          CAST(D.DEPARTAMENTO AS VARCHAR2(50))                                                         AS GRUPO,

          CAST('Venda de produção do estabelecimento' AS VARCHAR2(60))                                 AS NATITEM,

          CAST(CL.BAIRRO AS VARCHAR2(20))                                                              AS BAIRRO,

          CAST(CL.CIDADE AS VARCHAR2(35))                                                              AS CIDADE,

          CAST(PR.DESCRICAO AS VARCHAR2(60))                                                           AS NOMEREGIAO,

          RA.RAMO                           AS CATEGORIA,

          CL.CLIENTE                                                                                   AS NOMECLIFOR,

          'C'

          || LPAD(CL.CODCLI, 6, '0')                                                                   AS CODCLIFOR,

          CAST(CASE

                 WHEN CL.TIPOFJ = 'F' THEN 'Física'

                 ELSE 'Jurídica'

               END AS VARCHAR2(8))                                                                     AS TIPOPESSOA,

          CAST(CASE

                 WHEN C.CODPLPAG = 1 THEN 'VENDA A VISTA'

                 ELSE 'VENDA A PRAZO'

               END AS VARCHAR2(50))                                                                    AS CONDPAG,

          CAST('' AS VARCHAR2(40))                                                                     AS PONTOVENDA,

          CAST(P.CODPROD AS VARCHAR2(20))                                                              AS codproduto,

          CAST(P.DESCRICAO AS VARCHAR2(150))                                                           AS PRODUTO,

          CAST(PF.CODPRODFOR AS VARCHAR2(20))                                                          AS CODPRODUTOFABR,

          CAST('PREÇO NORMAL' AS VARCHAR2(20))                                                         AS IDPRECOTABELA,

          CAST(CASE

                 WHEN P.TIPOPROD = 'MR'

                       OR P.TIPOPROD IS NULL THEN 'MERCADORIA PARA REVENDA'

                 WHEN P.TIPOPROD = 'SE' THEN 'SERVIÇOS'

                 WHEN P.TIPOPROD = 'PA' THEN 'PRODUTO ACABADO'

                 WHEN P.TIPOPROD = 'UC' THEN 'USO E CONSUMO'

                 WHEN P.TIPOPROD = 'MP' THEN 'MATÉRIA PRIMA'

                 WHEN P.TIPOPROD = 'SP' THEN 'SUB-PRODUTO'

                 WHEN P.TIPOPROD = 'AI' THEN 'ATIVO IMOBILIZADO'

                 WHEN P.TIPOPROD = 'OT' THEN 'OUTROS'

                 WHEN P.TIPOPROD = 'OI' THEN 'OUTROS INSUMOS'

                 WHEN P.TIPOPROD = 'EP' THEN 'PRODUTO EM PROCESSO'

                 WHEN P.TIPOPROD = 'EM' THEN 'EMBALAGENS'

                 WHEN P.TIPOPROD = 'PI' THEN 'PRODUTO INTERMEDIARIO'

                 ELSE 'A DEFINIR'

               END AS VARCHAR2(30))                                                                    AS STATUSPROD,

          CAST(C.PERDESC AS FLOAT(25))                                                                 AS PERCDESCONTO,

          CAST('' AS VARCHAR2(20))                                                                     AS DSCSTATUSMOV,

          CAST('' AS VARCHAR2(4))                                                                      AS IDEXPEDICAO,

          CAST(P.EMBALAGEM AS VARCHAR2(12))                                                            AS UNIDITEMMOV,

          CAST(I.QTORIG AS NUMBER (18, 6))                                                             AS QTITENSVENDA,

          CAST(I.VLCUSTOREAL AS NUMBER (18, 6))                                                        AS CMV_A,

          CAST(I.QTORIG * P.PESOBRUTO AS NUMBER (18, 6))                                               AS TOTPESOBRUTO,

          CAST (NVL(SUM(I.QTORIG), 0) - (SELECT NVL(SUM(IT.QTPEDIDA), 0)

                                         FROM   ITEMPED IT,

                                                CABPED C1

                                         WHERE  IT.NUMPED = C1.NUMPED

                                                AND IT.CODPROD = I.CODPROD

                                                AND IT.CODBARRA = I.CODBARRA

                                                AND IT.SEQ = I.SEQ

                                                AND C1.NUMPEDORIGREMENTFUT = I.NUMPED

                                                AND C1.TIPO IN ( '24', '34', '36' )) AS NUMBER(18, 6)) AS qtnaoatend,

          CAST (I.QTORIG * I.PVENDA AS NUMBER(18, 6))                                                  AS VRVENDA,

          CAST('' AS NUMBER(18, 6))                                                                    AS VROPERACAO,

          I.NUMPED                                                                                     AS IDMOV,

          CAST(CASE

                 WHEN C.VLTOTAL = 0 THEN C.VLTOTCONT

                 ELSE

                   CASE

                     WHEN C.VLTOTCONT = 0 THEN C.VLTOTAL

                     ELSE C.VLTOTAL

                   END

               END AS NUMBER(18, 6))                                                                   AS TOTMOV,

          CAST('' AS NUMBER (4))                                                                       AS IDTRANSPORTADOR,

          CAST('' AS VARCHAR2 (60))                                                                    AS TRANSPORTADOR,

          CAST('' AS VARCHAR2(10))                                                                     AS TRANSPORTADORPLACA,

          CAST(CL.CIDADEENT AS VARCHAR2(33))                                                           AS TRANSPORTADORCIDADE,

          CAST('' AS VARCHAR2(20))                                                                     AS NUMEROFRETE,

          CAST(C.TOTPESO AS NUMBER(9, 2))                                                              AS PESOBRUTO,

          CAST(C.TOTPESOLIQ AS NUMBER(9, 2))                                                           AS PESOLIQUIDO,

          C.DTPREVENT                                                                                  AS DATAENTRADASAIDA,

          REPLACE (C.OBS, ';', ',')                                                                    AS OBSERVACOES,

          I.CODAMBIENTE                                                                                AS id_ambiente,

          A.AMBIENTE                                                                                   AS desc_ambiente,

          CS.CODSERVICO                                                                                AS ID_SERVICO,

          CS.DESCRICAO                                                                                 AS DESC_SERVICO,

          'A'

          || LPAD(C.CODPARIND, 6, '0')                                                                 AS ID_ARQUITETO,

          PC.NOME                                                                                      AS ARQUITETO,

          SYSDATE                                                                                      AS DATA_INTEGRACAO,

          DECODE(C.POSICAO, 'O' , C.CLIENTE, '')                                                       AS CLIENTE_ORCAMENTO

   FROM   CABPEDAUX C,

          ITEMPEDAUX I,

          CLIENTE CL,

          AMBIENTE A,

          FILIAL FL,

          VENDEDOR V,

          PRODUTO P,

          DEPTO D,

          PRODFORNEC PF,

          FORNECEDOR F,

          PRACA PR,

          PARCINDICA PC,

          CADSERVICO CS,

          RAMOATIV RA

   WHERE  C.NUMPED = I.NUMPED

          AND C.CODCLI = CL.CODCLI

          AND C.CODPRACA = PR.CODPRACA

          AND C.CODFILIAL = FL.CODFILIAL

          AND I.CODPROD = P.CODPROD

          AND C.CODVEND = V.CODVEND

          AND C.POSICAO NOT IN ( 'C' )

          AND I.CODAMBIENTE = A.CODAMBIENTE(+)

          AND P.CODEPTO = D.CODEPTO(+)

          AND P.CODPROD = PF.CODPROD(+)

          AND P.CODFORNECPRINC = PF.CODFORNEC(+)

          AND P.CODFORNECPRINC = F.CODFORNEC(+)

          AND C.CODPARIND = PC.CODIGO(+)

          AND I.CODSERVICO = CS.CODSERVICO(+)

          AND CL.CODATIV = RA.CODATIV(+)

   GROUP  BY C.DTEMISSAO,

             C.CODFILIAL,

             FL.FILIAL,

             D.CODEPTO,

             D.DEPARTAMENTO,

             I.CODPROD,

             C.POSICAO,

             C.TIPO,

             C.CODVEND,

             V.NOME,

             PF.CODPRODFOR,

             P.CODFORNECPRINC,

             I.NUMPED,

             I.CODBARRA,

             I.SEQ,

             F.FORNECEDOR,

             PR.DESCRICAO,

             CL.BAIRRO,

             CL.CIDADE,

             CL.CODPRACA,

             CL.CLIENTE,

             CL.CODCLI,

             CL.TIPOFJ,

             C.CODPLPAG,

             P.CODPROD,

             P.DESCRICAO,

             P.TIPOPROD,

             C.PERDESC,

             P.EMBALAGEM,

             I.QTORIG,

             I.VLCUSTOREAL,

             P.PESOBRUTO,

             I.PVENDA,

             C.VLTOTAL,

             C.VLTOTCONT,

             CL.CIDADEENT,

             C.TOTPESO,

             C.TOTPESOLIQ,

             C.DTPREVENT,

             C.OBS,

             I.CODAMBIENTE,

             A.AMBIENTE,

             C.CODPARIND,

             PC.NOME,

             CS.CODSERVICO,

             CS.DESCRICAO,

             RA.RAMO,

             C.CLIENTE)
/


-- End of DDL Script for View MARMORE.BI_VENDA_FLYGESTOR

