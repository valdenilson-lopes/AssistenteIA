unit uIAContratos;

interface

uses
  uIATipos;

type
  IIAContextoProvider = interface
    ['{D1076ED8-3858-457C-97D4-1D429FBE470E}']
    function CriarContextoAtual: TIAContextoUsuario;
  end;

  IIAAssistenteService = interface
    ['{E0574CD0-BEED-45E7-87CE-993296ED4F4C}']
    function Perguntar(const ARequisicao: TIARequisicao): TIAResposta;
  end;

  IIAConhecimentoERP = interface
    ['{2F905216-B153-4F64-9B04-50B1AC03227A}']
    function Buscar(const APergunta, AModulo: string;
      const ALimiteTrechos, ALimiteCaracteres: Integer): string;
    function RegistrarDemanda(const APergunta, AModuloProvavel,
      AAssuntoProvavel, AIdConversa: string): string;
  end;

  IIAFerramenta = interface
    ['{971D2257-F999-44F0-AB77-C04407E9F2F2}']
    function Nome: string;
    function Descricao: string;
    function ExecutarSomenteLeitura(const AParametrosJson: string;
      const AContexto: TIAContextoUsuario): string;
  end;

  IIARepositorioHistorico = interface
    ['{9EED37D0-6047-4D97-A57D-23BA7D8B60E5}']
    procedure Salvar(const AConversa: TIAConversa);
    function Carregar(const AIdConversa: string): TIAConversa;
    procedure Arquivar(const AIdConversa: string);
  end;

implementation

end.
