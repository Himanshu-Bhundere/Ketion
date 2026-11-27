#define MyAppName "Ketion"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Ketion"
#define MyAppExeName "ketion.exe"

[Setup]
AppId={{B4F04D71-6A7A-4E22-93F1-5B5A9E21D421}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={localappdata}\Programs\Ketion
DefaultGroupName=Ketion

OutputDir=..\..\dist\windows
OutputBaseFilename=Ketion-Setup-{#MyAppVersion}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

PrivilegesRequired=lowest

Compression=lzma2
SolidCompression=yes

UninstallDisplayIcon={app}\{#MyAppExeName}

WizardStyle=modern

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; \
    DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Ketion"; \
    Filename: "{app}\{#MyAppExeName}"

Name: "{autodesktop}\Ketion"; \
    Filename: "{app}\{#MyAppExeName}"; \
    Tasks: desktopicon

Name: "{userappdata}\Microsoft\Windows\SendTo\Ketion"; \
    Filename: "{app}\{#MyAppExeName}"; \
    Comment: "Send files to Ketion"

[Registry]
Root: HKCU; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: "*"; ValueData: ""; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Applications\{#MyAppExeName}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\ketion"; ValueType: string; ValueName: ""; ValueData: "URL:Ketion Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\ketion"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\ketion\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Flags: uninsdeletekey

[Tasks]
Name: "desktopicon"; \
    Description: "Create a desktop shortcut"; \
    GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\{#MyAppExeName}"; \
    Description: "Launch Ketion"; \
    Flags: nowait postinstall skipifsilent

