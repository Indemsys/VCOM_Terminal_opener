unit USB_COM_enumeration;

interface

uses Windows, Classes, SysUtils, JvSetupApi, System.StrUtils, System.AnsiStrings;

function EnumerateUsbCom(VID, PID, MI: Integer; Ports: TStrings): Integer;
function PopulateListWithPorts(Ports: TStrings): Integer;

const
  PortsGUID: TGUID = '{4D36E978-E325-11CE-BFC1-08002BE10318}'; // ports

implementation

procedure Convert_REG_MULTI_SZ_str(var s: string);
var
  i, j: Integer;
  k: Integer;
begin
  k := 0;
  j := 0;
  for i := 1 to Length(s) do
    if s[i] <> #0 then
    begin
      Inc(j);
      s[j] := s[i];
    end
    else
    begin
      if k = (i - 1) then
      begin
        SetLength(s, j - 1);
        exit;
      end;
      Inc(j);
      s[j] := ',';
      k := j;
    end;
  if j < Length(s) then
    SetLength(s, j);
end;

function EnumerateUsbCom(VID, PID, MI: Integer; Ports: TStrings): Integer;
var
  GUID: TGUID;
  PnPHandle: HDevInfo; // handle �� ���� ������ ���������, ������ ports
  i, j: DWORD;
  DeviceInfoData: SP_DEVINFO_DATA;
  Err: Integer;
  RequiredLength: DWORD;
  DevicePath: string;
  RegType: DWORD;
  Name: string;
  s: string;
  DevPID: Word;
  DevVID: Word;
  DevMI: Word;
  RegKey: HKey;
begin
  Ports.Clear;
  Result := 0;
  GUID := PortsGUID;

  // �������� handle �� ���� ������ ������ �������������� � �������
  // win7 compat: � ������ DIGCF_DEVICEINTERFACE � ��������� ������ � ��������
  // ������������� ������ �������� ���-�����
  PnPHandle := SetupDiGetClassDevs(@GUID, nil, 0, DIGCF_PRESENT { or  DIGCF_DEVICEINTERFACE } );

  if PnPHandle = Pointer(INVALID_HANDLE_VALUE) then // �� ����� ������� ����
    raise Exception.Create(SysErrorMessage(GetLastError));
  try
    i := 0; // ������ ����
    DeviceInfoData.cbSize := SizeOf(DeviceInfoData);
    while SetupDiEnumDeviceInfo(PnPHandle, i, DeviceInfoData) do
    // �������� ��������������� �����, ���� ��� ����.
    begin
      DevicePath := '';
      Name := '';
      // �������� ������ ������� HardwareID
      SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, nil, 0, RequiredLength);
      Err := GetLastError;
      if Err = ERROR_INSUFFICIENT_BUFFER then
      // ������ ��� ������ ������ ���������� - ��� ������ - ���-�� �� ���
      begin
        if Length(Name) < RequiredLength div SizeOf(Char) then
          // ���� ����� ���������, ��
          SetLength(Name, RequiredLength div SizeOf(Char));
        // ������������� ������ ������

        if not SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, @Name[1], RequiredLength, RequiredLength) then
        // �������� HardwareID
        begin
          Inc(i); // ���� ������, �� ������� �������� ����
          Continue;
        end;
      end
      else
        raise Exception.Create(SysErrorMessage(Err));

      Name := UpperCase(Name);
      // ����� ���������� ������, ��������� ��� � ��������� �����
      if Copy(Name, 1, 3) = 'USB' then
      // ���� ������ ��� ������� HardwareID = 'USB' - �� ��� � ��� ����������� ����
      begin
        j := pos('VID_', Name) + 4; // ���� ��� � ��� VID
        s := '';
        while Name[j] <> '&' do // �������� VID
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevVID := StrToInt('$' + s);

        j := pos('PID_', Name) + 4; // ���� PID
        s := '';
        while (Name[j] <> '&') and (Name[j] <> #0) do // �������� PID
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevPID := StrToInt('$' + s);

        j := pos('MI_', Name) + 3; // ���� MI
        s := '';
        while (Name[j] <> '&') and (Name[j] <> #0) do // �������� MI
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevMI := StrToInt('$' + s);


        if (DevVID = VID) and (DevPID = PID) and (DevMI = MI) then // ���� VID � PID � MI - ����, ��
        begin
          SetLength(DevicePath, 10);
          // 10 �������� �� �������� ���-����� - ������ (������������ COM999999 [��������� ������ = #0])
          RegKey := SetupDiOpenDevRegKey(PnPHandle, DeviceInfoData, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_QUERY_VALUE);
          // �������� Handle �� ������ ������� ���������� ����������
          if RegKey = INVALID_HANDLE_VALUE then
          begin
            Inc(i); // ���� ������ - �������� ����
            Continue;
          end;
          try
            RequiredLength := 10 * SizeOf(Char);
            if RegQueryValueEx(RegKey, 'PortName', nil, @RegType, @DevicePath[1], @RequiredLength) <> ERROR_SUCCESS then
            // � PortName �������� �������� ����� (�������� - ���5)
            begin
              Inc(i);
              Continue;
            end;
            DevicePath := Copy(DevicePath, 1, RequiredLength div SizeOf(Char) - 1);
            // � RequiredLength - ������ ���������� ������, ����� 1 - ��������� ���� ��� �� �����
            Ports.Add(DevicePath); // ���������� ��� �����
            Inc(Result);
            // ��������� ������� - ���������� ������ ��� ������� VID&PID
          finally
            RegCloseKey(RegKey); // Handle ���� �������, ���� � ������ ������
          end;
        end;
      end;
      Inc(i); // �������� ����
    end;
  finally
    SetupDiDestroyDeviceInfoList(PnPHandle); // ����������� ������� ������.
  end;
end;

function PopulateListWithPorts(Ports: TStrings): Integer;
var
  GUID: TGUID;
  PnPHandle: HDevInfo; // handle �� ���� ������ ���������, ������ ports
  i: DWORD;
  DeviceInfoData: SP_DEVINFO_DATA;
  Err: Integer;
  RequiredLength: DWORD;
  DevicePath: string;
  RegType: DWORD;
  Name: string;
  RegKey: HKey;
  inf_str: string;
begin
  Ports.Clear;
  Result := 0;
  GUID := PortsGUID;

  // �������� handle �� ���� ������ ������ �������������� � �������
  // win7 compat: � ������ DIGCF_DEVICEINTERFACE � ��������� ������ � ��������
  // ������������� ������ �������� ���-�����
  PnPHandle := SetupDiGetClassDevs(@GUID, nil, 0, DIGCF_PRESENT); // DIGCF_PRESENT or  DIGCF_DEVICEINTERFACE );

  if PnPHandle = Pointer(INVALID_HANDLE_VALUE) then // �� ����� ������� ����
    raise Exception.Create(SysErrorMessage(GetLastError));
  try
    i := 0; // ������ ����
    DeviceInfoData.cbSize := SizeOf(DeviceInfoData);
    while SetupDiEnumDeviceInfo(PnPHandle, i, DeviceInfoData) do
    // �������� ��������������� �����, ���� ��� ����.
    begin
      DevicePath := '';
      Name := '';
      // �������� ������ ������� HardwareID
      SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, nil, 0, RequiredLength);
      Err := GetLastError;
      if Err = ERROR_INSUFFICIENT_BUFFER then
      // ������ ��� ������ ������ ���������� - ��� ������ - ���-�� �� ���
      begin
        if Length(Name) < RequiredLength div SizeOf(Char) then
          // ���� ����� ���������, ��
          SetLength(Name, RequiredLength div SizeOf(Char));
        // ������������� ������ ������

        if not SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, @Name[1], RequiredLength, RequiredLength) then
        // �������� HardwareID
        begin
          Inc(i); // ���� ������, �� ������� �������� ����
          Continue;
        end;
      end
      else
        raise Exception.Create(SysErrorMessage(Err));

      Name := UpperCase(Name);
      Convert_REG_MULTI_SZ_str(Name);

      SetLength(DevicePath, 10);
      // 10 �������� �� �������� ���-����� - ������ (������������ COM999999 [��������� ������ = #0])
      RegKey := SetupDiOpenDevRegKey(PnPHandle, DeviceInfoData, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_QUERY_VALUE);
      // �������� Handle �� ������ ������� ���������� ����������
      if RegKey = INVALID_HANDLE_VALUE then
      begin
        Inc(i); // ���� ������ - �������� ����
        Continue;
      end;
      try
        RequiredLength := 10 * SizeOf(Char);
        if RegQueryValueEx(RegKey, 'PortName', nil, @RegType, @DevicePath[1], @RequiredLength) <> ERROR_SUCCESS then
        // � PortName �������� �������� ����� (�������� - ���5)
        begin
          Inc(i);
          Continue;
        end;
        DevicePath := Copy(DevicePath, 1, RequiredLength div SizeOf(Char) - 1);
        // � RequiredLength - ������ ���������� ������, ����� 1 - ��������� ���� ��� �� �����
        inf_str := Name + '  :' + DevicePath;
        Ports.Add(inf_str); // ���������� ��� �����
        Inc(Result);
        // ��������� ������� - ���������� ������ ��� ������� VID&PID
      finally
        RegCloseKey(RegKey); // Handle ���� �������, ���� � ������ ������
      end;
      Inc(i); // �������� ����
    end;
  finally
    SetupDiDestroyDeviceInfoList(PnPHandle); // ����������� ������� ������.
  end;
end;

end.
