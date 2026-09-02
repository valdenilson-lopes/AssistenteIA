# Assistente IA do ERP - fundação VCL

Este projeto é o cliente VCL inicial da plataforma. Ele é propositalmente
independente do ERP para que o padrão visual e os adaptadores reais sejam
incorporados depois.

## O que está implementado

- tela de chat VCL responsiva, com processamento em segundo plano;
- envio por `Ctrl+Enter`, bloqueio de duplicidade e nova conversa;
- retorno estruturado, fontes e estado de conhecimento insuficiente;
- botão `Ensinar a IA` exibido somente quando solicitado pela API;
- cliente HTTP sem dependência da OpenAI e sem chave de provider;
- contexto de usuário/empresa/filial atrás de interface;
- histórico em memória atrás de interface de persistência;
- contratos para Centro de Conhecimento e ferramentas somente leitura.

## Como abrir

Abra `AssistenteIA.dpr` no Delphi e permita que a IDE gere o `.dproj` compatível
com a versão instalada. O `.dproj` não foi fixado deliberadamente porque a
versão real do Delphi ainda não foi informada.

A base usa VCL, namespaces `System.*`/`Vcl.*`, `System.JSON`,
`System.Net.HttpClient`, generics e tarefas. A versão mínima exata deverá ser
confirmada no ERP antes da integração.

## Configuração do projeto isolado

O adaptador provisório `TIAContextoAmbiente` lê:

- `ERP_IA_API_URL` - URL HTTPS da API corporativa;
- `ERP_IA_API_TOKEN` - token da API intermediária, somente para teste local;
- `ERP_COD_USUARIO`;
- `ERP_COD_EMPRESA`;
- `ERP_COD_FILIAL`;
- `ERP_FILIAIS_PERMITIDAS` - códigos separados por vírgula;
- `ERP_ROTINA_ORIGEM`;
- `ERP_VERSAO`.

O token corporativo pode ser lido de `ERP_IA_API_TOKEN` durante o teste local e
não é embutido no executável. Quando a autenticação real existir, o ERP deverá
atribuir um token de sessão de curta duração a `TIAConfiguracao.AccessToken`.
Esse token é da API corporativa; nunca é uma chave do provedor de IA.

Durante desenvolvimento, `http://localhost` e `http://127.0.0.1` são aceitos.
Qualquer outro host exige HTTPS.

## Contrato esperado da API

O cliente chama `POST {ERP_IA_API_URL}/ia/perguntar`. Os schemas neutros estão
em `../../../contracts/ia`. O endpoint pode ser adaptado ao contrato real da
API corporativa sem alterar a tela.

## Pontos de integração com o ERP

1. substituir `TIAContextoAmbiente` por um provider da sessão real;
2. injetar autenticação da API corporativa;
3. substituir `TIARepositorioHistoricoMemoria` por persistência aprovada;
4. aplicar o padrão visual e a classe-base dos formulários do ERP;
5. conectar o botão `Ensinar a IA` à tela do Centro de Conhecimento;
6. revisar nomes de units e estilo de código conforme o projeto real.

Nenhuma View BI está habilitada por este cliente. Essa decisão pertence à API,
que deve aplicar whitelist, permissões e escopo de empresa/filial.

## Conexao FireDAC do ERP

O adaptador `uIAConexaoERP` reutiliza a instancia existente do DataModule e
retorna `DM_CONEXAO.FDConnection`. Ele nao cria, conecta, desconecta ou libera a
conexao. A criacao de `DM_CONEXAO` continua sob responsabilidade do ERP.

`uIAConsultasERP` oferece leitura controlada das Views inicialmente liberadas.
As consultas selecionam apenas colunas declaradas, exigem filial, usam binds,
possuem timeout de 15 segundos e limitam o retorno a no maximo 200 registros.
Views de metadados ou sem escopo confirmado permanecem bloqueadas.

## Perguntas com dados reais

`uIAOperacoesConhecidas` conecta as primeiras intencoes diretamente a consultas
agregadas, sempre usando `DM_CONEXAO.FDConnection` e bind de filial:

- `Quanto vendemos hoje?` - valores agrupados por `TIPOMOVIMENTO`;
- `Quanto temos a receber vencido?` - receber em aberto e vencido;
- `Quais produtos estao com estoque baixo?` - quantidade abaixo do minimo.

O total de vendas mostra separadamente as classificacoes da View e informa que
nao representa venda liquida enquanto a regra comercial nao for aprovada.
