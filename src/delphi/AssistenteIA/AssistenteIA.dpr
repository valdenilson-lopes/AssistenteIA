program AssistenteIA;
uses
  Vcl.Forms,
  uFrmAssistenteIA in 'uFrmAssistenteIA.pas' {FrmAssistenteIA},
  uIATipos in 'uIATipos.pas',
  uIAContratos in 'uIAContratos.pas',
  uIAConfiguracao in 'uIAConfiguracao.pas',
  uIAApiClient in 'uIAApiClient.pas',
  uIAHistoricoMemoria in 'uIAHistoricoMemoria.pas',
  uIAConexaoERP in 'uIAConexaoERP.pas',
  uIAConsultasERP in 'uIAConsultasERP.pas',
  uIAOperacoesConhecidas in 'uIAOperacoesConhecidas.pas',
  Classe.Auxiliar in '..\..\..\..\bspac0000_util\XE5\Classe.Auxiliar.pas',
  Unt_Conexao in '..\..\..\..\bspac0000_util\XE5\Unt_Conexao.pas' {DM_CONEXAO: TDataModule},
  Unt_Util in '..\..\..\..\bspac0000_util\XE5\Unt_Util.pas',
  uResultado in '..\..\..\..\bspac0000_util\form\uResultado.pas' {frmResultado};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Assistente IA do ERP';
  Application.CreateForm(TDM_CONEXAO, DM_CONEXAO);
  Application.CreateForm(TFrmAssistenteIA, FrmAssistenteIA);
  Application.Run;
end.
