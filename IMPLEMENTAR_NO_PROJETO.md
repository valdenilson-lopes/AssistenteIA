# Configuração e controle da API pelo Delphi

Este incremento adiciona ao projeto Delphi uma tela para:

- configurar a URL da API;
- informar o executável do Python;
- informar a pasta `server`;
- testar `/health`;
- iniciar a API;
- reiniciar a API;
- parar a API quando ela foi iniciada pela própria execução do Delphi;
- opcionalmente iniciar a API automaticamente ao abrir o Assistente;
- abrir o Python com console visível para diagnóstico.

## Segurança

A tela NÃO possui campo para `OPENAI_API_KEY`.

A chave do provider continua sendo lida pelo servidor Python por variável de
ambiente, conforme a arquitetura original:

```powershell
$env:ERP_IA_PROVIDER = 'openai'
$env:OPENAI_API_KEY = 'sua-chave'
$env:ERP_IA_OPENAI_MODEL = 'gpt-5-mini'
```

Para uso permanente, configure essas variáveis no ambiente da conta/serviço
que executa a API, e não dentro do Delphi.

## Arquivos novos

Copiar para `src/delphi/AssistenteIA`:

- `uIAApiLocalManager.pas`
- `uFrmConfiguracaoIA.pas`
- `uFrmConfiguracaoIA.dfm`

## Alteração necessária em uFrmAssistenteIA

### 1. Uses da implementation

Adicionar:

```delphi
uFrmConfiguracaoIA,
uIAApiLocalManager,
```

### 2. Campo privado

Adicionar:

```delphi
FApiLocalManager: TIAApiLocalManager;
```

### 3. FormCreate

Depois de criar `FConfiguracao`:

```delphi
FApiLocalManager := TIAApiLocalManager.Create(FConfiguracao);

if FApiLocalManager.Settings.AutoStart then
begin
  try
    FApiLocalManager.Start;
    lblStatus.Caption := 'API local iniciada';
  except
    on E: Exception do
      lblStatus.Caption := 'API local não iniciou: ' + E.Message;
  end;
end;
```

### 4. FormDestroy

Antes de `FConfiguracao.Free`:

```delphi
FApiLocalManager.Free;
```

A API NÃO é encerrada automaticamente ao fechar o ERP.

### 5. Botão no formulário

Adicionar um botão `btnConfigIA` no cabeçalho e o evento:

```delphi
procedure TFrmAssistenteIA.btnConfigIAClick(Sender: TObject);
begin
  if FProcessando then
    Exit;

  if TFrmConfiguracaoIA.Executar(
       Self,
       FConfiguracao,
       FApiLocalManager
     ) then
  begin
    lblStatus.Caption := 'Configuração da API atualizada';
  end;
end;
```

Sugestão de botão no DFM:

```delphi
object btnConfigIA: TButton
  Left = 700
  Top = 24
  Width = 145
  Height = 40
  Anchors = [akTop, akRight]
  Caption = 'Configurar API'
  TabOrder = 0
  OnClick = btnConfigIAClick
end
```

Ajuste o `TabOrder` do botão `btnNovaConversa` para 1.

## Configuração local salva

Somente os seguintes dados não secretos são persistidos em:

`%APPDATA%\AssistenteIA\ia-api-local.ini`

- pasta do servidor;
- caminho/nome do Python;
- auto start;
- exibir console.

A URL continua no objeto `TIAConfiguracao`. Se desejar persistência da URL,
ela pode continuar sendo fornecida por:

`ERP_IA_API_URL=http://127.0.0.1:8080`

O token ERP -> API continua vindo de `ERP_IA_API_TOKEN`.

## Comportamento de segurança do Reiniciar/Parar

O Delphi só encerra uma API se ele próprio iniciou aquele processo durante a
execução atual.

Se `/health` indicar que já existe uma API externa rodando, o botão Reiniciar
não usa `taskkill` nem encerra processos por porta/PID arbitrariamente.
