object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'VCOMTO'
  ClientHeight = 419
  ClientWidth = 639
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object memo_ports_list: TMemo
    Left = 0
    Top = 0
    Width = 639
    Height = 143
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 143
    Width = 639
    Height = 276
    Align = alBottom
    TabOrder = 1
    DesignSize = (
      639
      276)
    object Label1: TLabel
      Left = 512
      Top = 10
      Width = 38
      Height = 23
      Anchors = [akRight, akBottom]
      Caption = 'VID:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 59
    end
    object Label2: TLabel
      Left = 512
      Top = 46
      Width = 37
      Height = 23
      Anchors = [akRight, akBottom]
      Caption = 'PID:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 95
    end
    object Label3: TLabel
      Left = 395
      Top = 82
      Width = 155
      Height = 23
      Alignment = taRightJustify
      Anchors = [akRight, akBottom]
      Caption = 'Interface number:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 131
    end
    object Label4: TLabel
      Left = 12
      Top = 101
      Width = 171
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Terminal program path:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 150
    end
    object Label5: TLabel
      Left = 12
      Top = 169
      Width = 124
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Command string:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 218
    end
    object Label6: TLabel
      Left = 411
      Top = 155
      Width = 83
      Height = 23
      Alignment = taRightJustify
      Anchors = [akRight, akBottom]
      Caption = 'Baudrate:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 204
    end
    object btListAllPorts: TButton
      Left = 12
      Top = 6
      Width = 121
      Height = 33
      Caption = 'List of all USB ports'
      TabOrder = 0
      OnClick = btListAllPortsClick
    end
    object edVID: TEdit
      Left = 564
      Top = 10
      Width = 57
      Height = 30
      Anchors = [akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      Text = '0000'
    end
    object edPID: TEdit
      Left = 564
      Top = 46
      Width = 57
      Height = 30
      Anchors = [akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      Text = '0000'
    end
    object edIntfNum: TEdit
      Left = 564
      Top = 82
      Width = 57
      Height = 30
      Anchors = [akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      Text = '00'
    end
    object btOpenTerminal: TButton
      Left = 12
      Top = 231
      Width = 121
      Height = 33
      Caption = 'Open terminal'
      TabOrder = 4
      OnClick = btOpenTerminalClick
    end
    object edCmdString: TButtonedEdit
      Left = 12
      Top = 190
      Width = 609
      Height = 27
      Anchors = [akLeft, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      RightButton.Visible = True
      TabOrder = 5
    end
    object edPath: TFilenameEdit
      Left = 12
      Top = 121
      Width = 609
      Height = 27
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      Anchors = [akLeft, akRight, akBottom]
      NumGlyphs = 1
      ParentFont = False
      TabOrder = 6
      Text = ''
    end
    object edBaudrate: TEdit
      Left = 500
      Top = 154
      Width = 121
      Height = 30
      Anchors = [akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      Text = '115200'
    end
    object cbAutoOpen: TRxCheckBox
      Left = 468
      Top = 236
      Width = 161
      Height = 17
      Caption = 'Automatically open terminal'
      TabOrder = 8
      WordWrap = True
      HorizontalAlignment = taLeftJustify
      VerticalAlignment = taAlignTop
      Style = vsNormal
    end
    object cbOpenAll: TRxCheckBox
      Left = 297
      Top = 236
      Width = 160
      Height = 17
      Caption = 'Open all available ports:'
      TabOrder = 9
      WordWrap = True
      HorizontalAlignment = taLeftJustify
      VerticalAlignment = taAlignTop
      Style = vsNormal
    end
  end
  object FormStorage: TFormStorage
    Active = False
    IniFileName = 'Vcomto.ini'
    StoredProps.Strings = (
      'edPID.Text'
      'edVID.Text'
      'edIntfNum.Text'
      'edCmdString.Text'
      'edPath.Text'
      'edBaudrate.Text'
      'cbAutoOpen.Checked'
      'cbOpenAll.Checked')
    StoredValues = <>
    Left = 432
    Top = 40
  end
end
