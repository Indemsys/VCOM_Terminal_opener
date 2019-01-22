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
  PnPHandle: HDevInfo; // handle на базу данных драйверов, раздел ports
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

  // получаем handle на базу данных портов присутствующих в системе
  // win7 compat: с флагом DIGCF_DEVICEINTERFACE в некоторых компах с семеркой
  // перечисляются только нативные ком-порты
  PnPHandle := SetupDiGetClassDevs(@GUID, nil, 0, DIGCF_PRESENT { or  DIGCF_DEVICEINTERFACE } );

  if PnPHandle = Pointer(INVALID_HANDLE_VALUE) then // не можем открыть базу
    raise Exception.Create(SysErrorMessage(GetLastError));
  try
    i := 0; // первый порт
    DeviceInfoData.cbSize := SizeOf(DeviceInfoData);
    while SetupDiEnumDeviceInfo(PnPHandle, i, DeviceInfoData) do
    // получаем последовательно порты, пока они есть.
    begin
      DevicePath := '';
      Name := '';
      // получаем размер строчки HardwareID
      SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, nil, 0, RequiredLength);
      Err := GetLastError;
      if Err = ERROR_INSUFFICIENT_BUFFER then
      // только эта ошибка должна возникнуть - все другое - что-то не так
      begin
        if Length(Name) < RequiredLength div SizeOf(Char) then
          // если буфер маленький, то
          SetLength(Name, RequiredLength div SizeOf(Char));
        // устанавливаем размер буфера

        if not SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, @Name[1], RequiredLength, RequiredLength) then
        // получаем HardwareID
        begin
          Inc(i); // если ошибка, то смотрим следущий порт
          Continue;
        end;
      end
      else
        raise Exception.Create(SysErrorMessage(Err));

      Name := UpperCase(Name);
      // чтобы сравнивать строки, переводим все в заглавные буквы
      if Copy(Name, 1, 3) = 'USB' then
      // если первые три символа HardwareID = 'USB' - то это у нас виртуальный порт
      begin
        j := pos('VID_', Name) + 4; // ищем где у нас VID
        s := '';
        while Name[j] <> '&' do // получаем VID
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevVID := StrToInt('$' + s);

        j := pos('PID_', Name) + 4; // ищем PID
        s := '';
        while (Name[j] <> '&') and (Name[j] <> #0) do // получаем PID
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevPID := StrToInt('$' + s);

        j := pos('MI_', Name) + 3; // ищем MI
        s := '';
        while (Name[j] <> '&') and (Name[j] <> #0) do // получаем MI
        begin
          s := s + Name[j];
          Inc(j);
        end;
        DevMI := StrToInt('$' + s);


        if (DevVID = VID) and (DevPID = PID) and (DevMI = MI) then // если VID и PID и MI - наши, то
        begin
          SetLength(DevicePath, 10);
          // 10 символов на название ком-порта - хватит (максимальный COM999999 [последний символ = #0])
          RegKey := SetupDiOpenDevRegKey(PnPHandle, DeviceInfoData, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_QUERY_VALUE);
          // получаем Handle на раздел реестра экземпляра устройства
          if RegKey = INVALID_HANDLE_VALUE then
          begin
            Inc(i); // если ошибка - следущий порт
            Continue;
          end;
          try
            RequiredLength := 10 * SizeOf(Char);
            if RegQueryValueEx(RegKey, 'PortName', nil, @RegType, @DevicePath[1], @RequiredLength) <> ERROR_SUCCESS then
            // в PortName записано название порта (например - СОМ5)
            begin
              Inc(i);
              Continue;
            end;
            DevicePath := Copy(DevicePath, 1, RequiredLength div SizeOf(Char) - 1);
            // в RequiredLength - размер полученной строки, минус 1 - последний ноль нам не нужен
            Ports.Add(DevicePath); // добавлеяем имя порта
            Inc(Result);
            // результат функции - количество портов для данного VID&PID
          finally
            RegCloseKey(RegKey); // Handle надо закрыть, даже в случае ошибки
          end;
        end;
      end;
      Inc(i); // следущий порт
    end;
  finally
    SetupDiDestroyDeviceInfoList(PnPHandle); // освобождаем занятую память.
  end;
end;

function PopulateListWithPorts(Ports: TStrings): Integer;
var
  GUID: TGUID;
  PnPHandle: HDevInfo; // handle на базу данных драйверов, раздел ports
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

  // получаем handle на базу данных портов присутствующих в системе
  // win7 compat: с флагом DIGCF_DEVICEINTERFACE в некоторых компах с семеркой
  // перечисляются только нативные ком-порты
  PnPHandle := SetupDiGetClassDevs(@GUID, nil, 0, DIGCF_PRESENT); // DIGCF_PRESENT or  DIGCF_DEVICEINTERFACE );

  if PnPHandle = Pointer(INVALID_HANDLE_VALUE) then // не можем открыть базу
    raise Exception.Create(SysErrorMessage(GetLastError));
  try
    i := 0; // первый порт
    DeviceInfoData.cbSize := SizeOf(DeviceInfoData);
    while SetupDiEnumDeviceInfo(PnPHandle, i, DeviceInfoData) do
    // получаем последовательно порты, пока они есть.
    begin
      DevicePath := '';
      Name := '';
      // получаем размер строчки HardwareID
      SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, nil, 0, RequiredLength);
      Err := GetLastError;
      if Err = ERROR_INSUFFICIENT_BUFFER then
      // только эта ошибка должна возникнуть - все другое - что-то не так
      begin
        if Length(Name) < RequiredLength div SizeOf(Char) then
          // если буфер маленький, то
          SetLength(Name, RequiredLength div SizeOf(Char));
        // устанавливаем размер буфера

        if not SetupDiGetDeviceRegistryProperty(PnPHandle, DeviceInfoData, SPDRP_HARDWAREID, RegType, @Name[1], RequiredLength, RequiredLength) then
        // получаем HardwareID
        begin
          Inc(i); // если ошибка, то смотрим следущий порт
          Continue;
        end;
      end
      else
        raise Exception.Create(SysErrorMessage(Err));

      Name := UpperCase(Name);
      Convert_REG_MULTI_SZ_str(Name);

      SetLength(DevicePath, 10);
      // 10 символов на название ком-порта - хватит (максимальный COM999999 [последний символ = #0])
      RegKey := SetupDiOpenDevRegKey(PnPHandle, DeviceInfoData, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_QUERY_VALUE);
      // получаем Handle на раздел реестра экземпляра устройства
      if RegKey = INVALID_HANDLE_VALUE then
      begin
        Inc(i); // если ошибка - следущий порт
        Continue;
      end;
      try
        RequiredLength := 10 * SizeOf(Char);
        if RegQueryValueEx(RegKey, 'PortName', nil, @RegType, @DevicePath[1], @RequiredLength) <> ERROR_SUCCESS then
        // в PortName записано название порта (например - СОМ5)
        begin
          Inc(i);
          Continue;
        end;
        DevicePath := Copy(DevicePath, 1, RequiredLength div SizeOf(Char) - 1);
        // в RequiredLength - размер полученной строки, минус 1 - последний ноль нам не нужен
        inf_str := Name + '  :' + DevicePath;
        Ports.Add(inf_str); // добавлеяем имя порта
        Inc(Result);
        // результат функции - количество портов для данного VID&PID
      finally
        RegCloseKey(RegKey); // Handle надо закрыть, даже в случае ошибки
      end;
      Inc(i); // следущий порт
    end;
  finally
    SetupDiDestroyDeviceInfoList(PnPHandle); // освобождаем занятую память.
  end;
end;

end.
