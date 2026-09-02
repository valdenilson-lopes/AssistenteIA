unit uIATipos;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TIAStatusResposta = (srRespondida, srConhecimentoInsuficiente,
    srForaDoEscopo, srErro);

  TIATipoFonte = (tfConhecimento, tfFerramenta, tfView);

  TIAContextoUsuario = class
  private
    FFiliaisPermitidas: TStringList;
  public
    CodigoUsuario: string;
    CodigoEmpresa: string;
    CodigoFilial: string;
    RotinaOrigem: string;
    VersaoERP: string;
    constructor Create;
    destructor Destroy; override;
    property FiliaisPermitidas: TStringList read FFiliaisPermitidas;
    procedure Validar;
  end;

  TIAFonte = class
  public
    Tipo: TIATipoFonte;
    Identificador: string;
    Titulo: string;
    Versao: string;
  end;

  TIAUso = class
  public
    Provider: string;
    Modelo: string;
    TokensEntrada: Int64;
    TokensSaida: Int64;
    LatenciaMs: Int64;
    Custo: Double;
    Moeda: string;
  end;

  TIARequisicao = class
  public
    IdRequisicao: string;
    IdConversa: string;
    Pergunta: string;
    Contexto: TIAContextoUsuario;
    IncluirFontes: Boolean;
    constructor Create;
  end;

  TIAResposta = class
  private
    FFontes: TObjectList<TIAFonte>;
  public
    IdRequisicao: string;
    IdConversa: string;
    Status: TIAStatusResposta;
    Resposta: string;
    ConhecimentoSuficiente: Boolean;
    AcaoSugerida: string;
    IdDemandaConhecimento: string;
    CodigoErro: string;
    MensagemErro: string;
    IdCorrelacao: string;
    Uso: TIAUso;
    constructor Create;
    destructor Destroy; override;
    property Fontes: TObjectList<TIAFonte> read FFontes;
  end;

  TIAPapelMensagem = (pmUsuario, pmAssistente, pmSistema);

  TIAMensagem = class
  public
    Papel: TIAPapelMensagem;
    Conteudo: string;
    CriadaEm: TDateTime;
  end;

  TIAConversa = class
  private
    FMensagens: TObjectList<TIAMensagem>;
  public
    Id: string;
    Titulo: string;
    CriadaEm: TDateTime;
    AtualizadaEm: TDateTime;
    constructor Create;
    destructor Destroy; override;
    property Mensagens: TObjectList<TIAMensagem> read FMensagens;
  end;

implementation

constructor TIAContextoUsuario.Create;
begin
  inherited Create;
  FFiliaisPermitidas := TStringList.Create;
  FFiliaisPermitidas.Sorted := True;
  FFiliaisPermitidas.Duplicates := dupIgnore;
end;

destructor TIAContextoUsuario.Destroy;
begin
  FFiliaisPermitidas.Free;
  inherited;
end;

procedure TIAContextoUsuario.Validar;
begin
  if Trim(CodigoUsuario) = '' then
    raise EArgumentException.Create('O codigo do usuario nao foi informado.');
  if Trim(CodigoEmpresa) = '' then
    raise EArgumentException.Create('A empresa nao foi informada.');
  if Trim(CodigoFilial) = '' then
    raise EArgumentException.Create('A filial nao foi informada.');
  if FFiliaisPermitidas.IndexOf(CodigoFilial) < 0 then
    raise EArgumentException.Create('A filial atual nao consta entre as filiais permitidas.');
  if Trim(VersaoERP) = '' then
    raise EArgumentException.Create('A versao do ERP nao foi informada.');
end;

constructor TIARequisicao.Create;
begin
  inherited Create;
  IncluirFontes := True;
end;

constructor TIAResposta.Create;
begin
  inherited Create;
  FFontes := TObjectList<TIAFonte>.Create(True);
  Uso := TIAUso.Create;
end;

destructor TIAResposta.Destroy;
begin
  Uso.Free;
  FFontes.Free;
  inherited;
end;

constructor TIAConversa.Create;
begin
  inherited Create;
  FMensagens := TObjectList<TIAMensagem>.Create(True);
  CriadaEm := Now;
  AtualizadaEm := CriadaEm;
end;

destructor TIAConversa.Destroy;
begin
  FMensagens.Free;
  inherited;
end;

end.
