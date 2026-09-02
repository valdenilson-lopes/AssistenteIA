unit uIAConsultasERP;

interface

uses
  System.SysUtils,
  System.JSON;

type
  EIAConsultaERP = class(Exception);

  TIAConsultasERP = class
  private
    class function ColunasAutorizadas(const AView: string): string; static;
    class function ColunaFilial(const AView: string): string; static;
  public
    class function ConsultarView(const AView, ACodigoFilial: string;
      const ALimite: Integer = 100): TJSONArray; static;
    class function ViewsAutorizadas: TArray<string>; static;
  end;

implementation

uses
  System.Variants,
  Data.DB,
  FireDAC.Comp.Client,
  uIAConexaoERP;

class function TIAConsultasERP.ViewsAutorizadas: TArray<string>;
begin
  SetLength(Result, 5);
  Result[0] := 'BI_VENDA_FLYGESTOR';
  Result[1] := 'BI_FINANCEIRO_FLYGESTOR';
  Result[2] := 'BI_ESTOQUE_FLYGESTOR';
  Result[3] := 'CPAGAS_12MESES';
  Result[4] := 'SITEMERCADO_PRODUTO';
end;

class function TIAConsultasERP.ColunasAutorizadas(const AView: string): string;
begin
  if SameText(AView, 'BI_VENDA_FLYGESTOR') then
    Exit('DATAMOVIMENTO,CODFILIAL,CODLOCAL,LOCAL,TIPOMOVIMENTO,' +
      'IDVENDEDOR,VENDEDOR,IDFABRICANTE,FABRICANTE,IDGRUPO,GRUPO,' +
      'CODPRODUTO,PRODUTO,QTITENSVENDA,VRVENDA,VROPERACAO,IDMOV,TOTMOV');
  if SameText(AView, 'BI_FINANCEIRO_FLYGESTOR') then
    Exit('DATAVENCIMENTO,DATABAIXA,SITUACAOCPR,TIPOCPR,CODFILIAL,' +
      'TIPODOC,PORTADOR,PLANOCONTA,MEIOPAG,CONDPAG,TOTNOMINAL,' +
      'TOTPREVISTO,TOTREALIZADO,IDMOV,IDCPR');
  if SameText(AView, 'BI_ESTOQUE_FLYGESTOR') then
    Exit('CODFILIAL,CODLOCAL,LOCAL,CODFABR,FABRICANTE,CODGRUPO,GRUPO,' +
      'CODPRODUTO,PRODUTO,CODNCM,TIPOPROD,SDOFISICO,SDOFINANC,' +
      'SDOPEDIDOFOR,CUSTOCOMPRA,PRECOVENDA,UNIDADE');
  if SameText(AView, 'CPAGAS_12MESES') then
    Exit('MES,ANO,CODGRUPO,CODCONTA,CONTA,CODFILIAL,CONTAS_PAGAS');
  if SameText(AView, 'SITEMERCADO_PRODUTO') then
    Exit('ID_LOJA,DEPARTAMENTO,CATEGORIA,SUBCATEGORIA,MARCA,UNIDADE,' +
      'VOLUME,CODIGO_BARRA,NOME,VLR_PRODUTO,VLR_PROMOCAO,' +
      'QTD_ESTOQUE_ATUAL,QTD_ESTOQUE_MINIMO,ATIVO,VLR_ATACADO,QTD_ATACADO');
  raise EIAConsultaERP.Create('View nao autorizada para a Plataforma de IA: ' + AView);
end;

class function TIAConsultasERP.ColunaFilial(const AView: string): string;
begin
  if SameText(AView, 'SITEMERCADO_PRODUTO') then
    Exit('ID_LOJA');
  if SameText(AView, 'BI_VENDA_FLYGESTOR') or
     SameText(AView, 'BI_FINANCEIRO_FLYGESTOR') or
     SameText(AView, 'BI_ESTOQUE_FLYGESTOR') or
     SameText(AView, 'CPAGAS_12MESES') then
    Exit('CODFILIAL');
  raise EIAConsultaERP.Create('A View nao possui coluna de filial autorizada.');
end;

class function TIAConsultasERP.ConsultarView(const AView,
  ACodigoFilial: string; const ALimite: Integer): TJSONArray;
var
  Query: TFDQuery;
  Registro: TJSONObject;
  Campo: TField;
  LimiteSeguro: Integer;
  I: Integer;
begin
  if Trim(ACodigoFilial) = '' then
    raise EIAConsultaERP.Create('O codigo da filial e obrigatorio.');
  LimiteSeguro := ALimite;
  if LimiteSeguro < 1 then
    LimiteSeguro := 1;
  if LimiteSeguro > 200 then
    LimiteSeguro := 200;

  Result := TJSONArray.Create;
  Query := TFDQuery.Create(nil);
  try
    try
      Query.Connection := ObterConexaoERP;
      Query.FetchOptions.RecsMax := LimiteSeguro;
      Query.ResourceOptions.CmdExecTimeout := 15000;
      Query.SQL.Text := 'SELECT ' + ColunasAutorizadas(AView) +
        ' FROM ' + UpperCase(AView) +
        ' WHERE ' + ColunaFilial(AView) + ' = :CODFILIAL_IA' +
        ' AND ROWNUM <= :LIMITE_IA';
      Query.ParamByName('CODFILIAL_IA').AsString := ACodigoFilial;
      Query.ParamByName('LIMITE_IA').AsInteger := LimiteSeguro;
      Query.Open;
      while not Query.Eof do
      begin
        Registro := TJSONObject.Create;
        for I := 0 to Query.FieldCount - 1 do
        begin
          Campo := Query.Fields[I];
          if Campo.IsNull then
            Registro.AddPair(Campo.FieldName, TJSONNull.Create)
          else
            case Campo.DataType of
              ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc,
              ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftSingle, ftExtended:
                Registro.AddPair(Campo.FieldName,
                  TJSONNumber.Create(StringReplace(Campo.AsString, ',', '.', [rfReplaceAll])));
              ftDate, ftTime, ftDateTime, ftTimeStamp:
                Registro.AddPair(Campo.FieldName,
                  FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Campo.AsDateTime));
            else
              Registro.AddPair(Campo.FieldName, Campo.AsString);
            end;
        end;
        Result.AddElement(Registro);
        Query.Next;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

end.
