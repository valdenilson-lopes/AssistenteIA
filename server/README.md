# API intermediária - implementação de referência

Implementação executável em Python 3.11+ e SQLite, sem dependências externas no
modo texto/Markdown. Serve como referência funcional e pode ser substituída por
uma API corporativa mantendo os contratos JSON.

## Executar

```powershell
$env:ERP_IA_API_BEARER_TOKEN = 'token-corporativo-de-desenvolvimento'
.\run-server.ps1
```

Por padrão, a API escuta somente `127.0.0.1:8080`. Sem bearer token, requisições
são aceitas apenas por loopback. Em ambiente compartilhado, o token é
obrigatório e HTTPS deve ser encerrado por gateway/reverse proxy.

Para habilitar OpenAI no servidor:

```powershell
$env:ERP_IA_PROVIDER = 'openai'
$env:OPENAI_API_KEY = '...'
$env:ERP_IA_OPENAI_MODEL = 'gpt-5-mini'
python main.py
```

A chave nunca é enviada ao Delphi. O provider usa a Responses API com
`store=false`.

## Responsabilidades

- autenticar a sessão ERP;
- aplicar permissões e escopo de empresa/filial fora do modelo;
- manter secrets do provider somente no servidor;
- recusar assuntos externos ao ERP;
- separar perguntas documentais, de dados atuais e híbridas;
- recuperar somente conhecimento aprovado e relevante;
- executar apenas ferramentas e Views explicitamente autorizadas;
- auditar fontes, ferramenta, latência, modelo e consumo;
- retornar o contrato de `contracts/ia/resposta.schema.json`;
- criar demanda de conhecimento quando não houver evidência suficiente.

## Política inicial

- acesso a dados: negado por padrão;
- escrita e DDL: proibidos;
- web para usuário final: desabilitada;
- `knowledge/bi/views-catalog.json`: todas as Views começam bloqueadas;
- SQL ad hoc: fora do primeiro incremento;
- operações conhecidas: só após SQL e regras serem validados pelo ERP.

## Endpoint provisório

O cliente isolado usa `POST /ia/perguntar`. Ao integrar com uma API corporativa
existente, o caminho pode mudar dentro de `TIAApiClient` sem afetar a tela.

Endpoints implementados:

- `GET /health`;
- `POST /ia/conversas`;
- `POST /ia/perguntar`;
- `GET /ia/conversas/{id}`;
- `POST /ia/conhecimento/modulos`;
- `POST /ia/conhecimento/documentos`;
- `POST /ia/conhecimento/{id}/aprovar`;
- `POST /ia/conhecimento/{id}/rejeitar`;
- `POST /ia/conhecimento/{id}/reindexar`;
- `GET /ia/conhecimento/demandas`;
- `GET /ia/metricas`.

O gateway deve preencher e proteger `X-ERP-User`, `X-ERP-Company`,
`X-ERP-Branch` e `X-ERP-Roles`. O serviço confere esses valores contra o corpo,
mas cabe ao gateway impedir que o cliente sobrescreva cabeçalhos de identidade.

## Dependências ainda reais do ERP

- implementar `ReadOnlyQueryExecutor` para Oracle com credencial SELECT-only;
- aprovar Views e colunas, todas atualmente negadas;
- cadastrar SQL validado para operações conhecidas;
- trocar o validador conservador por parser Oracle antes de SQL ad hoc;
- conectar autenticação e permissões corporativas;
- adicionar extrator aprovado para PDF e demais formatos.

O SQLite armazena somente metadados da plataforma, conhecimento, conversas,
demandas e auditoria. Ele não representa nem replica dados operacionais do ERP.
