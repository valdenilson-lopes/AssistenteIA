-- Start of DDL Script for View MARMORE.BI_FINANCEIRO_FLYGESTOR
-- Generated 19-set-2024 10:35:55 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_financeiro_flygestor (
   anovencimento,
   mesvencimento,
   diavencimento,
   diabx,
   anobx,
   mesbx,
   datavencimento,
   databaixa,
   mescomp,
   situacaocpr,
   tipocpr,
   codclifor,
   nomecf,
   razaosocial,
   cidade,
   codfilial,
   filial,
   mes_anocadcli,
   diaemi,
   mes_anoemi,
   dataemissao,
   tipodoc,
   numdoc,
   numboleto,
   portador,
   planoconta,
   regiao,
   categoriaclifor,
   tipocontabil,
   meiopag,
   condpag,
   codvendedor,
   funcionario,
   totnominal,
   totprevisto,
   totrealizado,
   historico,
   observacoes,
   tipopessoa,
   cpfcgcclifor,
   email,
   telefone,
   idmov,
   idcpr,
   data_integracao )
AS
SELECT anovencimento,

       mesvencimento,

       diavencimento,

       diabx,

       anobx,

       mesbx,

       datavencimento,

       databaixa,

       mescomp,

       situacaocpr,

       tipocpr,

       codclifor,

       nomecf,

       replace(razaosocial,';',',') as razaosocial,

       cidade,

       cast (codfilial as number ) as codfilial,

       filial,

       mes_anocadcli,

       diaemi,

       mes_anoemi,

       dataemissao,

       tipodoc,

       numdoc,

       numboleto,

       portador,

      replace(planoconta, ';',',') as planoconta,

       regiao,

       categoriaclifor,

       tipocontabil,

       meiopag,

       condpag,

       codvendedor,

       funcionario,

       totnominal,

       totprevisto,

       totrealizado,

       replace(historico,';',',') as historico,

       replace(observacoes,';',',') as observacoes,

       tipopessoa,

       cpfcgcclifor,

       replace(email,';',',') as email,

       telefone,

       idmov,

       idcpr,

       data_integracao

FROM (SELECT CAST(To_char (CP.dtvenc, 'YYYY')  AS NUMBER(4,0)) AS ANOVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CP.DTPAGO, 'DD')                            AS DIABX,

       To_char (CP.DTPAGO, 'YYYY')                            AS ANOBX,

       To_char (CP.DTPAGO, 'MM')                           AS MESBX,

       CP.dtvenc                     AS DATAVENCIMENTO,

       CP.dtpago                     AS DATABAIXA,

       CAST(To_char(CP.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CP.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('pagar' AS VARCHAR2(7))                     AS TIPOCPR,

       CASE

         WHEN CP.tipoparceiro = 'F'

               OR CP.tipoparceiro IS NULL THEN 'F'

                                               || Lpad(F.codfornec, 6, '0')

         ELSE ''

       END                           AS CODCLIFOR,

       CAST(CASE

         WHEN CP.tipoparceiro = 'F'

               OR CP.tipoparceiro IS NULL THEN F.fornecedor

         ELSE ''

       END  AS VARCHAR2(70))                         AS NOMECF,

       CAST(CASE

         WHEN CP.tipoparceiro = 'F'

               OR CP.tipoparceiro IS NULL THEN F.fornecedor

         ELSE ''

       END  AS VARCHAR2(70))                          AS RAZAOSOCIAL,

       CAST(CASE

         WHEN CP.tipoparceiro = 'F'

               OR CP.tipoparceiro IS NULL THEN F.cidade

         ELSE ''

       END  AS VARCHAR2(33))                         AS CIDADE,

       CAST(CP.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

       cast(To_char (CP.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CP.DTLANC, 'MM/YYYY')   AS MES_ANOEMI,

       CP.DTLANC AS DATAEMISSAO,

       CAST( CASE WHEN NE.TIPOENTRADA = 'EN' THEN 'ENTRADA NORMAL' WHEN NE.TIPOENTRADA = 'EC' THEN 'ENTRADA DE USO E CONSUMO' ELSE 'ENTRADA NORMAL' END AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CP.NUMNOTA AS VARCHAR2(20))                  AS NUMDOC,

       '' AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       CAST(PR.DESCRICAO AS VARCHAR2(50)) AS REGIAO,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'F' OR CP.TIPOPARCEIRO IS NULL THEN 'FORNECEDOR' ELSE '' END AS VARCHAR2(30)) AS CATEGORIACLIFOR,

       CASE WHEN CP.STATUS = 'A' OR CP.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST('A PRAZO' AS VARCHAR2(50)) AS CONDPAG,

       CAST( 0 AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST('' AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST((CASE WHEN CP.TIPOPARCEIRO IS NULL THEN NE.VLTOTAL ELSE CP.VALOR END)AS NUMBER) AS TOTNOMINAL,

       CAST(CP.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST(CP.vpago AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CP.HISTORICO AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CP.HISTORICO2 AS VARCHAR2(4000)) AS OBSERVACOES,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'F' OR CP.TIPOPARCEIRO IS NULL THEN CASE WHEN F.TIPOFJ = 'F' THEN 'Física'ELSE 'Jurídica' END ELSE '' END AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'F' OR CP.TIPOPARCEIRO IS NULL THEN F.CPFCNPJ ELSE '' END AS VARCHAR2(19)) AS CPFCGCCLIFOR,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'F' OR CP.TIPOPARCEIRO IS NULL THEN F.EMAIL ELSE '' END AS VARCHAR2(150)) AS EMAIL,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'F' OR CP.TIPOPARCEIRO IS NULL THEN F.TELEFONE ELSE '' END AS VARCHAR2(20)) AS TELEFONE,

       CAST(CP.NUMLANC AS NUMBER(10))AS IDMOV,

       CONCAT(CP.NUMLANC, CP.PREST) AS IDCPR,

       CP.DTLANC AS DATA_INTEGRACAO

FROM   cpagar CP

       INNER JOIN fornecedor f

               ON cp.codfornec = f.codfornec

       INNER JOIN FILIAL FL ON

       CP.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CP.CODCONTA = CT.CODCONTA

       LEFT JOIN COBRANCA CB ON

       CP.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CP.CODFUNC = E.CODFUNC

       LEFT JOIN NFENT NE ON

       CP.NUMENT = NE.NUMENT

       RIGHT JOIN PRACA PR ON

       NVL(F.CODPRACA,100) = PR.CODPRACA

       WHERE CP.CODCOB<> 'DESD'

       AND NVL(CP.TIPOPARCEIRO,'F') = 'F'



UNION ALL

SELECT  CAST(To_char (CP.dtvenc, 'YYYY')  AS NUMBER(4,0)) AS ANOVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CP.dtpago, 'DD')                            AS DIABX,

       To_char (CP.dtpago, 'YYYY')                             AS ANOBX,

       To_char (CP.dtpago, 'MM')                           AS MESBX,

       CP.dtvenc                     AS DATAVENCIMENTO,

       CP.dtpago                     AS DATABAIXA,

       CAST(To_char(CP.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CP.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('pagar'  AS VARCHAR2(7))                   AS TIPOCPR,

       CASE

         WHEN CP.tipoparceiro = 'C' THEN



                                               'C'|| Lpad(CL.CODCLI, 6, '0')

         ELSE ''

       END                           AS CODCLIFOR,

      CAST( CASE

         WHEN CP.tipoparceiro = 'C'

                THEN CL.CLIENTE

         ELSE ''

       END AS VARCHAR2(70))                           AS NOMECF,

      CAST( CASE

         WHEN CP.tipoparceiro = 'C'

               THEN CL.CLIENTE

         ELSE ''

       END AS VARCHAR2(70))                          AS RAZAOSOCIAL,

       CAST(CASE

         WHEN CP.tipoparceiro = 'C'

                THEN CL.cidade

         ELSE ''

       END AS VARCHAR2(33))                           AS CIDADE,

       CAST(CP.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

        cast(To_char (CP.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CP.DTLANC, 'MM/YYYY')   AS MES_ANOEMI,

       CP.DTLANC AS DATAEMISSAO,

       CAST('' AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CP.NUMNOTA AS VARCHAR2(20))                     AS NUMDOC,

       '' AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       CAST(PR.DESCRICAO AS VARCHAR2(50)) AS REGIAO,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'C' THEN 'CLIENTE' ELSE '' END AS VARCHAR2(30))AS CATEGORIACLIFOR,

       CASE WHEN CP.STATUS = 'A' OR CP.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST('A PRAZO' AS VARCHAR2(50)) AS CONDPAG,

       CAST( 0 AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST('' AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST(CP.VALOR AS NUMBER(11,2)) AS TOTNOMINAL,

       CAST(CP.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST(CP.vpago AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CP.HISTORICO AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CP.HISTORICO2 AS VARCHAR2(4000)) AS OBSERVACOES,

       CAST('Física' AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'C' THEN CL.CPFCNPJ ELSE '' END AS VARCHAR2(19)) AS CPFCGCCLIFOR,

        CAST('' AS VARCHAR2(150))  AS EMAIL,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'C' THEN CL.TELEFONE ELSE '' END AS VARCHAR2(20)) AS  TELEFONE,

       CAST(CP.NUMLANC AS NUMBER(10)) AS IDMOV,

       CONCAT(CP.NUMLANC, CP.PREST) AS IDCPR,

       CP.DTLANC AS DATA_INTEGRACAO

FROM   cpagar CP

       INNER JOIN CLIENTE CL

               ON cp.codfornec = CL.CODCLI

       INNER JOIN FILIAL FL ON

       CP.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CP.CODCONTA = CT.CODCONTA

       LEFT JOIN COBRANCA CB ON

       CP.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CP.CODFUNC = E.CODFUNC

       LEFT JOIN PRACA PR ON

       CL.CODPRACA = PR.CODPRACA

       WHERE NVL(CP.CODCOB, 'BK') <> 'DESD'

       AND NVL(CP.TIPOPARCEIRO,'F') = 'C'



UNION ALL

SELECT  CAST(To_char (CR.dtvenc, 'YYYY')  AS NUMBER(4,0)) AS ANOVENCIMENTO,

       CAST(To_char (CR.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CR.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CR.DTPAGO, 'DD')                            AS DIABX,

       To_char (CR.DTPAGO, 'YYYY')                             AS ANOBX,

       To_char (CR.DTPAGO, 'MM')                           AS MESBX,

       CR.dtvenc                     AS DATAVENCIMENTO,

       CR.dtpago                     AS DATABAIXA,

       CAST(To_char(CR.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CR.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('receber' AS VARCHAR2(7))                    AS TIPOCPR,

       'C'|| Lpad(CL.CODCLI, 6, '0') AS CODCLIFOR,

       CAST(CL.CLIENTE AS VARCHAR2(70))AS NOMECF,

       CAST(CL.CLIENTE AS VARCHAR2(70)) AS RAZAOSOCIAL,

       CAST(CL.cidade AS VARCHAR2(33)) AS CIDADE,

       CAST(CR.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

        cast(To_char (Cr.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CR.DTEMISSAO, 'MM/YYYY')   AS MES_ANOEMI,

       CR.DTEMISSAO AS DATAEMISSAO,

       CAST(CASE WHEN NF.TIPOVENDA ='VV' THEN 'VENDA A VISTA' WHEN NF.TIPOVENDA ='VA' THEN 'VENDA AVULSA' WHEN NF.TIPOVENDA ='VP' THEN 'VENDA A PRAZO' ELSE 'VENDA A VISTA' END AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CR.numnota AS VARCHAR2(20))                   AS NUMDOC,

       CAST(CR.NOSSONUMBCO AS VARCHAR2(20)) AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       CAST(PR.DESCRICAO AS VARCHAR2(50)) AS REGIAO,

       CAST('CLIENTE' AS VARCHAR2(30)) AS CATEGORIACLIFOR,

       CASE WHEN CR.STATUS = 'A' OR CR.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST(CASE WHEN CR.CODCOB = 'D' THEN 'A VISTA' ELSE 'A PRAZO' END AS VARCHAR2(50)) AS CONDPAG,

       CAST(CR.CODVEND AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST(V.NOME AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST(NF.VLTOTAL AS NUMBER(11,2)) AS TOTNOMINAL,

       CAST(CR.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST((NVL(CR.VPAGO,0) + NVL(CR.VPAGOPARCIAL,0)) AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CR.OBS AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CR.OBS2 AS VARCHAR2(4000))AS  OBSERVACOES,

       CAST(CASE WHEN CL.TIPOFJ ='F' THEN 'Física' Else 'Jurídica' End AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CL.CPFCNPJ AS VARCHAR2(19)) AS CPFCGCCLIFOR,

       CAST(CL.EMAIL AS VARCHAR2(150)) AS EMAIL,

       CAST(CL.TELEFONE AS VARCHAR2(20)) AS  TELEFONE,

       CAST(CR.NUMPED AS NUMBER(10)) AS IDMOV,

       CONCAT(CR.NUMVENDA, CR.PREST) AS IDCPR,

       CR.DTEMISSAO AS DATA_INTEGRACAO

FROM   CRECEBER CR

       INNER JOIN CLIENTE CL

               ON CR.CODCLI = CL.CODCLI

       INNER JOIN FILIAL FL ON

       CR.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CR.CODCONT = CT.CODCONTA

       INNER JOIN COBRANCA CB ON

       CR.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CR.CODFUNC = E.CODFUNC

       INNER JOIN NFSAID NF ON

       CR.NUMVENDA = NF.NUMVENDA

       INNER JOIN PRACA PR ON

       NF.CODPRACA = PR.CODPRACA

        LEFT JOIN VENDEDOR V ON

       CR.CODVEND = V.CODVEND

       WHERE CR.CODCOB NOT IN ('DESD')

 UNION ALL

SELECT CAST(To_char (CP.dtvenc, 'YYYY')  AS NUMBER(4,0))    AS ANOVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CP.dtpago, 'DD')                            AS DIABX,

       To_char (CP.dtpago, 'YYYY')                          AS ANOBX,

       To_char (CP.dtpago, 'MM')                           AS MESBX,

       CP.dtvenc                     AS DATAVENCIMENTO,

       CP.dtpago                     AS DATABAIXA,

       CAST(To_char(CP.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CP.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('pagar'  AS VARCHAR2(7))                   AS TIPOCPR,

       CASE

         WHEN CP.tipoparceiro = 'E' THEN



                                               'E'|| Lpad(CL.CODFUNC, 6, '0')

         ELSE ''

       END                           AS CODCLIFOR,

      CAST( CASE

         WHEN CP.tipoparceiro = 'E'

                THEN CL.NOME

         ELSE ''

       END AS VARCHAR2(70))                           AS NOMECF,

      CASE

         WHEN CP.tipoparceiro = 'E'

               THEN CL.NOME

         ELSE ''   END                                   AS RAZAOSOCIAL,

      CASE

         WHEN CP.tipoparceiro = 'E'

                THEN CL.cidade

         ELSE ''

       END                                            AS CIDADE,

       CAST(CP.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

        cast(To_char (CP.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CP.DTLANC, 'MM/YYYY')   AS MES_ANOEMI,

       CP.DTLANC AS DATAEMISSAO,

       CAST('' AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CP.NUMNOTA AS VARCHAR2(20))                     AS NUMDOC,

       '' AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       '' AS REGIAO,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'E' THEN 'EMPREGADO' ELSE '' END AS VARCHAR2(30))AS CATEGORIACLIFOR,

       CASE WHEN CP.STATUS = 'A' OR CP.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST('A PRAZO' AS VARCHAR2(50)) AS CONDPAG,

       CAST( 0 AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST('' AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST(CP.VALOR AS NUMBER(11,2)) AS TOTNOMINAL,

       CAST(CP.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST(CP.vpago AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CP.HISTORICO AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CP.HISTORICO2 AS VARCHAR2(4000)) AS OBSERVACOES,

       CAST('Física' AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'E' THEN CL.CPF ELSE '' END AS VARCHAR2(19)) AS CPFCGCCLIFOR,

        CAST('' AS VARCHAR2(150))  AS EMAIL,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'E' THEN CL.TELEFONE ELSE '' END AS VARCHAR2(20)) AS  TELEFONE,

       CAST(CP.NUMLANC AS NUMBER(10)) AS IDMOV,

       CONCAT(CP.NUMLANC, CP.PREST) AS IDCPR,

       CP.DTLANC AS DATA_INTEGRACAO

FROM   cpagar CP

       INNER JOIN EMPREGADO CL

               ON cp.codfornec = CL.CODFUNC

       INNER JOIN FILIAL FL ON

       CP.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CP.CODCONTA = CT.CODCONTA

       LEFT JOIN COBRANCA CB ON

       CP.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CP.CODFUNC = E.CODFUNC

       WHERE NVL(CP.CODCOB,'BK') <> 'DESD'

       AND NVL(CP.TIPOPARCEIRO,'F') = 'E'

UNION ALL

       SELECT CAST(To_char (CP.dtvenc, 'YYYY')  AS NUMBER(4,0))    AS ANOVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CP.dtpago, 'DD')                            AS DIABX,

       To_char (CP.dtpago, 'YYYY')                          AS ANOBX,

       To_char (CP.dtpago, 'MM')                           AS MESBX,

       CP.dtvenc                     AS DATAVENCIMENTO,

       CP.dtpago                     AS DATABAIXA,

       CAST(To_char(CP.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CP.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('pagar'  AS VARCHAR2(7))                   AS TIPOCPR,

       CASE

         WHEN CP.tipoparceiro = 'M' THEN



                                               'M'|| Lpad(CL.CODMOTORISTA, 6, '0')

         ELSE ''

       END                           AS CODCLIFOR,

      CAST( CASE

         WHEN CP.tipoparceiro = 'M'

                THEN CL.NOME

         ELSE ''

       END AS VARCHAR2(70))                           AS NOMECF,

      CASE

         WHEN CP.tipoparceiro = 'M'

               THEN CL.NOME

         ELSE ''   END                                   AS RAZAOSOCIAL,

      CASE

         WHEN CP.tipoparceiro = 'M'

                THEN CL.cidade

         ELSE ''

       END                                            AS CIDADE,

       CAST(CP.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

        cast(To_char (CP.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CP.DTLANC, 'MM/YYYY')   AS MES_ANOEMI,

       CP.DTLANC AS DATAEMISSAO,

       CAST('' AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CP.NUMNOTA AS VARCHAR2(20))                     AS NUMDOC,

       '' AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       '' AS REGIAO,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'M' THEN 'MOTORISTA' ELSE '' END AS VARCHAR2(30))AS CATEGORIACLIFOR,

       CASE WHEN CP.STATUS = 'A' OR CP.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST('A PRAZO' AS VARCHAR2(50)) AS CONDPAG,

       CAST( 0 AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST('' AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST(CP.VALOR AS NUMBER(11,2)) AS TOTNOMINAL,

       CAST(CP.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST(CP.vpago AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CP.HISTORICO AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CP.HISTORICO2 AS VARCHAR2(4000)) AS OBSERVACOES,

       CAST('Física' AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'M' THEN CL.CPF ELSE '' END AS VARCHAR2(19)) AS CPFCGCCLIFOR,

        CAST('' AS VARCHAR2(150))  AS EMAIL,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'M' THEN CL.TELEFONE ELSE '' END AS VARCHAR2(20)) AS  TELEFONE,

       CAST(CP.NUMLANC AS NUMBER(10)) AS IDMOV,

       CONCAT(CP.NUMLANC, CP.PREST) AS IDCPR,

       CP.DTLANC AS DATA_INTEGRACAO

FROM   cpagar CP

       INNER JOIN MOTORISTA CL

               ON cp.codfornec = CL.CODMOTORISTA

       INNER JOIN FILIAL FL ON

       CP.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CP.CODCONTA = CT.CODCONTA

       LEFT JOIN COBRANCA CB ON

       CP.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CP.CODFUNC = E.CODFUNC

       WHERE NVL(CP.CODCOB,'BK') <> 'DESD'

       AND NVL(CP.TIPOPARCEIRO,'F') = 'M'

UNION ALL

SELECT CAST(To_char (CP.dtvenc, 'YYYY')  AS NUMBER(4,0))    AS ANOVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'MM') AS VARCHAR2(255))     AS MESVENCIMENTO,

       CAST(To_char (CP.dtvenc, 'DD') AS VARCHAR2(255))     AS DIAVENCIMENTO,

       To_char (CP.dtpago, 'DD')                            AS DIABX,

       To_char (CP.dtpago, 'YYYY')                          AS ANOBX,

       To_char (CP.dtpago, 'MM')                           AS MESBX,

       CP.dtvenc                     AS DATAVENCIMENTO,

       CP.dtpago                     AS DATABAIXA,

       CAST(To_char(CP.dtpago, 'MM/YYYY') AS VARCHAR2(511)) AS MESCOMP,

       CASE

         WHEN CP.dtpago IS NULL THEN 'EM ABERTO'

         ELSE 'BAIXADO'

       END                           AS SITUACAOCPR,

       CAST('pagar'  AS VARCHAR2(7))                   AS TIPOCPR,

       CASE

         WHEN CP.tipoparceiro = 'R' THEN



                                               'V'|| Lpad(CL.CODVEND, 6, '0')

         ELSE ''

       END                           AS CODCLIFOR,

      CAST( CASE

         WHEN CP.tipoparceiro = 'R'

                THEN CL.NOME

         ELSE ''

       END AS VARCHAR2(70))                           AS NOMECF,

      CASE

         WHEN CP.tipoparceiro = 'R'

               THEN CL.NOME

         ELSE ''   END                                   AS RAZAOSOCIAL,

      CASE

         WHEN CP.tipoparceiro = 'R'

                THEN CL.cidade

         ELSE ''

       END                                            AS CIDADE,

       CAST(CP.CODFILIAL AS VARCHAR2(2)) AS CODFILIAL,

       CAST(FL.FILIAL AS VARCHAR2(30)) AS FILIAL,

       CAST('' AS VARCHAR2(7)) AS MES_ANOCADCLI,

        cast(To_char (CP.dtvenc, 'DD') as number(4,0))   AS DIAEMI,

       To_char (CP.DTLANC, 'MM/YYYY')   AS MES_ANOEMI,

       CP.DTLANC AS DATAEMISSAO,

       CAST('' AS VARCHAR2(40)) AS  TIPODOC,

       CAST(CP.NUMNOTA AS VARCHAR2(20))                     AS NUMDOC,

       '' AS NUMBOLETO,

       CAST(CB.DESCRICAO AS VARCHAR2(20)) AS PORTADOR,

       CAST(CT.CONTA AS VARCHAR2(60)) AS PLANOCONTA,

       '' AS REGIAO,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'R' THEN 'VENDEDOR' ELSE '' END AS VARCHAR2(30))AS CATEGORIACLIFOR,

       CASE WHEN CP.STATUS = 'A' OR CP.STATUS IS  NULL THEN 'C'  ELSE 'N'  END AS TIPOCONTABIL,

       CAST( CB.DESCRICAO AS VARCHAR2(30)) AS MEIOPAG,

       CAST('A PRAZO' AS VARCHAR2(50)) AS CONDPAG,

       CAST( 0 AS VARCHAR2(5)) AS CODVENDEDOR,

       CAST('' AS VARCHAR2(30))  AS FUNCIONARIO,

       CAST(CP.VALOR AS NUMBER(11,2)) AS TOTNOMINAL,

       CAST(CP.VALOR AS NUMBER (18,6)) AS TOTPREVISTO,

       CAST(CP.vpago AS NUMBER(18,6)) AS TOTREALIZADO,

       CAST(CP.HISTORICO AS VARCHAR2(4000)) AS HISTORICO,

       CAST(CP.HISTORICO2 AS VARCHAR2(4000)) AS OBSERVACOES,

       CAST('Física' AS VARCHAR2(8)) AS TIPOPESSOA,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'R' THEN CL.CPF ELSE '' END AS VARCHAR2(19)) AS CPFCGCCLIFOR,

        CAST('' AS VARCHAR2(150))  AS EMAIL,

       CAST(CASE WHEN CP.TIPOPARCEIRO = 'R' THEN CL.TELEFONE ELSE '' END AS VARCHAR2(20)) AS  TELEFONE,

       CAST(CP.NUMLANC AS NUMBER(10)) AS IDMOV,

       CONCAT(CP.NUMLANC, CP.PREST) AS IDCPR,

       CP.DTLANC AS DATA_INTEGRACAO

FROM   cpagar CP

       INNER JOIN VENDEDOR CL

               ON cp.codfornec = CL.CODVEND

       INNER JOIN FILIAL FL ON

       CP.CODFILIAL = FL.CODFILIAL

       INNER JOIN CONTA CT ON

       CP.CODCONTA = CT.CODCONTA

       LEFT JOIN COBRANCA CB ON

       CP.CODCOB = CB.CODCOB

       INNER JOIN EMPREGADO E ON

       CP.CODFUNC = E.CODFUNC

       WHERE NVL(CP.CODCOB,'BK') <> 'DESD'

       AND NVL(CP.TIPOPARCEIRO,'F') = 'R')
/


-- End of DDL Script for View MARMORE.BI_FINANCEIRO_FLYGESTOR

