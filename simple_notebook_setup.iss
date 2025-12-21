[Setup]
AppName=Eiffel Notebook
AppVersion=1.0.0-alpha.24
AppPublisher=Simple Eiffel
AppPublisherURL=https://github.com/simple-eiffel/simple_notebook
DefaultDirName={autopf}\EiffelNotebook
DefaultGroupName=Eiffel Notebook
OutputDir=installer
OutputBaseFilename=eiffel_notebook_setup_1.0.0-alpha.24
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "EIFGENs\notebook_cli\F_code\simple_notebook.exe"; DestDir: "{app}"; DestName: "eiffel_notebook.exe"; Flags: ignoreversion
Source: "installer\config.json"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Eiffel Notebook"; Filename: "{app}\eiffel_notebook.exe"
Name: "{group}\Uninstall Eiffel Notebook"; Filename: "{uninstallexe}"

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath('{app}')

[Code]
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;
