#define MyAppName "FocusFlow"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "FocusFlow"
#define MyAppExeName "focusflow.exe"

[Setup]
AppId={{A7F1F1D9-67C8-4C91-9C77-0F0C05F10F10}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={localappdata}\Programs{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

OutputDir=output
OutputBaseFilename=FocusFlow-Setup-0.1.0

Compression=lzma
SolidCompression=yes
WizardStyle=modern

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

PrivilegesRequired=lowest

UninstallDisplayIcon={app}{#MyAppExeName}

VersionInfoVersion=0.1.0.1
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Windows MVP Installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autoprograms}\FocusFlow\FocusFlow"; Filename: "{app}\focusflow.exe"
Name: "{autoprograms}\FocusFlow\Uninstall FocusFlow"; Filename: "{uninstallexe}"
Name: "{userdesktop}\FocusFlow"; Filename: "{app}\focusflow.exe"; Tasks: desktopicon

[Run]
Filename: "{app}{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
