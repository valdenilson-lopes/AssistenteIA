-- Start of DDL Script for View MARMORE.BI_CLIFOR_FLYGESTOR
-- Generated 19-set-2024 10:34:08 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW bi_clifor_flygestor (
   idclifor,
   idempresa,
   nomeclifor,
   razaosocial,
   tipoclifor,
   tipopessoa,
   cpfcnpj,
   rgieclifor,
   tipologradouro,
   logradouro,
   numerologradouro,
   bairro,
   complemento,
   pontoreferencia,
   email,
   cep,
   idcidade,
   cidade,
   uf,
   idregiao,
   regiao,
   telefone1,
   telefone2,
   estadocivil,
   datanascimento,
   sexo,
   naturalidade,
   nacionalidade,
   observacao,
   listanegra,
   datacriacao,
   inativo,
   codfunc,
   idcategoriaclifor,
   categoria )
AS
SELECT idclifor,

       idempresa,

       nomeclifor,

       razaosocial,

       tipoclifor,

       tipopessoa,

       CPFCNPJ,

       rgieclifor,

       tipologradouro,

       replace(logradouro,';',',') as logradouro,

       REPLACE(numerologradouro,';',',') as numerologradouro,

       bairro,

       replace(complemento,';',',') as complemento,

       replace(pontoreferencia,';',',') as pontoreferencia,

       replace(email,';',',') as email,

       cep,

       idcidade,

       cidade,

       uf,

       idregiao,

       regiao,

       telefone1,

       telefone2,

       estadocivil,

       datanascimento,

       sexo,

       naturalidade,

       nacionalidade,

       observacao,

       listanegra,

       datacriacao,

       inativo,

       codfunc,

       IDCATEGORIACLIFOR,

       categoria

FROM (

SELECT Decode (P.tipoparc, 'C', 'C'

                                || LPAD(P.codparc,6,'0'),

                           'F'

                           || LPAD(P.codparc,6,'0')) AS IDCLIFOR,

         CAST(1 AS VARCHAR2(4))                             AS IDEMPRESA,

         CAST(DECODE(P.fantasia, '', NOME, FANTASIA) AS VARCHAR2(70))                      AS nomeclifor,

         CAST(P.nome AS VARCHAR2(70))                          AS RAZAOSOCIAL,

         CAST(P.tipoparc AS VARCHAR2(1))                      AS TIPOCLIFOR,

         P.tipofj                        AS TIPOPESSOA,

         CAST(P.cpfcnpj AS VARCHAR2(19)) AS cpfcnpj,

         CAST(Decode(P.tipoparc, 'C', ie2,

                          P.ie)  AS VARCHAR2(20))         AS RGIECLIFOR,

         CAST(CASE

           WHEN Substr(P.endereco, 0, 3) LIKE 'RU%' THEN 'RUA'



               WHEN Substr(P.endereco, 0, 3) LIKE 'AV%' THEN 'AV.'



                   WHEN Substr(P.endereco, 0, 3) LIKE 'RO%' THEN 'ROD'

                   ELSE 'TRAV.'

                 END

         AS VARCHAR2(5))                            AS TIPOLOGRADOURO,

         CAST(REPLACE(P.endereco, ';',',') AS VARCHAR2(50))                      AS LOGRADOURO,

         CAST(CASE

           WHEN Length(Substr(( P.endereco ), Instr(P.endereco, ' ', -1, 1 ) + 1,

                       Length(

                       P.endereco)))

                < 8 THEN Substr(( P.endereco ), Instr(P.endereco, ' ', -1, 1 ) + 1,

                         Length(

                         P.endereco))

           ELSE 'S/N'

         END AS VARCHAR2(8))                          AS NUMEROLOGRADOURO,

         CAST(P.bairro AS VARCHAR2(20)) AS BAIRRO,

         CAST(REPLACE(P.complemento,';',',' )AS VARCHAR2(20)) AS COMPLEMENTO,

         CAST('' AS VARCHAR2(50))      AS PONTOREFERENCIA,

         CAST(P.email AS VARCHAR2(150)) AS EMAIL,

         CAST(P.cep AS VARCHAR2(9)) AS CEP,

         CAST(P.codmunicipio AS NUMBER (10))                  AS IDCIDADE,

         CAST(P.cidade AS VARCHAR2(30))  AS CIDADE,

         CAST(P.estado AS VARCHAR(2))     AS UF,

         CAST(P.codpraca AS NUMBER(4))           AS IDREGIAO,

         CAST(praca.descricao AS VARCHAR2(50))               AS REGIAO,

         CAST(P.telefone AS VARCHAR2(15))                     AS TELEFONE1,

         CAST(P.telefoneent AS VARCHAR2(15))                  AS TELEFONE2,

         CAST(CASE

           WHEN P.estcivil = 'S' THEN 'SOLTEIRO'



               WHEN P.estcivil = 'C' THEN 'CASADO'



                   WHEN P.estcivil = 'V' THEN 'VIUVO'



                       WHEN P.estcivil = 'S' THEN 'SEPARADO'

                       ELSE 'SOLTEIRO'

                     END

         AS VARCHAR2(10))                                  AS ESTADOCIVIL,

         CAST('' AS DATE)                        AS DATANASCIMENTO,

         CAST('' AS VARCHAR2(1))                           AS SEXO,

         CAST('' AS VARCHAR2(30))                           AS NATURALIDADE,

         CAST('' AS VARCHAR2(30)) AS NACIONALIDADE,

         CAST(P.obs1 AS VARCHAR2(4000))                         AS OBSERVACAO,

         CAST('' AS VARCHAR2(1))                      AS LISTANEGRA,

         P.dtcadastro                   AS DATACRIACAO,

         CAST(CASE

           WHEN P.dtexclusao IS NULL THEN 'N'

           ELSE 'S'

         END AS VARCHAR2(1))                           AS INATIVO,

         CAST(P.codfunccad AS NUMBER(5))                   AS CODFUNC,

         P.CODATIV                 AS IDCATEGORIACLIFOR,

         RAMOATIV.RAMO  AS CATEGORIA

  FROM   parceiros P

         inner join praca

                 ON P.codpraca = praca.codpraca

         left join ramoativ

                ON P.tipoparc = ramoativ.tipo

                   AND P.codativ = ramoativ.codativ

UNION ALL

SELECT 'A' || LPAD(P.CODIGO,6,'0') AS IDCLIFOR,

         CAST(1 AS VARCHAR2(4))                             AS IDEMPRESA,

         CAST(DECODE(P.NOME, '', P.NOME, P.NOME) AS VARCHAR2(70))                      AS nomeclifor,

         CAST(P.nome AS VARCHAR2(70))                          AS RAZAOSOCIAL,

         CAST('A' AS VARCHAR2(1))                      AS TIPOCLIFOR,

         CASE WHEN LENGTH(REPLACE(P.CPFCNPJ, '.' ,'') ) >= 14 THEN 'J' ELSE 'F' END          AS TIPOPESSOA,

         CAST(P.cpfcnpj AS VARCHAR2(19)) AS cpfcnpj,

         ''         AS RGIECLIFOR,

         CAST(CASE

           WHEN Substr(P.endereco, 0, 3) LIKE 'RU%' THEN 'RUA'



               WHEN Substr(P.endereco, 0, 3) LIKE 'AV%' THEN 'AV.'



                   WHEN Substr(P.endereco, 0, 3) LIKE 'RO%' THEN 'ROD'

                   ELSE 'TRAV.'

                 END

         AS VARCHAR2(5))                            AS TIPOLOGRADOURO,

         CAST(REPLACE(P.endereco, ';',',') AS VARCHAR2(50))                      AS LOGRADOURO,

         CAST(CASE

           WHEN Length(Substr(( P.endereco ), Instr(P.endereco, ' ', -1, 1 ) + 1,

                       Length(

                       P.endereco)))

                < 8 THEN Substr(( P.endereco ), Instr(P.endereco, ' ', -1, 1 ) + 1,

                         Length(

                         P.endereco))

           ELSE 'S/N'

         END AS VARCHAR2(8))                          AS NUMEROLOGRADOURO,

         CAST(P.bairro AS VARCHAR2(20)) AS BAIRRO,

         NULL AS COMPLEMENTO,

         CAST('' AS VARCHAR2(50))      AS PONTOREFERENCIA,

         CAST(P.email AS VARCHAR2(150)) AS EMAIL,

         CAST(P.cep AS VARCHAR2(9)) AS CEP,

         NULL                  AS IDCIDADE,

         CAST(P.cidade AS VARCHAR2(30))  AS CIDADE,

         CAST(P.estado AS VARCHAR(2))     AS UF,

         DECODE ( NVL(P.ESTADO,'RN'), 'RN', 100, 200)           AS IDREGIAO,

         DECODE ( NVL(P.ESTADO,'RN'), 'RN', 'DENTRO DO ESTADO', 'FORA DO ESTADO')               AS REGIAO,

         CAST(P.telefone AS VARCHAR2(15))                     AS TELEFONE1,

         CAST(P.telefone AS VARCHAR2(15))                  AS TELEFONE2,

         'NADA CONSTA'                                  AS ESTADOCIVIL,

         CAST('' AS DATE)                        AS DATANASCIMENTO,

         CAST('' AS VARCHAR2(1))                           AS SEXO,

         CAST('' AS VARCHAR2(30))                           AS NATURALIDADE,

         CAST('' AS VARCHAR2(30)) AS NACIONALIDADE,

         CAST(P.obs1 AS VARCHAR2(4000))                         AS OBSERVACAO,

         CAST('' AS VARCHAR2(1))                      AS LISTANEGRA,

         P.dtcadastro                   AS DATACRIACAO,

         CAST(CASE

           WHEN P.DTTERMINO IS NULL THEN 'N'

           ELSE 'S'

         END AS VARCHAR2(1))                           AS INATIVO,

         NULL                   AS CODFUNC,

         NULL                AS IDCATEGORIACLIFOR,

         'ARQUITETO'             AS CATEGORIA

  FROM   parcindica P)
/


-- End of DDL Script for View MARMORE.BI_CLIFOR_FLYGESTOR

