program Shifter;

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Main in 'forms\Main.pas' {MainForm},
  Score in 'dialogs\Score.pas' {ScoreDialog},
  YourName in 'dialogs\YourName.pas' {YourNameDialog},
  About in 'dialogs\About.pas' {AboutForm},
  BlockPanel in 'units\BlockPanel.pas',
  Vcl.Themes,
  Vcl.Styles,
  Language in '..\..\Common\units\Language.pas' {LanguageDataModule},
  BigIni in '..\..\Common\units\BigIni.pas',
  Dlg in '..\..\Common\dialogs\Dlg.pas' {Dialog},
  Common in '..\..\Common\units\Common.pas',
  DownloadURL in '..\..\Common\dialogs\DownloadURL.pas' {DownloadURLDialog},
  CommonDialogs in '..\..\Common\units\CommonDialogs.pas',
  StyleHooks in '..\..\Common\units\StyleHooks.pas',
  Encoding in '..\..\Common\units\Encoding.pas';

{$R *.res}

var
  StyleFilename: string;
begin
  with TBigIniFile.Create(Common.GetINIFilename) do
  try
    if SectionExists('Preferences') then
      EraseSection('Preferences'); { depricated }
    { Style }
    StyleFilename := ReadString('Options', 'StyleFilename', 'Windows');
  finally
    Free;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if StyleFilename <> STYLENAME_WINDOWS then
    TStyleManager.SetStyle(TStyleManager.LoadFromFile(Format('%sStyles\%s', [ExtractFilePath(ParamStr(0)), StyleFilename])));
  Application.Title := 'Shifter';
  Application.HelpFile := 'Shifter.chm';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
