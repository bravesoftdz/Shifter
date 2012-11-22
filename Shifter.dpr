program Shifter;

uses
  Forms,
  Main in 'forms\Main.pas' {MainForm},
  Score in 'dialogs\Score.pas' {ScoreDialog},
  YourName in 'dialogs\YourName.pas' {YourNameDialog},
  About in 'dialogs\About.pas' {AboutForm},
  BlockPanel in 'units\BlockPanel.pas',
  Vcl.Themes,
  Vcl.Styles,
  Common in '..\..\Common\units\Common.pas',
  BigIni in '..\..\Common\units\BigIni.pas',
  Dlg in '..\..\Common\dialogs\Dlg.pas' {Dialog};

{$R *.res}

var
  StyleName: string;
begin
  with TBigIniFile.Create(Common.GetINIFilename) do
  try
    { Style }
    StyleName := ReadString('Preferences', 'StyleName', 'Windows');
  finally
    Free;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if StyleName <> 'Windows' then
    TStyleManager.TrySetStyle(StyleName);
  Application.Title := 'Shifter';
  Application.HelpFile := 'Shifter.chm';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
