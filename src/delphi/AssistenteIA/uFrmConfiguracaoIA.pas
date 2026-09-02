unit uFrmConfiguracaoIA;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Dialogs,
  Vcl.Controls,
  uIAConfiguracao,
  uIAApiLocalManager;

type
  TFrmConfiguracaoIA = class(TForm)
    pnlTopo: TPanel;
    lblTitulo: TLabel;
    lblAviso: TLabel;

    grpApi: TGroupBox;
    lblApiUrl: TLabel;
    edtApiUrl: TEdit;
    lblPython: TLabel;
    edtPython: TEdit;
    lblServerDir: TLabel;
    edtServerDir: TEdit;

    grpOpenAI: TGroupBox;
    lblProvider: TLabel;
    edtProvider: TEdit;
    lblOpenAIKey: TLabel;
    edtOpenAIKey: TEdit;
    lblModelo: TLabel;
    edtModelo: TEdit;
    chkMostrarOpenAIKey: TCheckBox;

    grpOracle: TGroupBox;
    lblOracleStatus: TLabel;
    lblOracleUsuario: TLabel;
    lblOracleDsn: TLabel;

    chkAutoStart: TCheckBox;
    chkShowConsole: TCheckBox;

    grpStatus: TGroupBox;
    lblStatusApi: TLabel;
    memDetalhes: TMemo;

    btnTestar: TButton;
    btnIniciar: TButton;
    btnReiniciar: TButton;
    btnParar: TButton;
    btnSalvar: TButton;
    btnFechar: TButton;

    procedure FormCreate(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnReiniciarClick(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure chkMostrarOpenAIKeyClick(Sender: TObject);

  private
    FConfiguracao: TIAConfiguracao;
    FManager: TIAApiLocalManager;

    procedure CarregarTela;
    procedure AplicarTela;
    procedure AtualizarStatus;
    procedure AtualizarOracle;

    procedure ExecutarAcao(
      const ACaption: string;
      const AProc: TProc
    );

  public
    class function Executar(
      const AOwner: TComponent;
      const AConfiguracao: TIAConfiguracao;
      const AManager: TIAApiLocalManager
    ): Boolean;
  end;

implementation

{$R *.dfm}

class function TFrmConfiguracaoIA.Executar(
  const AOwner: TComponent;
  const AConfiguracao: TIAConfiguracao;
  const AManager: TIAApiLocalManager
): Boolean;
var
  Form: TFrmConfiguracaoIA;
begin
  Form := TFrmConfiguracaoIA.Create(AOwner);

  try
    Form.FConfiguracao := AConfiguracao;
    Form.FManager := AManager;
    Form.CarregarTela;

    Result :=
      Form.ShowModal = System.UITypes.mrOk;
  finally
    Form.Free;
  end;
end;

procedure TFrmConfiguracaoIA.FormCreate(Sender: TObject);
begin
  Font.Name := 'Segoe UI';
  edtOpenAIKey.PasswordChar := '*';
  memDetalhes.Clear;
end;

procedure TFrmConfiguracaoIA.CarregarTela;
begin
  edtApiUrl.Text := FConfiguracao.ApiBaseUrl;
  edtPython.Text := FManager.Settings.PythonExe;
  edtServerDir.Text := FManager.Settings.ServerDir;

  edtProvider.Text := FManager.Settings.Provider;
  edtOpenAIKey.Text := FManager.Settings.OpenAIKey;
  edtModelo.Text := FManager.Settings.OpenAIModel;

  chkAutoStart.Checked := FManager.Settings.AutoStart;
  chkShowConsole.Checked := FManager.Settings.ShowConsole;

  AtualizarOracle;
  AtualizarStatus;
end;

procedure TFrmConfiguracaoIA.AplicarTela;
begin
  FConfiguracao.ApiBaseUrl := Trim(edtApiUrl.Text);

  FManager.Settings.PythonExe := Trim(edtPython.Text);
  FManager.Settings.ServerDir := Trim(edtServerDir.Text);

  FManager.Settings.Provider := Trim(edtProvider.Text);
  FManager.Settings.OpenAIKey := Trim(edtOpenAIKey.Text);
  FManager.Settings.OpenAIModel := Trim(edtModelo.Text);

  FManager.Settings.AutoStart := chkAutoStart.Checked;
  FManager.Settings.ShowConsole := chkShowConsole.Checked;
end;

procedure TFrmConfiguracaoIA.AtualizarOracle;
begin
  if Trim(FManager.Settings.OracleUser) = '' then
  begin
    lblOracleStatus.Caption := 'Conexão ERP: NÃO CARREGADA';
    lblOracleUsuario.Caption := 'Usuário: -';
    lblOracleDsn.Caption := 'Servidor/Service: -';
  end
  else
  begin
    lblOracleStatus.Caption := 'Conexão ERP: CONECTADA';
    lblOracleUsuario.Caption :=
      'Usuário: ' + FManager.Settings.OracleUser;

    lblOracleDsn.Caption :=
      'Servidor/Service: ' + FManager.Settings.OracleDsn;
  end;
end;

procedure TFrmConfiguracaoIA.AtualizarStatus;
var
  H: TIAApiHealth;
begin
  H := FManager.CheckHealth;

  if H.Online then
  begin
    lblStatusApi.Caption := 'API ONLINE';

    memDetalhes.Lines.Text :=
      'HTTP: ' +
      IntToStr(H.StatusCode) +
      sLineBreak +
      H.Body;
  end
  else
  begin
    lblStatusApi.Caption := 'API OFFLINE';
    memDetalhes.Lines.Text := H.ErrorMessage;

    if H.Body <> '' then
      memDetalhes.Lines.Add(H.Body);
  end;
end;

procedure TFrmConfiguracaoIA.ExecutarAcao(
  const ACaption: string;
  const AProc: TProc
);
begin
  Screen.Cursor := crHourGlass;

  try
    AplicarTela;

    try
      AProc;
      AtualizarOracle;
      AtualizarStatus;
    except
      on E: Exception do
      begin
        AtualizarOracle;
        AtualizarStatus;

        MessageDlg(
          ACaption +
          ':' +
          sLineBreak +
          E.Message,
          mtError,
          [mbOK],
          0
        );
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFrmConfiguracaoIA.btnTestarClick(Sender: TObject);
begin
  AplicarTela;
  AtualizarOracle;
  AtualizarStatus;
end;

procedure TFrmConfiguracaoIA.btnIniciarClick(Sender: TObject);
begin
  ExecutarAcao(
    'Não foi possível iniciar a API',
    procedure
    begin
      FManager.Start;
    end
  );
end;

procedure TFrmConfiguracaoIA.btnReiniciarClick(Sender: TObject);
begin
  ExecutarAcao(
    'Não foi possível reiniciar a API',
    procedure
    begin
      FManager.Restart;
    end
  );
end;

procedure TFrmConfiguracaoIA.btnPararClick(Sender: TObject);
begin
  ExecutarAcao(
    'Não foi possível parar a API',
    procedure
    begin
      FManager.Stop;
    end
  );
end;

procedure TFrmConfiguracaoIA.btnSalvarClick(Sender: TObject);
begin
  AplicarTela;
  FConfiguracao.Validar;

  if Trim(FManager.Settings.Provider) = '' then
    raise EInvalidOpException.Create(
      'Informe o provider da IA.'
    );

  if SameText(FManager.Settings.Provider, 'openai') then
  begin
    if Trim(FManager.Settings.OpenAIKey) = '' then
      raise EInvalidOpException.Create(
        'Informe a chave da OpenAI.'
      );

    if Trim(FManager.Settings.OpenAIModel) = '' then
      raise EInvalidOpException.Create(
        'Informe o modelo da OpenAI.'
      );
  end;

  if Trim(FManager.Settings.OracleUser) = '' then
    raise EInvalidOpException.Create(
      'A conexão Oracle do ERP ainda não foi carregada.'
    );

  FManager.Settings.Save;

  ModalResult := System.UITypes.mrOk;
end;

procedure TFrmConfiguracaoIA.btnFecharClick(Sender: TObject);
begin
  ModalResult := System.UITypes.mrCancel;
end;

procedure TFrmConfiguracaoIA.chkMostrarOpenAIKeyClick(Sender: TObject);
begin
  if chkMostrarOpenAIKey.Checked then
    edtOpenAIKey.PasswordChar := #0
  else
    edtOpenAIKey.PasswordChar := '*';
end;

end.
