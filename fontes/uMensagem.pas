unit uMensagem;

interface

type
  TMensagem = class
  private
    FcaminhoAnexo: String;
    Fmensagem: String;
    Ftelefone: String;
    FanexoBase64: String;
    FnomeArquivo: String;
    procedure SetcaminhoAnexo(const Value: String);
    procedure Setmensagem(const Value: String);
    procedure Settelefone(const Value: String);
    procedure SetanexoBase64(const Value: String);
    procedure SetnomeArquivo(const Value: String);
  public
    Constructor Create(vTelefone, vMensagem, vCaminhoAnexo, vAnexoBase64, vnomeArquivo : String);
    property telefone: String read Ftelefone write Settelefone;
    property mensagem: String read Fmensagem write Setmensagem;
    property caminhoAnexo: String read FcaminhoAnexo write SetcaminhoAnexo;
    property anexoBase64 : String read FanexoBase64 write SetanexoBase64;
    property nomeArquivo : String read FnomeArquivo write SetnomeArquivo;
  end;

implementation


{ TMensagem }

constructor TMensagem.Create(vTelefone, vMensagem, vCaminhoAnexo,vAnexoBase64, vnomeArquivo: String);
begin
  FcaminhoAnexo := vCaminhoAnexo;
  Fmensagem := vMensagem;
  Ftelefone := vTelefone;
  FanexoBase64 := vAnexoBase64;
  FnomeArquivo := vnomeArquivo;
end;

procedure TMensagem.SetanexoBase64(const Value: String);
begin
  FanexoBase64 := Value;
end;

procedure TMensagem.SetcaminhoAnexo(const Value: String);
begin
  FcaminhoAnexo := Value;
end;

procedure TMensagem.Setmensagem(const Value: String);
begin
  Fmensagem := Value;
end;

procedure TMensagem.SetnomeArquivo(const Value: String);
begin
  FnomeArquivo := Value;
end;

procedure TMensagem.Settelefone(const Value: String);
begin
  Ftelefone := Value;
end;

end.
