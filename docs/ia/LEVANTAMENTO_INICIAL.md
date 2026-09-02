# Plataforma de IA - levantamento inicial

Data do levantamento: 2026-09-02

## Resultado

O diretório fornecido ainda não contém o projeto Delphi. Não foram encontrados
arquivos `.dpr`, `.dproj`, `.pas` ou `.dfm`. Por isso, nenhuma unit, formulário,
DataModule, componente ou integração foi criada: fazê-lo exigiria presumir a
versão do Delphi e padrões internos ainda não confirmados.

Foram encontrados:

- a especificação principal do MVP somente leitura;
- um documento de arquitetura (versão 2.0);
- 12 scripts de definição de Views Oracle na pasta `Views BI`.

## O que pode ser reutilizado agora

- As definições das Views como fonte documental de nomes e colunas reais.
- Os princípios de separação entre conversa, contexto do usuário e conhecimento.
- O contrato de pergunta/resposta independente do provedor, materializado em
  `contracts/ia`.

As Views não estão automaticamente autorizadas para a IA. O catálogo inicial
mantém todas com `authorized_for_ai: false` até aprovação explícita.

## O que foi criado

- Contratos JSON Schema para contexto, pergunta e resposta do assistente.
- Catálogo inicial das Views encontradas, sem inferir descrições funcionais.
- Este levantamento de dependências e lacunas.

## Informações necessárias para implementar o cliente Delphi

Fornecer uma amostra pequena, mas representativa, contendo:

1. `.dpr` e `.dproj` do ERP, ou indicação exata da versão do Delphi;
2. um formulário VCL recente (`.pas` e `.dfm`) usado como padrão visual;
3. DataModule/unit que exponha a conexão FireDAC, sem credenciais;
4. units que forneçam usuário, empresa, filial atual e filiais permitidas;
5. rotina real de verificação de permissões;
6. infraestrutura HTTP e JSON já utilizada, se houver;
7. padrão existente de logging, mensagens e tratamento de exceções;
8. contrato e autenticação da API corporativa, se já existirem;
9. regra de atalho desejada para Enter/Ctrl+Enter.

Com esses arquivos será possível adaptar nomes e implementar tipos, cliente da
API e primeira tela de chat sem acoplamento ao provedor.

## Informações necessárias para habilitar dados vivos

Para cada View candidata, confirmar:

- se está autorizada para IA;
- finalidade e granularidade;
- significado e sensibilidade dos campos;
- filtros implícitos e regras consolidadas;
- coluna(s) de escopo por empresa/filial;
- permissões adicionais;
- exemplos de consultas validadas;
- limites e observações operacionais.

`ESTRUTURA_V` expõe metadados do schema e deve permanecer bloqueada salvo
decisão explícita de segurança. Views contendo CPF/CNPJ, e-mail, telefone ou
endereço exigem classificação e política de exposição antes do uso.

## Banco e configuração

Nenhuma alteração de banco foi criada. Nenhuma API key, endpoint, credencial ou
configuração de provider foi adicionada ao cliente.
