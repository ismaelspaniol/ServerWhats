program projWhats;

uses
  Vcl.Forms,
  uTInject.ConfigCEF,
  uMain in '..\fontes\uMain.pas' {frmMain},
  uMensagem in '..\fontes\uMensagem.pas';

{$R *.res}

begin
  If not GlobalCEFApp.StartMainProcess then
    Exit;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.


//program proj;
//
//uses
//  Vcl.Forms,
//  uTInject.ConfigCEF,
//  uMain in '..\uMain.pas' {Form1},
//  uDTOEnvioWhats in '..\uDTOEnvioWhats.pas';
//
//{$R *.res}
//
//begin
//  If not GlobalCEFApp.StartMainProcess then
//    Exit;
//
//  Application.Initialize;
//  Application.MainFormOnTaskbar := True;
//  Application.CreateForm(TForm1, Form1);
//  Application.Run;
//end.
