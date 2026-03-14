; FlowDesk Windows Installer Script (Inno Setup)
; Run this in Inno Setup Compiler on Windows

[Setup]
AppName=FlowDesk
AppVersion=1.2.4
DefaultDirName={autopf}\FlowDesk
DefaultGroupName=FlowDesk
UninstallDisplayIcon={app}\FlowDeskServer.exe
Compression=lzma2
SolidCompression=yes
OutputDir=..\build\windows
OutputBaseFilename=FlowDeskSetup
SetupIconFile=src\icon.ico

[Files]
Source: "dist\FlowDeskServer.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "src\icon.ico"; DestDir: "{app}\src"; Flags: ignoreversion

[Icons]
Name: "{group}\FlowDesk"; Filename: "{app}\FlowDeskServer.exe"
Name: "{commondesktop}\FlowDesk"; Filename: "{app}\FlowDeskServer.exe"

[Run]
Filename: "{app}\FlowDeskServer.exe"; Description: "Launch FlowDesk Server"; Flags: nowait postinstall skipifsilent
