# Plataforma de IA do ERP

Fundação incremental de uma plataforma de IA corporativa integrada ao ERP
Delphi. O MVP é exclusivamente de consulta e não concede acesso automático a
nenhuma tabela ou View.

## Estrutura atual

- `src/delphi/AssistenteIA` - cliente VCL compilável e desacoplado do provider;
- `contracts/ia` - contratos JSON de contexto, pergunta e resposta;
- `knowledge/bi` - catálogo negado por padrão das Views fornecidas;
- `server` - serviço intermediário executável, governança, RAG, auditoria e testes;
- `docs/ia` - levantamento, decisões e lacunas de integração;
- `Views BI` - fontes Oracle originais, preservadas sem alteração.

## Fluxo do MVP

```text
Tela VCL
  -> IIAAssistenteService
  -> API corporativa HTTPS
  -> segurança e escopo no servidor
  -> conhecimento aprovado ou ferramenta autorizada
  -> resposta estruturada com fontes
```

Conhecimento, histórico e contexto do usuário são contratos separados. A tela
não conhece OpenAI, SQL, Oracle, RAG ou detalhes de ferramentas.

## Estado

O cliente VCL compila no Delphi 10.4 Sydney. O servidor de referência executa
em Python 3.11+ e possui persistência SQLite para dados próprios da plataforma.
A integração ao ERP aguarda as units e regras reais listadas em
`docs/ia/LEVANTAMENTO_INICIAL.md`.

Nenhuma alteração de banco é necessária nesta etapa.
