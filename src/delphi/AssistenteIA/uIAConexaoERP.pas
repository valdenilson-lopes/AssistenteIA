unit uIAConexaoERP;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client;

type
  EIAConexaoERP = class(Exception);

function ObterConexaoERP: TFDConnection;

implementation

uses
  Unt_Conexao;

function ObterConexaoERP: TFDConnection;
begin
  if not Assigned(DM_CONEXAO) then
    raise EIAConexaoERP.Create('O DataModule DM_CONEXAO ainda nao foi criado pelo ERP.');
  if not Assigned(DM_CONEXAO.FDConnection) then
    raise EIAConexaoERP.Create('DM_CONEXAO.FDConnection nao esta disponivel.');
  if not DM_CONEXAO.FDConnection.Connected then
    raise EIAConexaoERP.Create('A conexao FireDAC do ERP nao esta ativa.');
  Result := DM_CONEXAO.FDConnection;
end;

end.
