; Writ — Windows installer (Inno Setup 6)
; Build the app first (build_exe.sh produces dist/Writ/), build the encrypted
; knowledge base (build_encrypted_db.py produces dist_data/writ_data.dat),
; then compile:  iscc installer\windows\writ.iss
;
; Bundling Ollama: download OllamaSetup.exe from https://ollama.com/download
; and place it next to this .iss (it is ~1 GB, so it is NOT in git).
; The installer:
;   1. installs Writ.exe + index.html next to it (PyInstaller onedir),
;   2. installs writ_data.dat (encrypted, obfuscated name) to {commonappdata}\Writ,
;   3. installs Ollama silently if missing, starts it,
;   4. pulls hf.co/prawinin/vidhi (~2 GB) if not already present — if the model
;      already exists (checked via `ollama list`), the download is skipped and
;      its existing location (OLLAMA_MODELS or %USERPROFILE%\.ollama\models) is kept.
; OPTIONAL post-install: python scripts/setup_reranker.py (~23 MB neural
; rerank model into models\minilm) — needs onnxruntime+tokenizers for Python.

#define MyAppName "Writ"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "prawin.app"
#define MyAppURL "https://prawin.app"

[Setup]
AppId={{8DDC3585-CE9B-4F05-B94F-8F4E57BC2BFA}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\Writ
DefaultGroupName=Writ
OutputDir=..\..\dist-installer
OutputBaseFilename=Writ-Setup-{#MyAppVersion}-Windows
Compression=lzma2/max
SolidCompression=yes
PrivilegesRequired=admin
WizardStyle=modern
SetupIconFile=..\..\assets\icon.ico
UninstallDisplayIcon={app}\Writ.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; App (PyInstaller onedir output — everything in dist/Writ)
Source: "..\..\dist\Writ\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs


[Icons]
Name: "{group}\Writ"; Filename: "{app}\Writ.exe"
Name: "{autodesktop}\Writ"; Filename: "{app}\Writ.exe"; Tasks: desktopicon

[Code]
var
  DownloadPage: TDownloadWizardPage;
  OptionsPage: TInputOptionWizardPage;

procedure InitializeWizard;
begin
  OptionsPage := CreateInputOptionPage(wpSelectTasks,
    'Additional Downloads', 'Select optional components to download',
    'Would you like to download the offline knowledge base? This is required for the full experience.' + #13#10 + #13#10 + 'Note: The Vidhi LLM (~2GB) will be downloaded via Ollama automatically on first run if not already present. Please install Ollama from ollama.com if you haven''t already.',
    False, False);
  
  OptionsPage.Add('Download Writ Knowledge Base (~1.6 GB)');
  OptionsPage.Values[0] := True;

  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurPageID = OptionsPage.ID then
  begin
    DownloadPage.Clear;
    if OptionsPage.Values[0] then
      DownloadPage.Add('https://github.com/prawinin/writ/releases/download/v1.0.0/writ_data.dat', 'writ_data.dat', '');

    if OptionsPage.Values[0] then
    begin
      DownloadPage.Show;
      try
        try
          DownloadPage.Download;
          Result := True;
        except
          if DownloadPage.AbortedByUser then
            Log('Aborted by user.')
          else
            MsgBox('Download failed: ' + GetExceptionMessage, mbError, MB_OK);
          Result := False;
        end;
      finally
        DownloadPage.Hide;
      end;
    end
    else
      Result := True;
  end
  else
    Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  DataDest: String;
begin
  if CurStep = ssPostInstall then
  begin
    if OptionsPage.Values[0] then
    begin
      DataDest := ExpandConstant('{commonappdata}\Writ');
      ForceDirectories(DataDest);
      FileCopy(ExpandConstant('{tmp}\writ_data.dat'), DataDest + '\writ_data.dat', False);
    end;
  end;
end;

[Dirs]
Name: "{commonappdata}\Writ"; Permissions: everyone-modify


[Run]
Filename: "{app}\Writ.exe"; Description: "Launch Writ"; Flags: nowait postinstall skipifsilent
