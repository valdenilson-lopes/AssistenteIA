-- Start of DDL Script for View MARMORE.SITEMERCADO_PRODUTO
-- Generated 19-set-2024 10:37:07 from MARMORE@192.168.0.163:1521/orcl

CREATE OR REPLACE VIEW sitemercado_produto (
   id_loja,
   departamento,
   categoria,
   subcategoria,
   marca,
   unidade,
   volume,
   codigo_barra,
   nome,
   dt_cadastro,
   dt_ultima_alteracao,
   vlr_produto,
   vlr_promocao,
   qtd_estoque_atual,
   qtd_estoque_minimo,
   descricao,
   ativo,
   plu,
   vlr_compra,
   validade_proxima,
   vlr_atacado,
   qtd_atacado,
   image_url )
AS
SELECT filial.codfilial                                              AS ID_LOJA,

       depto.departamento                                            AS

       Departamento,

       secao.secao                                                   AS

       Categoria,

       categ.categoria                                               AS

       Subcategoria,

       marcas.descricao                                              AS Marca,

       embalagemregiao.unidade                                       AS Unidade,

       embalagemregiao.embalagem                                     AS Volume,

       embalagemregiao.codbarra                                      AS

       codigo_barra,

       produto.descricao                                             AS Nome,

       produto.dtcadastro                                            AS

       dt_cadastro,

       produto.dtultalter                                            AS

       dt_ultima_alteracao,

       NVL(embalagemregiao.pvenda1,0)                                       AS

       vlr_produto,

       NVL(embalagemregiao.poferta,0)                                       AS

       vlr_promocao,

       ( Nvl(estoque.qtestger, 0) - Nvl(estoque.qtreserv, 0) -

           Nvl(estoque.qtbloqueada, 0) - Nvl(estoque.qtindeniz, 0) ) AS

       qtd_estoque_atual,

       NVL(estoque.qtestmin,0)                                             AS

       qtd_estoque_minimo,

       produto.descricao

       ||'  '

       || produto.obs                                                AS

       Descricao,

       Decode(produto.dtexclusao, NULL, 'N',

                                  'S')                               AS ativo,

       produto.codprod                                               AS plu,

       NVL(estoque.custoreal,0)                                             AS

       vlr_compra,

       'N'                                                           AS

       validade_proxima,

       0                                                             AS

       vlr_atacado,

       0                                                             AS

       qtd_atacado,

       produto.url_foto_s3                                           AS

       image_url

FROM   produto,

       embalagemregiao,

       depto,

       secao,

       categ,

       marcas,

       estoque,

       parametro,

       filial

WHERE  filial.id_parametro = parametro.id_parametro

       AND embalagemregiao.codfilial = filial.codfilial

       AND filial.codfilial = estoque.codfilial

       and filial.USA_SITE_MERCADO = 'S'

       AND produto.codprod = embalagemregiao.codprod

       AND produto.codprod = estoque.codprod

       AND parametro.NUMREGIAO_ECOMMERCE = embalagemregiao.numregiao

       AND produto.codepto = depto.codepto

       AND produto.codsec = secao.codsec

       AND produto.codcat = categ.codcateg(+)

       AND produto.codmarca = marcas.codigo(+)

       and produto.codepto is not null

       and produto.codsec is not null

       and produto.revenda = 'S'

       and NVL(produto.venda_fv,'S') = 'S'

       AND NVL(EMBALAGEMREGIAO.PVENDA1,0) > 0

       ORDER BY

       PRODUTO.CODPROD
/


-- End of DDL Script for View MARMORE.SITEMERCADO_PRODUTO

