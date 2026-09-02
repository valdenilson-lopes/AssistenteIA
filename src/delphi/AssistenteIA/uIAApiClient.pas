unit uIAApiClient;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.Net.URLClient,
  System.Net.HttpClient,
  uIATipos,
  uIAContratos,
  uIAConfiguracao;

type
  EIAApiError = class(Exception)
  private
    FStatusCode: Integer;
  public
    constructor Create(const AMensagem: string; const AStatusCode: Integer);
    property StatusCode: Integer read FStatusCode;
  end;

  TIAApiClient = class(TInterfacedObject, IIAAssistenteService)
  private
    FConfiguracao: TIAConfiguracao;
    function CriarJson(const ARequisicao: TIARequisicao): TJSONObject;
    function LerResposta(const AJson: string): TIAResposta;
  public
    constructor Create(const AConfiguracao: TIAConfiguracao);
    function Perguntar(const ARequisicao: TIARequisicao): TIAResposta;
  end;

implementation

function SemBarraFinal(const AUrl: string): string;
begin
  Result := Trim(AUrl);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function JsonTexto(const AObjeto: TJSONObject; const ANome: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  V := AObjeto.GetValue(ANome);
  if (V <> nil) and not (V is TJSONNull) then
    Result := V.Value;
end;

function JsonBooleano(const AObjeto: TJSONObject; const ANome: string): Boolean;
var
  V: TJSONValue;
begin
  V := AObjeto.GetValue(ANome);
  Result := (V <> nil) and SameText(V.Value, 'true');
end;

constructor EIAApiError.Create(const AMensagem: string; const AStatusCode: Integer);
begin
  inherited Create(AMensagem);
  FStatusCode := AStatusCode;
end;

constructor TIAApiClient.Create(const AConfiguracao: TIAConfiguracao);
begin
  inherited Create;
  FConfiguracao := AConfiguracao;
end;

function TIAApiClient.CriarJson(const ARequisicao: TIARequisicao): TJSONObject;
var
  Contexto: TJSONObject;
  Filiais: TJSONArray;
  I: Integer;
begin
  ARequisicao.Contexto.Validar;
  Contexto := TJSONObject.Create;
  Filiais := TJSONArray.Create;
  for I := 0 to ARequisicao.Contexto.FiliaisPermitidas.Count - 1 do
    Filiais.Add(ARequisicao.Contexto.FiliaisPermitidas[I]);
  Contexto.AddPair('user_code', ARequisicao.Contexto.CodigoUsuario);
  Contexto.AddPair('company_code', ARequisicao.Contexto.CodigoEmpresa);
  Contexto.AddPair('branch_code', ARequisicao.Contexto.CodigoFilial);
  Contexto.AddPair('allowed_branch_codes', Filiais);
  Contexto.AddPair('origin_routine', ARequisicao.Contexto.RotinaOrigem);
  Contexto.AddPair('erp_version', ARequisicao.Contexto.VersaoERP);

  Result := TJSONObject.Create;
  Result.AddPair('request_id', ARequisicao.IdRequisicao);
  if ARequisicao.IdConversa <> '' then
    Result.AddPair('conversation_id', ARequisicao.IdConversa)
  else
    Result.AddPair('conversation_id', TJSONNull.Create);
  Result.AddPair('question', ARequisicao.Pergunta);
  Result.AddPair('context', Contexto);
  Result.AddPair('include_sources', TJSONBool.Create(ARequisicao.IncluirFontes));
end;

function TIAApiClient.Perguntar(const ARequisicao: TIARequisicao): TIAResposta;
var
  Cliente: THTTPClient;
  Corpo: TJSONObject;
  Stream: TStringStream;
  HttpResposta: IHTTPResponse;
  Headers: TNetHeaders;
  Url: string;
begin
  FConfiguracao.Validar;
  Corpo := CriarJson(ARequisicao);
  Cliente := THTTPClient.Create;
  try
    Cliente.ConnectionTimeout := FConfiguracao.TimeoutMs;
    Cliente.ResponseTimeout := FConfiguracao.TimeoutMs;
    SetLength(Headers, 2);
    Headers[0] := TNetHeader.Create('Content-Type', 'application/json; charset=utf-8');
    Headers[1] := TNetHeader.Create('Accept', 'application/json');
    SetLength(Headers, 5);
    Headers[2] := TNetHeader.Create('X-ERP-User', ARequisicao.Contexto.CodigoUsuario);
    Headers[3] := TNetHeader.Create('X-ERP-Company', ARequisicao.Contexto.CodigoEmpresa);
    Headers[4] := TNetHeader.Create('X-ERP-Branch', ARequisicao.Contexto.CodigoFilial);
    if FConfiguracao.AccessToken <> '' then
    begin
      SetLength(Headers, 6);
      Headers[5] := TNetHeader.Create('Authorization',
        'Bearer ' + FConfiguracao.AccessToken);
    end;
    Stream := TStringStream.Create(Corpo.ToJSON, TEncoding.UTF8);
    try
      Url := SemBarraFinal(FConfiguracao.ApiBaseUrl) + '/ia/perguntar';
      HttpResposta := Cliente.Post(Url, Stream, nil, Headers);
      if (HttpResposta.StatusCode < 200) or (HttpResposta.StatusCode >= 300) then
        raise EIAApiError.Create('A API de IA recusou a solicitacao. Codigo HTTP ' +
          IntToStr(HttpResposta.StatusCode) + '.', HttpResposta.StatusCode);
      Result := LerResposta(HttpResposta.ContentAsString(TEncoding.UTF8));
    finally
      Stream.Free;
    end;
  finally
    Cliente.Free;
    Corpo.Free;
  end;
end;

function TIAApiClient.LerResposta(const AJson: string): TIAResposta;
var
  Raiz, FonteObj, ErroObj: TJSONObject;
  Valor, CampoJson: TJSONValue;
  Fontes: TJSONArray;
  Fonte: TIAFonte;
  I: Integer;
  Status: string;
begin
  Valor := TJSONObject.ParseJSONValue(AJson);
  if not (Valor is TJSONObject) then
  begin
    Valor.Free;
    raise EIAApiError.Create('A API retornou JSON invalido.', 0);
  end;
  Raiz := TJSONObject(Valor);
  Result := TIAResposta.Create;
  try
    Result.IdRequisicao := JsonTexto(Raiz, 'request_id');
    Result.IdConversa := JsonTexto(Raiz, 'conversation_id');
    Result.Resposta := JsonTexto(Raiz, 'answer');
    Result.ConhecimentoSuficiente := JsonBooleano(Raiz, 'knowledge_sufficient');
    Result.AcaoSugerida := JsonTexto(Raiz, 'suggested_action');
    Result.IdDemandaConhecimento := JsonTexto(Raiz, 'knowledge_request_id');
    Status := JsonTexto(Raiz, 'status');
    if Status = 'answered' then Result.Status := srRespondida
    else if Status = 'knowledge_insufficient' then Result.Status := srConhecimentoInsuficiente
    else if Status = 'refused_out_of_scope' then Result.Status := srForaDoEscopo
    else Result.Status := srErro;

    Fontes := nil;
    CampoJson := Raiz.GetValue('sources');
    if CampoJson is TJSONArray then
      Fontes := TJSONArray(CampoJson);
    if Fontes <> nil then
      for I := 0 to Fontes.Count - 1 do
        if Fontes.Items[I] is TJSONObject then
        begin
          FonteObj := TJSONObject(Fontes.Items[I]);
          Fonte := TIAFonte.Create;
          Fonte.Identificador := JsonTexto(FonteObj, 'source_id');
          Fonte.Titulo := JsonTexto(FonteObj, 'title');
          Fonte.Versao := JsonTexto(FonteObj, 'version');
          Status := JsonTexto(FonteObj, 'source_type');
          if Status = 'tool' then Fonte.Tipo := tfFerramenta
          else if Status = 'view' then Fonte.Tipo := tfView
          else Fonte.Tipo := tfConhecimento;
          Result.Fontes.Add(Fonte);
        end;

    ErroObj := nil;
    CampoJson := Raiz.GetValue('error');
    if CampoJson is TJSONObject then
      ErroObj := TJSONObject(CampoJson);
    if ErroObj <> nil then
    begin
      Result.CodigoErro := JsonTexto(ErroObj, 'code');
      Result.MensagemErro := JsonTexto(ErroObj, 'user_message');
      Result.IdCorrelacao := JsonTexto(ErroObj, 'correlation_id');
    end;
  except
    Result.Free;
    raise;
  end;
  Raiz.Free;
end;

end.
