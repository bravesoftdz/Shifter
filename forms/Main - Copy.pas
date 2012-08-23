unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls,
  ThdTimer, BlockPanel, BCProgressPanel, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, Vcl.ToolWin, Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.StdStyleActnCtrls, Vcl.ImgList,
  BCImageList, Vcl.XPMan;

const
  INTERVAL_MSEC = 20; { fps = 1000/INTERVAL (INTERVAL 20 -> fps 50) }
  DEFAULT_SIZE_WIDTH = 200;
  DEFAULT_SIZE_HEIGHT = 310;
  MSG_ASKAREYOUSURE = 'Current game is not finished. Start a new game, are you sure?';
  MSG_ASKNEWGAME = 'Do you want to play again?';
  MSG_ASKCLOSING = 'Close the game, are you sure?';

type
  TMainForm = class(TForm)
    GamePanel: TPanel;
    StatusBar: TStatusBar;
    ThreadedTimer: TThreadedTimer;
    ProgressBar: TProgressPanel;
    ActionMainMenuBar: TActionMainMenuBar;
    ActionManager: TActionManager;
    NewGameAction: TAction;
    ScoresAction: TAction;
    ExitAction: TAction;
    AboutAction: TAction;
    StyleAuricAction: TAction;
    StyleAmakritsAction: TAction;
    StyleAmethystKamriAction: TAction;
    StyleAquaGraphiteAction: TAction;
    StyleAquaLightSlateAction: TAction;
    StyleCarbonAction: TAction;
    StyleCharcoalDarkSlateAction: TAction;
    StyleCobaltXEMediaAction: TAction;
    StyleCyanDuskAction: TAction;
    StyleCyanNightAction: TAction;
    StyleEmeraldLightSlateAction: TAction;
    StyleGoldenGraphiteAction: TAction;
    StyleIcebergClassicoAction: TAction;
    StyleLavenderClassicoAction: TAction;
    StyleMetroBlackAction: TAction;
    StyleMetroBlueAction: TAction;
    StyleMetroGreenAction: TAction;
    StyleRubyGraphiteAction: TAction;
    StyleSaphireKamriAction: TAction;
    StyleSlateClassicoAction: TAction;
    StyleSmokeyQuartzKamriAction: TAction;
    StyleTurquoiseGrayAction: TAction;
    StyleWindowsAction: TAction;
    Action1: TAction;
    ImageList: TImageList;
    MenuImageList: TBCImageList;
    XPManifest: TXPManifest;
    procedure FormCreate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure ThreadedTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure NewGameActionExecute(Sender: TObject);
    procedure ScoresActionExecute(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure AboutActionExecute(Sender: TObject);
    procedure StyleAuricActionExecute(Sender: TObject);
    procedure StyleAmakritsActionExecute(Sender: TObject);
    procedure StyleAmethystKamriActionExecute(Sender: TObject);
    procedure StyleAquaGraphiteActionExecute(Sender: TObject);
    procedure StyleAquaLightSlateActionExecute(Sender: TObject);
    procedure StyleCarbonActionExecute(Sender: TObject);
    procedure StyleCharcoalDarkSlateActionExecute(Sender: TObject);
    procedure StyleCobaltXEMediaActionExecute(Sender: TObject);
    procedure StyleCyanDuskActionExecute(Sender: TObject);
    procedure StyleCyanNightActionExecute(Sender: TObject);
    procedure StyleEmeraldLightSlateActionExecute(Sender: TObject);
    procedure StyleGoldenGraphiteActionExecute(Sender: TObject);
    procedure StyleIcebergClassicoActionExecute(Sender: TObject);
    procedure StyleLavenderClassicoActionExecute(Sender: TObject);
    procedure StyleMetroBlackActionExecute(Sender: TObject);
    procedure StyleMetroBlueActionExecute(Sender: TObject);
    procedure StyleMetroGreenActionExecute(Sender: TObject);
    procedure StyleRubyGraphiteActionExecute(Sender: TObject);
    procedure StyleSaphireKamriActionExecute(Sender: TObject);
    procedure StyleSlateClassicoActionExecute(Sender: TObject);
    procedure StyleSmokeyQuartzKamriActionExecute(Sender: TObject);
    procedure StyleTurquoiseGrayActionExecute(Sender: TObject);
    procedure StyleWindowsActionExecute(Sender: TObject);
  private
    { Private declarations }
    BlockPanel: TBlockPanel;
    FOldScore: Integer;
    procedure OnGameScoreChange(Sender: TObject);
    procedure OnGameLevelChange(Sender: TObject);
    procedure OnGameStartWaiting(Sender: TObject);
    procedure OnGameEndWaiting(Sender: TObject);
    procedure OnRestore(Sender: TObject);
    function GetProgressBarColor(Value: Integer): TColor;
    procedure SetCurrentScore(Value: Integer);
    procedure SetProgressBarPosition(Value: Integer);
    procedure SetStyleName(Value: string);
    procedure StartNewGame;
    procedure ReadIniFile;
    procedure WriteIniFile;
    procedure WMNCRButtonDown(var Msg: TWMNCRButtonDown); message WM_NCRBUTTONDOWN;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  public
    { Public declarations }
    property CurrentScore: Integer write SetCurrentScore;
    property ProgressBarPosition: Integer write SetProgressBarPosition;
    property StyleName: string write SetStyleName;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Common, System.Math, Score, About, Vcl.Themes, BigIni;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FOldScore := 0;
  { BlockPanel }
  BlockPanel := TBlockPanel.Create(MainForm, ImageList);
  with BlockPanel do
  begin
    Parent := GamePanel;
    Align := alClient;
    Interval := INTERVAL_MSEC;
    Running := True;
    OnScoreChange := OnGameScoreChange;
    OnLevelChange := OnGameLevelChange;
    OnStartWaiting := OnGameStartWaiting;
    OnEndWaiting := OnGameEndWaiting;
    DemoRunning := True;
  end;
  StatusBar.Panels[0].Text := '';
  StatusBar.Panels[1].Text := '';

  Application.OnRestore := OnRestore;

  ReadIniFile;
  StyleName := TStyleManager.ActiveStyle.Name;
end;

procedure TMainForm.SetStyleName(Value: string);
begin
  StyleAmakritsAction.Checked := Value = STYLENAME_AMAKRITS;
  StyleAmethystKamriAction.Checked := Value = STYLENAME_AMETHYST_KAMRI;
  StyleAquaGraphiteAction.Checked := Value = STYLENAME_AQUA_GRAPHITE;
  StyleAquaLightSlateAction.Checked := Value = STYLENAME_AQUA_LIGHT_SLATE;
  StyleAuricAction.Checked := Value = STYLENAME_AURIC;
  StyleCarbonAction.Checked := Value = STYLENAME_CARBON;
  StyleCharcoalDarkSlateAction.Checked := Value = STYLENAME_CHARCOAL_DARK_SLATE;
  StyleCobaltXEMediaAction.Checked := Value = STYLENAME_COBALT_XEMEDIA;
  StyleCyanDuskAction.Checked := Value = STYLENAME_CYAN_DUSK;
  StyleCyanNightAction.Checked := Value = STYLENAME_CYAN_NIGHT;
  StyleEmeraldLightSlateAction.Checked := Value = STYLENAME_EMERALD_LIGHT_SLATE;
  StyleGoldenGraphiteAction.Checked := Value = STYLENAME_GOLDEN_GRAPHITE;
  StyleIcebergClassicoAction.Checked := Value = STYLENAME_ICEBERG_CLASSICO;
  StyleLavenderClassicoAction.Checked := Value = STYLENAME_LAVENDER_CLASSICO;
  StyleMetroBlackAction.Checked := Value = STYLENAME_METRO_BLACK;
  StyleMetroBlueAction.Checked := Value = STYLENAME_METRO_BLUE;
  StyleMetroGreenAction.Checked := Value = STYLENAME_METRO_GREEN;
  StyleRubyGraphiteAction.Checked := Value = STYLENAME_RUBY_GRAPHITE;
  StyleSaphireKamriAction.Checked := Value = STYLENAME_SAPPHIRE_KAMRI;
  StyleSlateClassicoAction.Checked := Value = STYLENAME_SLATE_CLASSICO;
  StyleSmokeyQuartzKamriAction.Checked := Value = STYLENAME_SMOKEY_QUARTZ_KAMRI;
  StyleTurquoiseGrayAction.Checked := Value = STYLENAME_TURUOISE_GRAY;
  StyleWindowsAction.Checked := Value = STYLENAME_WINDOWS;
  if Assigned(TStyleManager.ActiveStyle) then
    if Value <> TStyleManager.ActiveStyle.Name then
      TStyleManager.TrySetStyle(Value);
end;

procedure TMainForm.ReadIniFile;
begin
  with TBigIniFile.Create(ChangeFileExt(Application.EXEName, '.ini')) do
  try
    { Size }
    Width := ReadInteger('Size', 'Width', DEFAULT_SIZE_WIDTH);
    Height := ReadInteger('Size', 'Height', DEFAULT_SIZE_HEIGHT);
    { Position }
    Left := ReadInteger('Position', 'Left', (Screen.Width - Width) div 2);
    Top := ReadInteger('Position', 'Top', (Screen.Height - Height) div 2);
  finally
    Free;
  end;
end;

procedure TMainForm.WriteIniFile;
begin
  if WindowState = wsNormal then
  with TBigIniFile.Create(ChangeFileExt(Application.EXEName, '.ini')) do
  try
    { Position }
    WriteInteger('Position', 'Left', Left);
    WriteInteger('Position', 'Top', Top);
    { Size }
    WriteInteger('Size', 'Width', Width);
    WriteInteger('Size', 'Height', Height);
    if Assigned(TStyleManager.ActiveStyle) then
      WriteString('Preferences', 'StyleName', TStyleManager.ActiveStyle.Name);
  finally
    Free;
  end;
end;


procedure TMainForm.OnRestore(Sender: TObject);
begin
  BlockPanel.Idle := False;
end;

procedure TMainForm.OnGameStartWaiting(Sender: TObject);
begin
  ThreadedTimer.Enabled := True;
  ThreadedTimerTimer(Sender)
end;

procedure TMainForm.OnGameEndWaiting(Sender: TObject);
begin
  ThreadedTimer.Enabled := False
end;

procedure TMainForm.SetCurrentScore(Value: Integer);
begin
  StatusBar.Panels[1].Text := Format('Score: %d', [Value]);
end;

function TMainForm.GetProgressBarColor(Value: Integer): TColor;
begin
  if Value < 10 then
    Result := clRed
  else
  if Value < 20 then
    Result := clYellow
  else
    Result := clGreen
end;

procedure TMainForm.SetProgressBarPosition(Value: Integer);
begin
  ProgressBar.Position := Value;
  ProgressBar.FillColor := GetProgressBarColor(Value);
end;

procedure TMainForm.OnGameScoreChange(Sender: TObject);
begin
  CurrentScore := BlockPanel.Score;
  ProgressBarPosition := Min(ProgressBar.Position + Round(((BlockPanel.Score - FOldScore) div 10)*(500/ThreadedTimer.Interval)),
    ProgressBar.Max);
  FOldScore := BlockPanel.Score;
end;

procedure TMainForm.OnGameLevelChange(Sender: TObject);
var
  Interval: Integer;
begin
  StatusBar.Panels[0].Text := 'Level '+inttostr(BlockPanel.Level);
  ProgressBarPosition := 50;

  Interval := 500 - 50*(BlockPanel.Level-1);
  if Interval < 100 then
    Interval := 100;
  ThreadedTimer.Interval := Interval;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  Resize := True;
  if (NewWidth > 200) and (NewHeight > 310) then
  begin
    if NewWidth <> NewHeight then
      NewWidth := NewHeight - 110
  end
  else
    Resize := False
end;

procedure TMainForm.ExitActionExecute(Sender: TObject);
begin
  if Common.AskYesOrNo(MSG_ASKCLOSING) then
    Close;
end;

procedure TMainForm.ThreadedTimerTimer(Sender: TObject);
begin
  if not BlockPanel.Idle then
  begin
    ProgressBarPosition := ProgressBar.Position - 1;

    if ProgressBar.Position = 0 then
      BlockPanel.SetGameOver;

    if BlockPanel.GameOver then
    begin
      ThreadedTimer.Enabled := False;
      ScoreDialog.Open(BlockPanel.Score, BlockPanel.Level);
      if Common.AskYesOrNo(MSG_ASKNEWGAME) then
        StartNewGame
      else
        Close
    end;
  end;
end;

procedure TMainForm.StartNewGame;
begin
  BlockPanel.DemoRunning := False;
  BlockPanel.NewGame;
end;

procedure TMainForm.NewGameActionExecute(Sender: TObject);
begin
  if not BlockPanel.DemoRunning then
    if not Common.AskYesOrNo(MSG_ASKAREYOUSURE) then
      Exit;

  StartNewGame;
end;

procedure TMainForm.AboutActionExecute(Sender: TObject);
begin
  AboutDialog.Open;
end;

procedure TMainForm.ScoresActionExecute(Sender: TObject);
begin
  ScoreDialog.Open;
end;

{ player can't cheat by clicking form caption and pause game }
procedure TMainForm.WMNCRButtonDown(var Msg : TWMNCRButtonDown);
begin
  if (Msg.HitTest = HTCAPTION) then
    ;
end;

procedure TMainForm.WMSysCommand(var Msg: TWMSysCommand);
begin
  if Msg.CmdType = SC_MINIMIZE then
  begin
    BlockPanel.Idle := True;
    Application.Minimize
  end
  else
  if Msg.CmdType = SC_MAXIMIZE then
  begin
    if WindowState = wsNormal then
      WindowState := wsMaximized
    else
      WindowState := wsNormal
  end;

  DefaultHandler(Msg);
end;

procedure TMainForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  WriteIniFile;
end;

procedure TMainForm.StyleAuricActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_AURIC;
end;

procedure TMainForm.StyleAmakritsActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_AMAKRITS;
end;

procedure TMainForm.StyleAmethystKamriActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_AMETHYST_KAMRI;
end;

procedure TMainForm.StyleAquaGraphiteActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_AQUA_GRAPHITE;
end;

procedure TMainForm.StyleAquaLightSlateActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_AQUA_LIGHT_SLATE;
end;

procedure TMainForm.StyleCarbonActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_CARBON;
end;

procedure TMainForm.StyleCharcoalDarkSlateActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_CHARCOAL_DARK_SLATE;
end;

procedure TMainForm.StyleCobaltXEMediaActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_COBALT_XEMEDIA;
end;

procedure TMainForm.StyleCyanDuskActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_CYAN_DUSK;
end;

procedure TMainForm.StyleCyanNightActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_CYAN_NIGHT;
end;

procedure TMainForm.StyleEmeraldLightSlateActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_EMERALD_LIGHT_SLATE;
end;

procedure TMainForm.StyleGoldenGraphiteActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_GOLDEN_GRAPHITE;
end;

procedure TMainForm.StyleIcebergClassicoActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_ICEBERG_CLASSICO;
end;

procedure TMainForm.StyleLavenderClassicoActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_LAVENDER_CLASSICO;
end;

procedure TMainForm.StyleMetroBlackActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_METRO_BLACK;
end;

procedure TMainForm.StyleMetroBlueActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_METRO_BLUE;
end;

procedure TMainForm.StyleMetroGreenActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_METRO_GREEN;
end;

procedure TMainForm.StyleRubyGraphiteActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_RUBY_GRAPHITE;
end;

procedure TMainForm.StyleSaphireKamriActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_SAPPHIRE_KAMRI;
end;

procedure TMainForm.StyleSlateClassicoActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_SLATE_CLASSICO;
end;

procedure TMainForm.StyleSmokeyQuartzKamriActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_SMOKEY_QUARTZ_KAMRI;
end;

procedure TMainForm.StyleTurquoiseGrayActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_TURUOISE_GRAY;
end;

procedure TMainForm.StyleWindowsActionExecute(Sender: TObject);
begin
  StyleName := STYLENAME_WINDOWS;
end;

end.
