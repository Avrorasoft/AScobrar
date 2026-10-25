; Script de Inno Setup para AScobrar con icono personalizado
; Avrora Soft

#define MyAppName "AScobrar"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Avrora Soft"
#define MyAppURL "https://loan-app-vibola.web.app"
#define MyAppExeName "ascobrar.exe"
#define SourceFolder "C:\AScobrar\build\windows\x64\runner\Release"
#define MyIcon "C:\AScobrar\AScobrar.ico"

[Setup]
AppId={{9C2D3E4F-5A6B-7C8D-9E0F-1A2B3C4D5E6F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=C:\AScobrar\installer_output
OutputBaseFilename=AScobrar_Setup_v1.0.0
SetupIconFile={#MyIcon}
UninstallDisplayIcon={app}\AScobrar.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceFolder}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#MyIcon}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\AScobrar.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\AScobrar.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
