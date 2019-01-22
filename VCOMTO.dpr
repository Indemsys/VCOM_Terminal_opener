program VCOMTO;

uses
  Vcl.Forms,
  Main in 'Main.pas' {frmMain},
  JvSetupApi in 'JVCL\JvSetupApi.pas',
  ModuleLoader in 'JVCL\ModuleLoader.pas',
  WinConvTypes in 'JVCL\WinConvTypes.pas',
  USB_COM_enumeration in 'USB_COM_enumeration.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  LoadSetupApi;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
