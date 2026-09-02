object FrmConfiguracaoIA: TFrmConfiguracaoIA
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Configuração da API de IA'
  ClientHeight = 690
  ClientWidth = 820
  Color = 16250871
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 3158064
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17

  object pnlTopo: TPanel
    Left = 0
    Top = 0
    Width = 820
    Height = 88
    Align = alTop
    BevelOuter = bvNone
    Color = 2105376
    ParentBackground = False
    TabOrder = 0

    object lblTitulo: TLabel
      Left = 24
      Top = 16
      Width = 240
      Height = 25
      Caption = 'Configuração da API de IA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end

    object lblAviso: TLabel
      Left = 24
      Top = 50
      Width = 650
      Height = 17
      Caption = 'Oracle é obtido automaticamente da conexão ativa do ERP.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end

  object grpApi: TGroupBox
    Left = 24
    Top = 104
    Width = 772
    Height = 155
    Caption = ' API '
    TabOrder = 1

    object lblApiUrl: TLabel
      Left = 16
      Top = 24
      Width = 67
      Height = 17
      Caption = 'URL da API'
    end

    object edtApiUrl: TEdit
      Left = 16
      Top = 45
      Width = 740
      Height = 25
      TabOrder = 0
      Text = 'http://127.0.0.1:8080'
    end

    object lblPython: TLabel
      Left = 16
      Top = 80
      Width = 110
      Height = 17
      Caption = 'Executável Python'
    end

    object edtPython: TEdit
      Left = 16
      Top = 101
      Width = 220
      Height = 25
      TabOrder = 1
      Text = 'python.exe'
    end

    object lblServerDir: TLabel
      Left = 256
      Top = 80
      Width = 127
      Height = 17
      Caption = 'Pasta server do projeto'
    end

    object edtServerDir: TEdit
      Left = 256
      Top = 101
      Width = 500
      Height = 25
      TabOrder = 2
    end
  end

  object grpOpenAI: TGroupBox
    Left = 24
    Top = 270
    Width = 772
    Height = 155
    Caption = ' OpenAI '
    TabOrder = 2

    object lblProvider: TLabel
      Left = 16
      Top = 24
      Width = 50
      Height = 17
      Caption = 'Provider'
    end

    object edtProvider: TEdit
      Left = 16
      Top = 45
      Width = 170
      Height = 25
      TabOrder = 0
      Text = 'openai'
    end

    object lblModelo: TLabel
      Left = 202
      Top = 24
      Width = 44
      Height = 17
      Caption = 'Modelo'
    end

    object edtModelo: TEdit
      Left = 202
      Top = 45
      Width = 190
      Height = 25
      TabOrder = 1
      Text = 'gpt-5-mini'
    end

    object lblOpenAIKey: TLabel
      Left = 16
      Top = 82
      Width = 72
      Height = 17
      Caption = 'OpenAI API Key'
    end

    object edtOpenAIKey: TEdit
      Left = 16
      Top = 103
      Width = 590
      Height = 25
      PasswordChar = '*'
      TabOrder = 2
    end

    object chkMostrarOpenAIKey: TCheckBox
      Left = 620
      Top = 105
      Width = 130
      Height = 21
      Caption = 'Mostrar chave'
      TabOrder = 3
      OnClick = chkMostrarOpenAIKeyClick
    end
  end

  object grpOracle: TGroupBox
    Left = 24
    Top = 436
    Width = 772
    Height = 108
    Caption = ' Oracle - conexão atual do ERP '
    TabOrder = 3

    object lblOracleStatus: TLabel
      Left = 16
      Top = 25
      Width = 182
      Height = 17
      Caption = 'Conexão ERP: NÃO CARREGADA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3158064
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end

    object lblOracleUsuario: TLabel
      Left = 16
      Top = 51
      Width = 55
      Height = 17
      Caption = 'Usuário: -'
    end

    object lblOracleDsn: TLabel
      Left = 16
      Top = 76
      Width = 106
      Height = 17
      Caption = 'Servidor/Service: -'
    end
  end

  object chkAutoStart: TCheckBox
    Left = 24
    Top = 558
    Width = 300
    Height = 21
    Caption = 'Iniciar API automaticamente ao abrir'
    TabOrder = 4
  end

  object chkShowConsole: TCheckBox
    Left = 340
    Top = 558
    Width = 330
    Height = 21
    Caption = 'Exibir janela do Python para diagnóstico'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end

  object grpStatus: TGroupBox
    Left = 24
    Top = 590
    Width = 772
    Height = 52
    Caption = ' Status '
    TabOrder = 6

    object lblStatusApi: TLabel
      Left = 16
      Top = 23
      Width = 80
      Height = 17
      Caption = 'API OFFLINE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3158064
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end

    object memDetalhes: TMemo
      Left = 120
      Top = 15
      Width = 636
      Height = 26
      ReadOnly = True
      TabOrder = 0
    end
  end

  object btnTestar: TButton
    Left = 24
    Top = 650
    Width = 92
    Height = 32
    Caption = 'Testar'
    TabOrder = 7
    OnClick = btnTestarClick
  end

  object btnIniciar: TButton
    Left = 124
    Top = 650
    Width = 92
    Height = 32
    Caption = 'Iniciar'
    TabOrder = 8
    OnClick = btnIniciarClick
  end

  object btnReiniciar: TButton
    Left = 224
    Top = 650
    Width = 92
    Height = 32
    Caption = 'Reiniciar'
    TabOrder = 9
    OnClick = btnReiniciarClick
  end

  object btnParar: TButton
    Left = 324
    Top = 650
    Width = 92
    Height = 32
    Caption = 'Parar'
    TabOrder = 10
    OnClick = btnPararClick
  end

  object btnSalvar: TButton
    Left = 604
    Top = 650
    Width = 92
    Height = 32
    Caption = 'Salvar'
    Default = True
    TabOrder = 11
    OnClick = btnSalvarClick
  end

  object btnFechar: TButton
    Left = 704
    Top = 650
    Width = 92
    Height = 32
    Cancel = True
    Caption = 'Fechar'
    TabOrder = 12
    OnClick = btnFecharClick
  end
end
