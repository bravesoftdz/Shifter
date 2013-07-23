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
  BCCommon.LanguageStrings in '..\..\Common\units\BCCommon.LanguageStrings.pas' {LanguageDataModule},
  BigIni in '..\..\Common\units\BigIni.pas',
  BCDialogs.Dlg in '..\..\Common\dialogs\BCDialogs.Dlg.pas' {Dialog},
  BCCommon in '..\..\Common\units\BCCommon.pas',
  BCDialogs.DownloadURL in '..\..\Common\dialogs\BCDialogs.DownloadURL.pas' {DownloadURLDialog},
  BCCommon.Dialogs in '..\..\Common\units\BCCommon.Dialogs.pas',
  BCCommon.StyleHooks in '..\..\Common\units\BCCommon.StyleHooks.pas',
  BCCommon.Encoding in '..\..\Common\units\BCCommon.Encoding.pas',
  BCCommon.Messages in '..\..\Common\units\BCCommon.Messages.pas',
  BCCommon.FileUtils in '..\..\Common\units\BCCommon.FileUtils.pas',
  BCCommon.StringUtils in '..\..\Common\units\BCCommon.StringUtils.pas';

{$R *.res}

var
  StyleFilename: string;
begin
  with TBigIniFile.Create(GetINIFilename) do
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
