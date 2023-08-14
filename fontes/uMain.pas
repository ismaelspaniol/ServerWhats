unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  System.Generics.Collections,uMensagem,


    //units adicionais obrigatorias
   uTInject.ConfigCEF, uTInject,            uTInject.Constant,      uTInject.JS,     uInjectDecryptFile,
   uTInject.Console,   uTInject.Diversos,   uTInject.AdjustNumber,  uTInject.Config, uTInject.Classes,


   System.NetEncoding, uDWAbout, uRESTDWBase, Vcl.AppEvnts, Horse

  ;

type
  TfrmMain = class(TForm)
    btnIniciarServidor: TSpeedButton;
    Image1: TImage;
    whatsOff: TImage;
    whatsOn: TImage;
    Label3: TLabel;
    lblStatus: TLabel;
    btnLogout: TSpeedButton;
    Rdb_FormaConexao: TRadioGroup;
    TInject1: TInject;
    CtiPrincipal: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnIniciarServidorClick(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure TInject1ErroAndWarning(Sender: TObject; const PError, PInfoAdc: string);
    procedure TInject1GetQrCode(const Sender: TObject; const QrCode: TResultQRCodeClass);
    procedure TInject1GetStatus(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CtiPrincipalDblClick(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
  private
    procedure HideApplication;
    function GetHandleOnTaskBar: THandle;
    procedure Stop;
    procedure Start;
    procedure horsePostEnvia(Req: THorseRequest; Res: THorseResponse);

  public

    function enviarMensagens(FMensagens : TObjectList<TMensagem>):String;
  end;

var
  frmMain: TfrmMain;

implementation
uses
  EncdDecd, IniFiles, IdCoder, IdCoderMIME,   System.Json, Rest.Json, Rest.JsonReflect;

{$R *.dfm}

{ TfrmMain }



procedure TfrmMain.ApplicationEvents1Minimize(Sender: TObject);
begin
  Hide();
  WindowState := wsMinimized;

  { Show the animated tray icon and also a hint balloon. }
  CtiPrincipal.Visible := True;
  CtiPrincipal.Animate := True;
  CtiPrincipal.ShowBalloonHint;
end;

procedure TfrmMain.btnIniciarServidorClick(Sender: TObject);
begin
  try
    if not TInject1.Auth(false) then
    Begin
      TInject1.FormQrCodeType := TFormQrCodeType(Rdb_FormaConexao.ItemIndex);
      TInject1.FormQrCodeStart;
    End;

    if not TInject1.FormQrCodeShowing then
       TInject1.FormQrCodeShowing := True;

  except on e : Exception do
  begin
    showMessage('Erro: '+e.Message);
  end;

  end;


end;

procedure TfrmMain.btnLogoutClick(Sender: TObject);
begin
 if not TInject1.auth then
    exit;

   TInject1.Logtout;
   TInject1.Disconnect;
end;

function TfrmMain.enviarMensagens(FMensagens : TObjectList<TMensagem>): String;
var
 i : Integer;
  lThread     : TThread;
  LStream     : TMemoryStream;
  LBase64File : TBase64Encoding;
  LExtension  : String;
  LBase64     : String;
begin
  try
    if not TInject1.Auth then
    Exit;

    for i := 0 to FMensagens.Count -1 do
    begin
      if ((FMensagens[i].telefone <> EmptyStr) and (FMensagens[i].mensagem <> EmptyStr)) then
      begin

        if ((FMensagens[i].caminhoAnexo = EmptyStr) and (FMensagens[i].anexoBase64 = EmptyStr)) then
        begin
          TInject1.send(FMensagens[i].telefone, FMensagens[i].mensagem);
        end
        else
        begin
          if not (FMensagens[i].caminhoAnexo = EmptyStr) then
          begin

            TInject1.SendFile(FMensagens[i].telefone, FMensagens[i].caminhoAnexo ,FMensagens[i].mensagem   );
          end
          else
          if not (FMensagens[i].anexoBase64 = EmptyStr) then
          begin
            LBase64 := FMensagens[i].anexoBase64;
            LBase64 := StrExtFile_Base64Type( FMensagens[i].nomeArquivo) +LBase64 ;
            TInject1.SendBase64(LBase64,FMensagens[i].telefone,FMensagens[i].nomeArquivo,FMensagens[i].mensagem);
            if FMensagens[i].mensagem <> EmptyStr then
               TInject1.send(FMensagens[i].telefone, FMensagens[i].mensagem);



          end;
        end;
      end;
    end;

  finally
    FMensagens.Free;
  end;

end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 TInject1.ShutDown;


  if THorse.IsRunning then
    Stop;
end;
procedure TfrmMain.Stop;
begin
  THorse.StopListen;
end;

procedure TfrmMain.Start;
var
  ini : TIniFile;
  porta : String;
begin
  try
    Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    porta    := ini.ReadString('Config', 'porta', '8082');
  finally
    ini.free;

  end;

  THorse.Listen(strToInt(porta));
end;

procedure TfrmMain.horsePostEnvia(Req: THorseRequest; Res: THorseResponse);
var
     json, telefone, teste, decodedMensagem, decodedCaminho, decodedNomeArquivo : String;
     ja:TJSONArray;
     jv:TJsonValue;
     Mensagens : TObjectList<TMensagem>;
begin
  decodedMensagem := '';
    decodedCaminho := '';
    decodedNomeArquivo := '';

    json :=Req.Body;

    ja := TJSONObject.ParseJSONValue(json) as TJSONArray;
    Mensagens := TObjectList<TMensagem>.Create;

    for jv in ja do
    begin
      if(jv.GetValue<string>('mensagem') <> '') then
      begin
        decodedMensagem := DecodeString(jv.GetValue<string>('mensagem'))

      end
      else decodedMensagem := '';

      if (jv.GetValue<string>('caminho_arquivo') <> '') then
      begin
        decodedCaminho := DecodeString(jv.GetValue<string>('caminho_arquivo'));
      end
      else decodedCaminho := '';

      if (jv.GetValue<string>('nome_arquivo') <> '') then
      begin
        decodedNomeArquivo := DecodeString(jv.GetValue<string>('nome_arquivo'));
      end
      else decodedNomeArquivo := '';


      Mensagens.Add(TMensagem.Create('55'+jv.GetValue<string>('telefone')+'@c.us',
                                     decodedMensagem,
                                     decodedCaminho,
                                     jv.GetValue<string>('arquivo_base64'),
                                     decodedNomeArquivo
                                     ));

    end;

    frmMain.enviarMensagens(Mensagens);

end;

procedure TfrmMain.FormCreate(Sender: TObject);

begin
  btnIniciarServidor.Click;


  start();

  THorse.Post('envia',horsePostEnvia);

end;

procedure TfrmMain.TInject1ErroAndWarning(Sender: TObject; const PError, PInfoAdc: string);
begin
showMessage(PError+PInfoAdc);
end;

procedure TfrmMain.TInject1GetQrCode(const Sender: TObject; const QrCode: TResultQRCodeClass);
begin
  if TInject1.FormQrCodeType = TFormQrCodeType(Ft_none) then
     Image1.Picture := QrCode.AQrCodeImage else
     Image1.Picture := nil; //Limpa foto
end;

procedure TfrmMain.TInject1GetStatus(Sender: TObject);
begin
if not Assigned(Sender) Then
     Exit;
   if (TInject(Sender).Status = Inject_Initialized) then
  begin
    lblStatus.Caption            := 'Online';
    lblStatus.Font.Color         := $0000AE11;
    btnLogout.Enabled              := true;
  end else
  begin
    btnLogout.Enabled              := false;
    lblStatus.Caption            := 'Offline';
    lblStatus.Font.Color         := $002894FF;
  end;

//    (TInject(Sender).Status = Inject_Initialized);;
  whatsOn.Visible            := btnLogout.enabled;
  whatsOff.Visible           := Not whatsOn.Visible;

  case TInject(Sender).status of
    Server_ConnectedDown       : Label3.Caption := TInject(Sender).StatusToStr;
    Server_Disconnected        : Label3.Caption := TInject(Sender).StatusToStr;
    Server_Disconnecting       : Label3.Caption := TInject(Sender).StatusToStr;
    Server_Connected           : Label3.Caption := '';
    Server_Connecting          : Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Initializing        : Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Initialized         : Label3.Caption := TInject(Sender).StatusToStr;
    Server_ConnectingNoPhone   : Label3.Caption := TInject(Sender).StatusToStr;
    Server_ConnectingReaderCode: Label3.Caption := TInject(Sender).StatusToStr;
    Server_TimeOut             : Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Destroying          : Label3.Caption := TInject(Sender).StatusToStr;
    Inject_Destroy             : Label3.Caption := TInject(Sender).StatusToStr;
  end;
  If Label3.Caption <> '' Then
     Label3.Visible := true;


  If TInject(Sender).Status in [Server_ConnectingNoPhone, Server_TimeOut] Then
  Begin
    if TInject(Sender).FormQrCodeType = Ft_Desktop then
    Begin
       if TInject(Sender).Status = Server_ConnectingNoPhone then
          TInject1.FormQrCodeStop;
    end else
    Begin
      if TInject(Sender).Status = Server_ConnectingNoPhone then
      Begin
        if not TInject(Sender).FormQrCodeShowing then
           TInject(Sender).FormQrCodeShowing := True;
      end else
      begin
        TInject(Sender).FormQrCodeReloader;
      end;
    end;
  end;

   if lblStatus.Caption = 'Online' then
   begin
     HideApplication;
   end;
end;

procedure TfrmMain.CtiPrincipalDblClick(Sender: TObject);
begin
  CtiPrincipal.Visible     := False;
  Application.ShowMainForm := True;
  If Self <> Nil Then
  Begin
    Self.Visible     := True;
    Self.WindowState := WsNormal;
  End;
  ShowWindow(GetHandleOnTaskBar, SW_SHOW);

end;




procedure TfrmMain.HideApplication;
Begin
  CtiPrincipal.Visible     := True;
  Application.ShowMainForm := False;
  If Self <> Nil Then
    Self.Visible := False;
  Application.Minimize;
  ShowWindow(GetHandleOnTaskBar, SW_HIDE);

End;


Function TfrmMain.GetHandleOnTaskBar: THandle;
Begin
 {$IFDEF COMPILER11_UP}
 If Application.MainFormOnTaskBar And Assigned(Application.MainForm) Then
  Result := Application.MainForm.Handle
 Else
 {$ENDIF COMPILER11_UP}
  Result := Application.Handle;
End;

end.
