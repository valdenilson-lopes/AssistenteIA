unit uIAConfiguracao;

interface

uses
  System.SysUtils;

type
  TIAConfiguracao = class
  private
    FApiBaseUrl: string;
    FAccessToken: string;
    FTimeoutMs: Integer;
  public
    constructor Create;
    procedure Validar;
    property ApiBaseUrl: string read FApiBaseUrl write FApiBaseUrl;
    property AccessToken: string read FAccessToken write FAccessToken;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
  end;

implementation

constructor TIAConfiguracao.Create;
begin
  inherited Create;
  FApiBaseUrl := GetEnvironmentVariable('ERP_IA_API_URL');
  FAccessToken := GetEnvironmentVariable('ERP_IA_API_TOKEN');
  FTimeoutMs := 60000;
end;

procedure TIAConfiguracao.Validar;
begin
  if Trim(FApiBaseUrl) = '' then
    raise EInvalidOpException.Create(
      'Configure ERP_IA_API_URL com a URL da API corporativa.');
  if not SameText(Copy(FApiBaseUrl, 1, 8), 'https://') and
     not SameText(Copy(FApiBaseUrl, 1, 17), 'http://localhost') and
     not SameText(Copy(FApiBaseUrl, 1, 16), 'http://127.0.0.1') then
    raise EInvalidOpException.Create('A API deve utilizar HTTPS.');
  if FTimeoutMs <= 0 then
    raise EInvalidOpException.Create('Timeout invalido para a API de IA.');
end;

end.
