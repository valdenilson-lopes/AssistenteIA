unit uIAContextoAmbiente;

interface

uses
  System.SysUtils,
  System.Classes,
  uIATipos,
  uIAContratos;

type
  { Adaptador provisorio para o projeto isolado. No ERP, substituir por uma
    implementacao que leia sessao, permissoes e filiais autorizadas reais. }
  TIAContextoAmbiente = class(TInterfacedObject, IIAContextoProvider)
  public
    function CriarContextoAtual: TIAContextoUsuario;
  end;

implementation

function TIAContextoAmbiente.CriarContextoAtual: TIAContextoUsuario;
var
  Filiais: TStringList;
  I: Integer;
begin
  Result := TIAContextoUsuario.Create;
  try
    Result.CodigoUsuario := GetEnvironmentVariable('ERP_COD_USUARIO');
    Result.CodigoEmpresa := GetEnvironmentVariable('ERP_COD_EMPRESA');
    Result.CodigoFilial := GetEnvironmentVariable('ERP_COD_FILIAL');
    Result.RotinaOrigem := GetEnvironmentVariable('ERP_ROTINA_ORIGEM');
    Result.VersaoERP := GetEnvironmentVariable('ERP_VERSAO');
    Filiais := TStringList.Create;
    try
      Filiais.StrictDelimiter := True;
      Filiais.Delimiter := ',';
      Filiais.DelimitedText := GetEnvironmentVariable('ERP_FILIAIS_PERMITIDAS');
      for I := 0 to Filiais.Count - 1 do
        if Trim(Filiais[I]) <> '' then
          Result.FiliaisPermitidas.Add(Trim(Filiais[I]));
    finally
      Filiais.Free;
    end;
    Result.Validar;
  except
    Result.Free;
    raise;
  end;
end;

end.
