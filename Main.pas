unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, RxPlacemnt, System.ImageList, Vcl.ImgList, Vcl.Mask, RxToolEdit,
  ShellApi, RxCtrls,
  JclSysInfo, System.AnsiStrings,
  System.DateUtils;

const
  DBT_DEVICEREMOVECOMPLETE = $8004;
  DBT_DEVICEARRIVAL = $8000;

type
  TfrmMain = class(TForm)
    memo_ports_list: TMemo;
    Panel1: TPanel;
    btListAllPorts: TButton;
    edVID: TEdit;
    Label1: TLabel;
    edPID: TEdit;
    Label2: TLabel;
    edIntfNum: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    FormStorage: TFormStorage;
    btOpenTerminal: TButton;
    edCmdString: TButtonedEdit;
    Label5: TLabel;
    edPath: TFilenameEdit;
    edBaudrate: TEdit;
    Label6: TLabel;
    cbAutoOpen: TRxCheckBox;
    cbOpenAll: TRxCheckBox;
    procedure btListAllPortsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btOpenTerminalClick(Sender: TObject);
    procedure btnShowAllProcessesClick(Sender: TObject);
  private
    app_path: string;
    portname: string;
    portnum: Integer;
    procedure OpenTerminal(strl: TStringList);
    function Find_task(term_caption: string; wait: boolean): boolean;
    { Private declarations }
  public
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure ShowAllProcesses;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses USB_COM_enumeration;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  app_path := ExtractFilePath(Application.ExeName);
  FormStorage.IniFileName := app_path + 'vcomto.ini';
  FormStorage.Active := true;
end;

procedure TfrmMain.ShowAllProcesses;
begin
  GetTasksList(memo_ports_list.Lines);
  RunningProcessesList(memo_ports_list.Lines, true);
end;

procedure TfrmMain.btnShowAllProcessesClick(Sender: TObject);
begin
  ShowAllProcesses;
end;

procedure TfrmMain.btListAllPortsClick(Sender: TObject);
begin
  memo_ports_list.Lines.Clear;
  PopulateListWithPorts(memo_ports_list.Lines);
end;

function TfrmMain.Find_task(term_caption: string; wait: boolean): boolean;
var
  start: TDateTime;
  task_name: string;
  open_task_list: TStringList;
begin

  Find_task := false;
  open_task_list := TStringList.Create;
  try
    // ѕолучаем список названий окон всех работающих задач
    start := Now;
    repeat
      Application.ProcessMessages;

      if GetTasksList(open_task_list) = false then
      begin
        Application.ProcessMessages;
        GetTasksList(open_task_list);
      end;

      // »щем задачу с таким названием
      for task_name in open_task_list do
      begin
        // ≈сли задача с таким названием уже работает то пропускаем создание новой
        if AnsiContainsStr(task_name, term_caption) = true then
        begin
          Find_task := true;
          exit;
        end;
      end;
      if MilliSecondsBetween(Now, start) > 1000 then
      begin
        exit;
      end;
    until wait = false;

  finally
    open_task_list.Free;
  end;

end;

procedure TfrmMain.OpenTerminal(strl: TStringList);
var
  str: string;
  cmdstr: string;
  item: string;
  term_caption: string;

begin

  for item in strl do
  begin
    portname := item;
    str := Copy(portname, 4, portname.Length - 3);
    term_caption := 'Port: ' + str + '.  Baudrate: ' + edBaudrate.text + '.   ';

    if Find_task(term_caption, false) then
      continue;

    portnum := StrToInt(str);
    cmdstr := edCmdString.text;
    cmdstr := cmdstr + ' /BAUD=' + edBaudrate.text;
    cmdstr := cmdstr + ' /W="' + term_caption + '"';
    cmdstr := cmdstr + ' /C=' + IntToStr(portnum);
    ShellExecute(Handle, 'open', PChar(edPath.text), PChar(cmdstr), nil, SW_SHOWNORMAL);
    Find_task(term_caption, true); // ∆дем пока не по€витс€ задача с нашим названием

    if cbOpenAll.Checked = false then
      break;
  end;

end;

procedure TfrmMain.btOpenTerminalClick(Sender: TObject);
var
  VID, PID, MI: Integer;
  strl: TStringList;
begin
  VID := StrToInt('$' + edVID.text);
  PID := StrToInt('$' + edPID.text);
  MI := StrToInt('$' + edIntfNum.text);

  strl := TStringList.Create;
  EnumerateUsbCom(VID, PID, MI, strl);
  if strl.Count = 0 then
  begin
    Showmessage('Port not found!');
    exit;
  end;

  OpenTerminal(strl);
end;

procedure TfrmMain.WMDeviceChange(var Msg: TMessage);
var
  VID, PID, MI: Integer;
  strl: TStringList;
begin

  if (Msg.WParam = DBT_DEVICEREMOVECOMPLETE) or (Msg.WParam = DBT_DEVICEARRIVAL) then
  begin
    if cbAutoOpen.Checked then
    begin
      VID := StrToInt('$' + edVID.text);
      PID := StrToInt('$' + edPID.text);
      MI := StrToInt('$' + edIntfNum.text);
      strl := TStringList.Create;
      EnumerateUsbCom(VID, PID, MI, strl);
      OpenTerminal(strl);
    end;
  end;
  // RunningProcessesList
end;

end.
