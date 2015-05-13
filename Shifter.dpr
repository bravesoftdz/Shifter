program Shifter;

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Shifter.Forms.Main in 'Forms\Shifter.Forms.Main.pas' {MainForm},
  Shifter.Dialogs.Score in 'Dialogs\Shifter.Dialogs.Score.pas' {ScoreDialog},
  Shifter.Dialogs.YourName in 'Dialogs\Shifter.Dialogs.YourName.pas' {YourNameDialog},
  Shifter.Dialogs.About in 'Dialogs\Shifter.Dialogs.About.pas' {AboutForm},
  Shifter.Units.BlockPanel in 'Units\Shifter.Units.BlockPanel.pas',
  Vcl.Themes,
  Vcl.Styles,
  BCCommon.FileUtils,
  BigIni;

{$R *.res}

var
  StyleFilename: string;
begin
  with TBigIniFile.Create(GetINIFilename) do
  try
    if SectionExists('Preferences') then
      EraseSection('Preferences'); { deprecated }
    { Style }
    StyleFilename := ReadString('Options', 'StyleFilename', 'Windows');
  finally
    Free;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if StyleFilename <> 'Windows' then
    TStyleManager.SetStyle(TStyleManager.LoadFromFile(Format('%sStyles\%s', [ExtractFilePath(ParamStr(0)), StyleFilename])));
  Application.Title := 'Shifter';
  Application.HelpFile := 'Shifter.chm';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
