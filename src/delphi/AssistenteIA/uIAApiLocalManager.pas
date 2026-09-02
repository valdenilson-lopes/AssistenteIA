unit uIAApiLocalManager;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  System.Net.URLClient,
  System.Net.HttpClient,
  System.NetEncoding,
  FireDAC.Comp.Client,
  uIAConfiguracao,
  Unt_Conexao;

type
  TIAApiLocalSettings = class
  private
    FServerDir: string;
    FPythonExe: string;
    FAutoStart: Boolean;
    FShowConsole: Boolean;

    FProvider: string;
    FOpenAIKey: string;
    FOpenAIModel: string;

    FOracleUser: string;
    FOraclePassword: string;
    FOracleDsn: string;
    FOracleSource: string;

    function GetIniFileName: string;
    function ProtectSecret(const AValue: string): string;
    function UnprotectSecret(const AValue: string): string;
  public
    constructor Create;
    procedure Load;
    procedure Save;

    property ServerDir: string read FServerDir write FServerDir;
    property PythonExe: string read FPythonExe write FPythonExe;
    property AutoStart: Boolean read FAutoStart write FAutoStart;
    property ShowConsole: Boolean read FShowConsole write FShowConsole;

    property Provider: string read FProvider write FProvider;
    property OpenAIKey: string read FOpenAIKey write FOpenAIKey;
    property OpenAIModel: string read FOpenAIModel write FOpenAIModel;

    property OracleUser: string read FOracleUser write FOracleUser;
    property OraclePassword: string read FOraclePassword write FOraclePassword;
    property OracleDsn: string read FOracleDsn write FOracleDsn;
    property OracleSource: string read FOracleSource write FOracleSource;
  end;

  TIAApiHealth = record
    Online: Boolean;
    StatusCode: Integer;
    Body: string;
    ErrorMessage: string;
  end;

  TIAApiLocalManager = class
  private
    FConfiguracao: TIAConfiguracao;
    FSettings: TIAApiLocalSettings;
    FProcessInfo: TProcessInformation;
    FStartedByThisProcess: Boolean;

    function BuildCommandLine: string;
    function ApiHealthUrl: string;
    function ProcessIsRunning: Boolean;
    function ParamValue(const AConnection: TFDConnection;
      const ANames: array of string): string;
    function BuildOracleDsnFromConnection(
      const AConnection: TFDConnection): string;

    procedure CloseProcessHandles;
    procedure ApplyEnvironment;
    procedure RestoreEnvironment(
      const AProvider, AOpenAIKey, AOpenAIModel,
            AOracleUser, AOraclePassword, AOracleDsn: string;
      const AHadProvider, AHadOpenAIKey, AHadOpenAIModel,
            AHadOracleUser, AHadOraclePassword, AHadOracleDsn: Boolean
    );
  public
    constructor Create(const AConfiguracao: TIAConfiguracao);
    destructor Destroy; override;

    procedure LoadOracleFromERP;

    function CheckHealth: TIAApiHealth;
    function WaitUntilHealthy(const ATimeoutMs: Cardinal = 10000): Boolean;

    procedure Start;
    procedure Stop;
    procedure Restart;

    property Settings: TIAApiLocalSettings read FSettings;
    property StartedByThisProcess: Boolean read FStartedByThisProcess;
  end;

implementation

type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

const
  CRYPTPROTECT_UI_FORBIDDEN = $00000001;

function CryptProtectData(
  pDataIn: PDataBlob;
  szDataDescr: PWideChar;
  pOptionalEntropy: PDataBlob;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDataBlob
): BOOL; stdcall; external 'Crypt32.dll';

function CryptUnprotectData(
  pDataIn: PDataBlob;
  ppszDataDescr: PPWideChar;
  pOptionalEntropy: PDataBlob;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PDataBlob
): BOOL; stdcall; external 'Crypt32.dll';

function RemoveTrailingSlash(const AValue: string): string;
begin
  Result := Trim(AValue);
  while (Result <> '') and
        CharInSet(Result[Length(Result)], ['/', '\']) do
    Delete(Result, Length(Result), 1);
end;

function QuoteArg(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;

function ReadEnv(const AName: string; out AExists: Boolean): string;
var
  Len: DWORD;
begin
  Len := GetEnvironmentVariable(PChar(AName), nil, 0);
  AExists := Len > 0;

  if not AExists then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, Len - 1);
  if Len > 1 then
    GetEnvironmentVariable(PChar(AName), PChar(Result), Len);
end;

procedure RestoreEnv(const AName, AValue: string; const AExists: Boolean);
begin
  if AExists then
    SetEnvironmentVariable(PChar(AName), PChar(AValue))
  else
    SetEnvironmentVariable(PChar(AName), nil);
end;

{ TIAApiLocalSettings }

constructor TIAApiLocalSettings.Create;
begin
  inherited Create;

  FPythonExe := 'python.exe';
  FServerDir := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '..\..\..\server'
  );

  FAutoStart := False;
  FShowConsole := True;

  FProvider := 'openai';
  FOpenAIKey := '';
  FOpenAIModel := 'gpt-5-mini';

  FOracleUser := '';
  FOraclePassword := '';
  FOracleDsn := '';
  FOracleSource := '';

  Load;
end;

function TIAApiLocalSettings.GetIniFileName: string;
var
  BaseDir: string;
begin
  BaseDir := TPath.Combine(
    GetEnvironmentVariable('APPDATA'),
    'AssistenteIA'
  );

  if Trim(BaseDir) = '' then
    BaseDir := TPath.Combine(TPath.GetTempPath, 'AssistenteIA');

  ForceDirectories(BaseDir);

  Result := TPath.Combine(BaseDir, 'ia-api-local.ini');
end;

function TIAApiLocalSettings.ProtectSecret(const AValue: string): string;
var
  InBlob: TDataBlob;
  OutBlob: TDataBlob;
  Bytes: TBytes;
begin
  Result := '';

  if AValue = '' then
    Exit;

  Bytes := TEncoding.UTF8.GetBytes(AValue);

  ZeroMemory(@InBlob, SizeOf(InBlob));
  ZeroMemory(@OutBlob, SizeOf(OutBlob));

  if Length(Bytes) > 0 then
  begin
    InBlob.cbData := Length(Bytes);
    InBlob.pbData := @Bytes[0];
  end;

  if not CryptProtectData(
    @InBlob,
    nil,
    nil,
    nil,
    nil,
    CRYPTPROTECT_UI_FORBIDDEN,
    @OutBlob
  ) then
    RaiseLastOSError;

  try
    SetLength(Bytes, OutBlob.cbData);

    if OutBlob.cbData > 0 then
      Move(OutBlob.pbData^, Bytes[0], OutBlob.cbData);

    Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
  finally
    if OutBlob.pbData <> nil then
      LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

function TIAApiLocalSettings.UnprotectSecret(const AValue: string): string;
var
  InBlob: TDataBlob;
  OutBlob: TDataBlob;
  Bytes: TBytes;
  Description: PWideChar;
begin
  Result := '';

  if Trim(AValue) = '' then
    Exit;

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(AValue);

  ZeroMemory(@InBlob, SizeOf(InBlob));
  ZeroMemory(@OutBlob, SizeOf(OutBlob));
  Description := nil;

  if Length(Bytes) > 0 then
  begin
    InBlob.cbData := Length(Bytes);
    InBlob.pbData := @Bytes[0];
  end;

  if not CryptUnprotectData(
    @InBlob,
    @Description,
    nil,
    nil,
    nil,
    CRYPTPROTECT_UI_FORBIDDEN,
    @OutBlob
  ) then
    RaiseLastOSError;

  try
    SetLength(Bytes, OutBlob.cbData);

    if OutBlob.cbData > 0 then
      Move(OutBlob.pbData^, Bytes[0], OutBlob.cbData);

    Result := TEncoding.UTF8.GetString(Bytes);
  finally
    if Description <> nil then
      LocalFree(HLOCAL(Description));

    if OutBlob.pbData <> nil then
      LocalFree(HLOCAL(OutBlob.pbData));
  end;
end;

procedure TIAApiLocalSettings.Load;
var
  Ini: TIniFile;
  Enc: string;
begin
  Ini := TIniFile.Create(GetIniFileName);
  try
    FServerDir := Ini.ReadString('API', 'ServerDir', FServerDir);
    FPythonExe := Ini.ReadString('API', 'PythonExe', FPythonExe);
    FAutoStart := Ini.ReadBool('API', 'AutoStart', FAutoStart);
    FShowConsole := Ini.ReadBool('API', 'ShowConsole', FShowConsole);

    FProvider := Ini.ReadString('OPENAI', 'Provider', FProvider);
    FOpenAIModel := Ini.ReadString('OPENAI', 'Model', FOpenAIModel);

    Enc := Ini.ReadString('OPENAI', 'ApiKeyProtected', '');
    if Enc <> '' then
    begin
      try
        FOpenAIKey := UnprotectSecret(Enc);
      except
        FOpenAIKey := '';
      end;
    end;

    FOracleSource := Ini.ReadString('ORACLE', 'Source', '');
  finally
    Ini.Free;
  end;
end;

procedure TIAApiLocalSettings.Save;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniFileName);
  try
    Ini.WriteString('API', 'ServerDir', FServerDir);
    Ini.WriteString('API', 'PythonExe', FPythonExe);
    Ini.WriteBool('API', 'AutoStart', FAutoStart);
    Ini.WriteBool('API', 'ShowConsole', FShowConsole);

    Ini.WriteString('OPENAI', 'Provider', FProvider);
    Ini.WriteString('OPENAI', 'Model', FOpenAIModel);

    if Trim(FOpenAIKey) <> '' then
      Ini.WriteString(
        'OPENAI',
        'ApiKeyProtected',
        ProtectSecret(FOpenAIKey)
      )
    else
      Ini.DeleteKey('OPENAI', 'ApiKeyProtected');

    { Não persiste usuário/senha/DSN Oracle.
      Eles são sempre obtidos novamente da conexão ativa do ERP. }
    Ini.WriteString('ORACLE', 'Source', FOracleSource);
    Ini.DeleteKey('ORACLE', 'User');
    Ini.DeleteKey('ORACLE', 'Dsn');
    Ini.DeleteKey('ORACLE', 'PasswordProtected');
  finally
    Ini.Free;
  end;
end;

{ TIAApiLocalManager }

constructor TIAApiLocalManager.Create(
  const AConfiguracao: TIAConfiguracao
);
begin
  inherited Create;

  FConfiguracao := AConfiguracao;
  FSettings := TIAApiLocalSettings.Create;

  ZeroMemory(@FProcessInfo, SizeOf(FProcessInfo));

  FStartedByThisProcess := False;

  { Carrega automaticamente a conexao Oracle oficial do ERP.
    Se o DataModule ainda nao estiver pronto, a tela continua abrindo e
    uma nova tentativa sera feita antes de iniciar/reiniciar a API. }
  if Assigned(dm_conexao) and
     Assigned(dm_conexao.FDConnection) and
     dm_conexao.FDConnection.Connected then
  begin
    try
      LoadOracleFromERP;
    except
      { Nao bloqueia a criacao do manager. }
    end;
  end;
end;

destructor TIAApiLocalManager.Destroy;
begin
  CloseProcessHandles;
  FreeAndNil(FSettings);
  inherited;
end;

function TIAApiLocalManager.ParamValue(
  const AConnection: TFDConnection;
  const ANames: array of string
): string;
var
  I: Integer;
begin
  Result := '';

  if AConnection = nil then
    Exit;

  for I := Low(ANames) to High(ANames) do
  begin
    Result := Trim(AConnection.Params.Values[ANames[I]]);

    if Result <> '' then
      Exit;
  end;
end;

function TIAApiLocalManager.BuildOracleDsnFromConnection(
  const AConnection: TFDConnection
): string;
var
  Server: string;
  Port: string;
  DatabaseName: string;
begin
  Server := ParamValue(
    AConnection,
    ['Server', 'Host', 'HostName']
  );

  Port := ParamValue(
    AConnection,
    ['Port']
  );

  DatabaseName := ParamValue(
    AConnection,
    ['Database', 'Service_Name', 'ServiceName', 'SID']
  );

  if Port = '' then
    Port := '1521';

  if (Server <> '') and (DatabaseName <> '') then
  begin
    Result :=
      Server + ':' + Port + '/' + DatabaseName;
    Exit;
  end;

  { Algumas configurações FireDAC Oracle já mantêm o connect descriptor,
    TNS alias ou host/service inteiro em Database. }
  Result := DatabaseName;
end;

procedure TIAApiLocalManager.LoadOracleFromERP;
begin
  if not Assigned(dm_conexao) then
    raise Exception.Create(
      'O DataModule de conexao do ERP nao esta disponivel.');

  if not dm_conexao.FDConnection.Connected then
    raise Exception.Create(
      'A conexao Oracle do ERP nao esta ativa.');

  FSettings.OracleUser :=
    Trim(dm_conexao.vsUSUARIOBD);

  FSettings.OraclePassword :=
    dm_conexao.vsSENHABD;

  FSettings.OracleDsn :=
    Trim(dm_conexao.vsBANCO);

  FSettings.OracleSource :=
    'Unt_Conexao';

  if FSettings.OracleUser = '' then
    raise Exception.Create(
      'Usuario Oracle nao encontrado na Unt_Conexao.');

  if FSettings.OraclePassword = '' then
    raise Exception.Create(
      'Senha Oracle nao encontrada na Unt_Conexao.');

  if FSettings.OracleDsn = '' then
    raise Exception.Create(
      'Banco Oracle nao encontrado na Unt_Conexao.');
end;

function TIAApiLocalManager.CheckHealth: TIAApiHealth;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  Headers: TNetHeaders;
  Token: string;
begin
  Result.Online := False;
  Result.StatusCode := 0;
  Result.Body := '';
  Result.ErrorMessage := '';

  if Trim(FConfiguracao.ApiBaseUrl) = '' then
  begin
    Result.ErrorMessage :=
      'URL da API não configurada.';
    Exit;
  end;

  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 2500;
    Client.ResponseTimeout := 2500;

    Token := Trim(FConfiguracao.AccessToken);

    SetLength(Headers, 1);
    Headers[0] := TNetHeader.Create(
      'Accept',
      'application/json'
    );

    if Token <> '' then
    begin
      SetLength(Headers, 2);
      Headers[1] := TNetHeader.Create(
        'Authorization',
        'Bearer ' + Token
      );
    end;

    try
      Response := Client.Get(
        ApiHealthUrl,
        nil,
        Headers
      );

      Result.StatusCode := Response.StatusCode;
      Result.Body := Response.ContentAsString(TEncoding.UTF8);

      Result.Online :=
        (Response.StatusCode >= 200) and
        (Response.StatusCode < 300);

      if not Result.Online then
        Result.ErrorMessage :=
          'A API respondeu HTTP ' +
          IntToStr(Response.StatusCode) + '.';
    except
      on E: Exception do
        Result.ErrorMessage := E.Message;
    end;
  finally
    Client.Free;
  end;
end;

function TIAApiLocalManager.BuildCommandLine: string;
var
  MainPy: string;
begin
  MainPy := TPath.Combine(
    FSettings.ServerDir,
    'main.py'
  );

  if not FileExists(MainPy) then
    raise EFileNotFoundException.Create(
      'Não foi encontrado main.py em: ' +
      FSettings.ServerDir
    );

  if Trim(FSettings.PythonExe) = '' then
    raise EInvalidOpException.Create(
      'Informe o executável do Python.'
    );

  Result :=
    QuoteArg(FSettings.PythonExe) +
    ' ' +
    QuoteArg(MainPy);
end;

function TIAApiLocalManager.ProcessIsRunning: Boolean;
var
  ExitCode: DWORD;
begin
  Result := False;

  if FProcessInfo.hProcess = 0 then
    Exit;

  if GetExitCodeProcess(FProcessInfo.hProcess, ExitCode) then
    Result := ExitCode = STILL_ACTIVE;
end;

procedure TIAApiLocalManager.CloseProcessHandles;
begin
  if FProcessInfo.hThread <> 0 then
  begin
    CloseHandle(FProcessInfo.hThread);
    FProcessInfo.hThread := 0;
  end;

  if FProcessInfo.hProcess <> 0 then
  begin
    CloseHandle(FProcessInfo.hProcess);
    FProcessInfo.hProcess := 0;
  end;

  FProcessInfo.dwProcessId := 0;
  FProcessInfo.dwThreadId := 0;
end;

function TIAApiLocalManager.ApiHealthUrl: string;
begin
  Result :=
    RemoveTrailingSlash(FConfiguracao.ApiBaseUrl) +
    '/health';
end;

procedure TIAApiLocalManager.ApplyEnvironment;
begin
  SetEnvironmentVariable(
    'ERP_IA_PROVIDER',
    PChar(Trim(FSettings.Provider))
  );

  SetEnvironmentVariable(
    'OPENAI_API_KEY',
    PChar(Trim(FSettings.OpenAIKey))
  );

  SetEnvironmentVariable(
    'ERP_IA_OPENAI_MODEL',
    PChar(Trim(FSettings.OpenAIModel))
  );

  SetEnvironmentVariable(
    'ERP_IA_ORACLE_USER',
    PChar(Trim(FSettings.OracleUser))
  );

  SetEnvironmentVariable(
    'ERP_IA_ORACLE_PASSWORD',
    PChar(FSettings.OraclePassword)
  );

  SetEnvironmentVariable(
    'ERP_IA_ORACLE_DSN',
    PChar(Trim(FSettings.OracleDsn))
  );
end;

procedure TIAApiLocalManager.RestoreEnvironment(
  const AProvider, AOpenAIKey, AOpenAIModel,
        AOracleUser, AOraclePassword, AOracleDsn: string;
  const AHadProvider, AHadOpenAIKey, AHadOpenAIModel,
        AHadOracleUser, AHadOraclePassword, AHadOracleDsn: Boolean
);
begin
  RestoreEnv('ERP_IA_PROVIDER', AProvider, AHadProvider);
  RestoreEnv('OPENAI_API_KEY', AOpenAIKey, AHadOpenAIKey);
  RestoreEnv('ERP_IA_OPENAI_MODEL', AOpenAIModel, AHadOpenAIModel);
  RestoreEnv('ERP_IA_ORACLE_USER', AOracleUser, AHadOracleUser);
  RestoreEnv('ERP_IA_ORACLE_PASSWORD', AOraclePassword, AHadOraclePassword);
  RestoreEnv('ERP_IA_ORACLE_DSN', AOracleDsn, AHadOracleDsn);
end;

procedure TIAApiLocalManager.Start;
var
  StartupInfo: TStartupInfo;
  CmdLine: string;
  WorkDir: string;
  Flags: DWORD;
  CmdBuffer: array of Char;

  OldProvider: string;
  OldOpenAIKey: string;
  OldOpenAIModel: string;
  OldOracleUser: string;
  OldOraclePassword: string;
  OldOracleDsn: string;

  HadProvider: Boolean;
  HadOpenAIKey: Boolean;
  HadOpenAIModel: Boolean;
  HadOracleUser: Boolean;
  HadOraclePassword: Boolean;
  HadOracleDsn: Boolean;
begin
  
  { Atualiza sempre com a conexao atual do ERP antes de iniciar a API. }
  LoadOracleFromERP;

if CheckHealth.Online then
    Exit;

  if ProcessIsRunning then
  begin
    if not WaitUntilHealthy(10000) then
      raise EInvalidOpException.Create(
        'O processo da API está ativo, mas /health não respondeu.'
      );

    Exit;
  end;

  if SameText(Trim(FSettings.Provider), 'openai') and
     (Trim(FSettings.OpenAIKey) = '') then
    raise EInvalidOpException.Create(
      'Informe a chave da OpenAI.'
    );

  if Trim(FSettings.OpenAIModel) = '' then
    raise EInvalidOpException.Create(
      'Informe o modelo da OpenAI.'
    );

  if (Trim(FSettings.OracleUser) = '') or
     (Trim(FSettings.OraclePassword) = '') or
     (Trim(FSettings.OracleDsn) = '') then
    raise EInvalidOpException.Create(
      'A conexão Oracle do ERP ainda não foi carregada para a API.'
    );

  OldProvider := ReadEnv('ERP_IA_PROVIDER', HadProvider);
  OldOpenAIKey := ReadEnv('OPENAI_API_KEY', HadOpenAIKey);
  OldOpenAIModel := ReadEnv('ERP_IA_OPENAI_MODEL', HadOpenAIModel);
  OldOracleUser := ReadEnv('ERP_IA_ORACLE_USER', HadOracleUser);
  OldOraclePassword := ReadEnv('ERP_IA_ORACLE_PASSWORD', HadOraclePassword);
  OldOracleDsn := ReadEnv('ERP_IA_ORACLE_DSN', HadOracleDsn);

  CloseProcessHandles;

  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  ZeroMemory(@FProcessInfo, SizeOf(FProcessInfo));

  StartupInfo.cb := SizeOf(StartupInfo);

  CmdLine := BuildCommandLine;
  WorkDir := ExcludeTrailingPathDelimiter(FSettings.ServerDir);

  SetLength(CmdBuffer, Length(CmdLine) + 1);
  StrPCopy(PChar(CmdBuffer), CmdLine);

  if FSettings.ShowConsole then
    Flags := CREATE_NEW_CONSOLE
  else
    Flags := CREATE_NO_WINDOW;

  ApplyEnvironment;

  try
    if not CreateProcess(
      nil,
      PChar(CmdBuffer),
      nil,
      nil,
      False,
      Flags,
      nil,
      PChar(WorkDir),
      StartupInfo,
      FProcessInfo
    ) then
      RaiseLastOSError;
  finally
    RestoreEnvironment(
      OldProvider,
      OldOpenAIKey,
      OldOpenAIModel,
      OldOracleUser,
      OldOraclePassword,
      OldOracleDsn,
      HadProvider,
      HadOpenAIKey,
      HadOpenAIModel,
      HadOracleUser,
      HadOraclePassword,
      HadOracleDsn
    );
  end;

  if FProcessInfo.hThread <> 0 then
  begin
    CloseHandle(FProcessInfo.hThread);
    FProcessInfo.hThread := 0;
  end;

  FStartedByThisProcess := True;

  if not WaitUntilHealthy(12000) then
    raise EInvalidOpException.Create(
      'A API foi iniciada, mas não ficou disponível no prazo esperado. ' +
      'Verifique a janela do Python para identificar o erro.'
    );
end;

procedure TIAApiLocalManager.Stop;
begin
  if not FStartedByThisProcess then
  begin
    if CheckHealth.Online then
      raise EInvalidOpException.Create(
        'A API está ativa, mas não foi iniciada por esta execução do ERP. ' +
        'Por segurança, o Delphi não encerrará um processo externo.'
      );

    Exit;
  end;

  if ProcessIsRunning then
  begin
    if not TerminateProcess(FProcessInfo.hProcess, 0) then
      RaiseLastOSError;

    WaitForSingleObject(FProcessInfo.hProcess, 5000);
  end;

  CloseProcessHandles;
  FStartedByThisProcess := False;
end;

procedure TIAApiLocalManager.Restart;
begin
  if CheckHealth.Online and
     not FStartedByThisProcess then
    raise EInvalidOpException.Create(
      'A API já está ativa externamente. ' +
      'O reinício só é permitido quando a API foi iniciada pelo próprio Delphi.'
    );

  if FStartedByThisProcess then
    Stop;

  Sleep(300);
  Start;
end;

function TIAApiLocalManager.WaitUntilHealthy(
  const ATimeoutMs: Cardinal
): Boolean;
var
  Started: Cardinal;
  Health: TIAApiHealth;
begin
  Result := False;
  Started := GetTickCount;

  repeat
    Health := CheckHealth;

    if Health.Online then
      Exit(True);

    Sleep(300);

  until GetTickCount - Started >= ATimeoutMs;
end;

end.