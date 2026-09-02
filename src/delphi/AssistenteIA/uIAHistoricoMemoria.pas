unit uIAHistoricoMemoria;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  uIATipos,
  uIAContratos;

type
  { Implementacao transitoria. O contrato permite trocar por persistencia do
    ERP sem alterar a tela ou o servico de IA. }
  TIARepositorioHistoricoMemoria = class(TInterfacedObject, IIARepositorioHistorico)
  private
    FConversas: TObjectDictionary<string, TIAConversa>;
    function Clonar(const AConversa: TIAConversa): TIAConversa;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Salvar(const AConversa: TIAConversa);
    function Carregar(const AIdConversa: string): TIAConversa;
    procedure Arquivar(const AIdConversa: string);
  end;

implementation

constructor TIARepositorioHistoricoMemoria.Create;
begin
  inherited Create;
  FConversas := TObjectDictionary<string, TIAConversa>.Create([doOwnsValues]);
end;

destructor TIARepositorioHistoricoMemoria.Destroy;
begin
  FConversas.Free;
  inherited;
end;

function TIARepositorioHistoricoMemoria.Clonar(
  const AConversa: TIAConversa): TIAConversa;
var
  Origem, Destino: TIAMensagem;
begin
  Result := TIAConversa.Create;
  Result.Id := AConversa.Id;
  Result.Titulo := AConversa.Titulo;
  Result.CriadaEm := AConversa.CriadaEm;
  Result.AtualizadaEm := AConversa.AtualizadaEm;
  for Origem in AConversa.Mensagens do
  begin
    Destino := TIAMensagem.Create;
    Destino.Papel := Origem.Papel;
    Destino.Conteudo := Origem.Conteudo;
    Destino.CriadaEm := Origem.CriadaEm;
    Result.Mensagens.Add(Destino);
  end;
end;

procedure TIARepositorioHistoricoMemoria.Salvar(const AConversa: TIAConversa);
begin
  if Trim(AConversa.Id) = '' then
    Exit;
  FConversas.AddOrSetValue(AConversa.Id, Clonar(AConversa));
end;

function TIARepositorioHistoricoMemoria.Carregar(
  const AIdConversa: string): TIAConversa;
var
  Conversa: TIAConversa;
begin
  if FConversas.TryGetValue(AIdConversa, Conversa) then
    Result := Clonar(Conversa)
  else
    Result := nil;
end;

procedure TIARepositorioHistoricoMemoria.Arquivar(const AIdConversa: string);
begin
  FConversas.Remove(AIdConversa);
end;

end.
