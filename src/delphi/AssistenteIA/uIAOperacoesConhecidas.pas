unit uIAOperacoesConhecidas;

interface

uses
  System.SysUtils;

type
  TIAOperacoesConhecidas = class
  public
    class function TentarExecutar(const APergunta, AFilial: string;
      out AResposta: string): Boolean; static;
  end;

implementation

uses
  FireDAC.Comp.Client,
  uIAConexaoERP;

function TextoNormalizado(const ATexto: string): string;
begin
  Result := AnsiLowerCase(Trim(ATexto));
end;

function NovaQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := ObterConexaoERP;
  Result.ResourceOptions.CmdExecTimeout := 15000;
end;

function ConsultarVendasHoje(const AFilial: string): string;
var
  Q: TFDQuery;
  Total: Currency;
begin
  Q := NovaQuery;
  try
    Q.SQL.Text :=
      'SELECT TIPOMOVIMENTO, COUNT(DISTINCT IDMOV) QT_MOVIMENTOS, ' +
      'NVL(SUM(VRVENDA),0) TOTAL FROM BI_VENDA_FLYGESTOR ' +
      'WHERE CODFILIAL=:FILIAL AND DATAMOVIMENTO>=TRUNC(SYSDATE) ' +
      'AND DATAMOVIMENTO<TRUNC(SYSDATE)+1 ' +
      'GROUP BY TIPOMOVIMENTO ORDER BY TIPOMOVIMENTO';
    Q.ParamByName('FILIAL').AsString := AFilial;
    Q.Open;
    Result := 'Movimentos de hoje na filial ' + AFilial + ':';
    Total := 0;
    if Q.IsEmpty then
      Exit(Result + sLineBreak + '- Nenhum movimento encontrado.');
    while not Q.Eof do
    begin
      Result := Result + sLineBreak + '- ' + Q.FieldByName('TIPOMOVIMENTO').AsString +
        ': ' + Q.FieldByName('QT_MOVIMENTOS').AsString + ' movimento(s), R$ ' +
        FormatFloat('#,##0.00', Q.FieldByName('TOTAL').AsCurrency);
      Total := Total + Q.FieldByName('TOTAL').AsCurrency;
      Q.Next;
    end;
    Result := Result + sLineBreak + 'Total de todas as classificacoes: R$ ' +
      FormatFloat('#,##0.00', Total) + sLineBreak +
      'Observacao: inclui todas as classificacoes acima; nao representa venda ' +
      'liquida ate a regra comercial ser aprovada.';
  finally
    Q.Free;
  end;
end;

function ConsultarReceberVencido(const AFilial: string): string;
var
  Q: TFDQuery;
begin
  Q := NovaQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) QT_TITULOS, ' +
      'NVL(SUM(NVL(TOTPREVISTO,0)-NVL(TOTREALIZADO,0)),0) SALDO ' +
      'FROM BI_FINANCEIRO_FLYGESTOR WHERE CODFILIAL=:FILIAL ' +
      'AND TIPOCPR=''receber'' AND SITUACAOCPR=''EM ABERTO'' ' +
      'AND DATAVENCIMENTO<TRUNC(SYSDATE)';
    Q.ParamByName('FILIAL').AsString := AFilial;
    Q.Open;
    Result := 'Contas a receber vencidas na filial ' + AFilial + ': ' +
      Q.FieldByName('QT_TITULOS').AsString + ' titulo(s), saldo de R$ ' +
      FormatFloat('#,##0.00', Q.FieldByName('SALDO').AsCurrency) + '.' +
      sLineBreak + 'Criterio: receber, em aberto, vencimento anterior a hoje; ' +
      'saldo = previsto menos realizado.';
  finally
    Q.Free;
  end;
end;

function ConsultarEstoqueBaixo(const AFilial: string): string;
var
  Q: TFDQuery;
begin
  Q := NovaQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) QT_PRODUTOS FROM SITEMERCADO_PRODUTO ' +
      'WHERE ID_LOJA=:FILIAL AND ATIVO=''S'' ' +
      'AND QTD_ESTOQUE_ATUAL<QTD_ESTOQUE_MINIMO';
    Q.ParamByName('FILIAL').AsString := AFilial;
    Q.Open;
    Result := 'A filial ' + AFilial + ' possui ' +
      Q.FieldByName('QT_PRODUTOS').AsString +
      ' produto(s) ativo(s) abaixo do estoque minimo.';
  finally
    Q.Free;
  end;
end;

class function TIAOperacoesConhecidas.TentarExecutar(const APergunta,
  AFilial: string; out AResposta: string): Boolean;
var
  Texto: string;
begin
  Texto := TextoNormalizado(APergunta);
  Result := ((Pos('venda', Texto) > 0) or (Pos('vendemos', Texto) > 0)) and
    (Pos('hoje', Texto) > 0);
  if Result then
  begin
    AResposta := ConsultarVendasHoje(AFilial);
    Exit;
  end;
  Result := (Pos('receber', Texto) > 0) and (Pos('vencid', Texto) > 0);
  if Result then
  begin
    AResposta := ConsultarReceberVencido(AFilial);
    Exit;
  end;
  Result := (Pos('estoque', Texto) > 0) and
    ((Pos('baixo', Texto) > 0) or (Pos('minimo', Texto) > 0));
  if Result then
    AResposta := ConsultarEstoqueBaixo(AFilial);
end;

end.
