unit Shifter.Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.ExtCtrls, Shifter.Units.BlockPanel, BCControl.ProgressPanel, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin, Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.StdStyleActnCtrls,
  Vcl.ImgList, BCControl.ImageList, System.Actions, System.Win.TaskbarCore, Vcl.Taskbar, acAlphaImageList,
  System.ImageList;

const
  INTERVAL_MSEC = 20; { fps = 1000/INTERVAL (INTERVAL 20 -> fps 50) }
  DEFAULT_SIZE_WIDTH = 200;
  DEFAULT_SIZE_HEIGHT = 310;
  MSG_ASKAREYOUSURE = 'Current game is not finished. Start a new game, are you sure?';
  MSG_ASKNEWGAME = 'Do you want to play again?';
  MSG_ASKCLOSING = 'Close the game, are you sure?';

type
  TMainForm = class(TForm)
    ActionAbout: TAction;
    ActionExit: TAction;
    ActionMainMenuBar: TActionMainMenuBar;
    ActionManager: TActionManager;
    ActionNewGame: TAction;
    ActionScores: TAction;
    ActionSelectStyle: TAction;
    ActionViewStyle: TAction;
    ImageList: TImageList;
    ImageListMenu: TBCImageList;
    PanelGame: TPanel;
    ProgressBar: TBCProgressPanel;
    StatusBar: TStatusBar;
    Taskbar: TTaskbar;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
    procedure TimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActionNewGameExecute(Sender: TObject);
    procedure ActionScoresExecute(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
    procedure ActionSelectStyleExecute(Sender: TObject);
    procedure ActionViewStyleExecute(Sender: TObject);
  private
    { Private declarations }
    FBlockPanel: TBlockPanel;
    FOldScore: Integer;
    procedure OnGameScoreChange(Sender: TObject);
    procedure OnGameLevelChange(Sender: TObject);
    procedure OnGameStartWaiting(Sender: TObject);
    procedure OnGameEndWaiting(Sender: TObject);
    procedure OnRestore(Sender: TObject);
    procedure SetCurrentScore(Value: Integer);
    procedure SetProgressBarPosition(Value: Integer);
    procedure StartNewGame;
    procedure ReadIniFile;
    procedure WriteIniFile;
    procedure WMNCRButtonDown(var Msg: TWMNCRButtonDown); message WM_NCRBUTTONDOWN;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    function GetActionClientItem(MenuItemIndex, SubMenuItemIndex: Integer): TActionClientItem;
    procedure CreateStyleMenu;
  public
    { Public declarations }
    property CurrentScore: Integer write SetCurrentScore;
    property ProgressBarPosition: Integer write SetProgressBarPosition;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Math, Shifter.Dialogs.Score, Shifter.Dialogs.About, Vcl.Themes, BigIni, BCCommon.FileUtils, System.IOUtils,
  BCCommon.Messages, System.Types;

const
  VIEW_MENU_ITEMINDEX = 1;
  VIEW_STYLE_MENU_ITEMINDEX = 0;
  STYLENAME_WINDOWS = 'Windows';

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FOldScore := 0;
  { BlockPanel }
  FBlockPanel := TBlockPanel.Create(MainForm, ImageList);
  with FBlockPanel do
  begin
    Parent := PanelGame;
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

  CreateStyleMenu;
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
          WriteString('Options', 'StyleName', TStyleManager.ActiveStyle.Name);
      finally
        Free;
      end;
end;

procedure TMainForm.OnRestore(Sender: TObject);
begin
  FBlockPanel.Idle := False;
end;

procedure TMainForm.OnGameStartWaiting(Sender: TObject);
begin
  Timer.Enabled := True;
  TimerTimer(Sender);
end;

procedure TMainForm.OnGameEndWaiting(Sender: TObject);
begin
  Timer.Enabled := False;
end;

function TMainForm.GetActionClientItem(MenuItemIndex, SubMenuItemIndex: Integer): TActionClientItem;
begin
  Result := ActionMainMenuBar.ActionClient.Items[MenuItemIndex];
  Result := Result.Items[SubMenuItemIndex];
end;

procedure TMainForm.ActionSelectStyleExecute(Sender: TObject);
var
  i, j: Integer;
  ActionCaption: string;
  Action: TAction;
  ActionClientItem: TActionClientItem;
  StyleInfo: TStyleInfo;
begin
  Action := Sender as TAction;
  ActionCaption := StringReplace(Action.Caption, '&', '', [rfReplaceAll]);

  if Action.Caption = STYLENAME_WINDOWS then
    TStyleManager.TrySetStyle(ActionCaption)
  else if TStyleManager.IsValidStyle(ActionCaption, StyleInfo) then
  begin
    if Assigned(TStyleManager.Style[StyleInfo.Name]) then
      TStyleManager.TrySetStyle(StyleInfo.Name)
    else
      TStyleManager.SetStyle(TStyleManager.LoadFromFile(ActionCaption));
  end;

  with TBigIniFile.Create(GetINIFilename) do
    try
      WriteString('Options', 'StyleFilename', ExtractFilename(ActionCaption));
    finally
      Free;
    end;

  ActionClientItem := GetActionClientItem(VIEW_MENU_ITEMINDEX, VIEW_STYLE_MENU_ITEMINDEX);
  for i := 0 to ActionClientItem.Items.Count - 1 do
    for j := 0 to ActionClientItem.Items[i].Items.Count - 1 do
      TAction(ActionClientItem.Items[i].Items[j].Action).Checked := False;
  Action.Checked := True;
end;

procedure TMainForm.SetCurrentScore(Value: Integer);
begin
  StatusBar.Panels[1].Text := Format('Score: %d', [Value]);
end;

procedure TMainForm.SetProgressBarPosition(Value: Integer);

  function GetProgressBarColor(Value: Integer): TColor;
  begin
    if Value < 10 then
      Result := clRed
    else if Value < 20 then
      Result := clYellow
    else
      Result := clGreen
  end;

  function GetProgressState(Value: Integer): TTaskBarProgressState;
  begin
    if Value < 10 then
      Result := TTaskBarProgressState.Error
    else if Value < 20 then
      Result := TTaskBarProgressState.Paused
    else
      Result := TTaskBarProgressState.Normal
  end;

begin
  ProgressBar.Position := Value;
  ProgressBar.FillColor := GetProgressBarColor(Value);
  Taskbar.ProgressValue := Value;
  Taskbar.ProgressState := GetProgressState(Value);
end;

procedure TMainForm.OnGameScoreChange(Sender: TObject);
begin
  CurrentScore := FBlockPanel.Score;
  ProgressBarPosition := Min(ProgressBar.Position + Round(((FBlockPanel.Score - FOldScore) div 10) *
    (500 / Timer.Interval)), ProgressBar.Max);
  FOldScore := FBlockPanel.Score;
end;

procedure TMainForm.OnGameLevelChange(Sender: TObject);
var
  Interval: Integer;
begin
  StatusBar.Panels[0].Text := 'Level ' + IntToStr(FBlockPanel.Level);
  ProgressBarPosition := 50;

  Interval := 500 - 50 * (FBlockPanel.Level - 1);
  if Interval < 100 then
    Interval := 100;
  Timer.Interval := Interval;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
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

procedure TMainForm.ActionExitExecute(Sender: TObject);
begin
  if AskYesOrNo(MSG_ASKCLOSING) then
    Close;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  if not FBlockPanel.Idle then
  begin
    ProgressBarPosition := ProgressBar.Position - 1;

    if ProgressBar.Position = 0 then
      FBlockPanel.SetGameOver;

    if FBlockPanel.GameOver then
    begin
      Timer.Enabled := False;
      ScoreDialog.Open(FBlockPanel.Score, FBlockPanel.Level);
      if AskYesOrNo(MSG_ASKNEWGAME) then
        StartNewGame
      else
        Close
    end;
  end;
end;

procedure TMainForm.ActionViewStyleExecute(Sender: TObject);
begin
  { dummy action }
end;

procedure TMainForm.StartNewGame;
begin
  FBlockPanel.DemoRunning := False;
  FBlockPanel.NewGame;
end;

procedure TMainForm.ActionNewGameExecute(Sender: TObject);
begin
  if not FBlockPanel.DemoRunning then
    if not AskYesOrNo(MSG_ASKAREYOUSURE) then
      Exit;

  StartNewGame;
end;

procedure TMainForm.ActionAboutExecute(Sender: TObject);
begin
  TAboutDialog.ClassShowModal(Self);
end;

procedure TMainForm.ActionScoresExecute(Sender: TObject);
begin
  ScoreDialog.Open;
end;

{ player can't cheat by clicking form caption and pause game }
procedure TMainForm.WMNCRButtonDown(var Msg: TWMNCRButtonDown);
begin
  if Msg.HitTest = HTCAPTION then
    Msg.Msg := 0;
end;

procedure TMainForm.WMSysCommand(var Msg: TWMSysCommand);
begin
  if Msg.CmdType = SC_MINIMIZE then
  begin
    FBlockPanel.Idle := True;
    Application.Minimize
  end
  else if Msg.CmdType = SC_MAXIMIZE then
  begin
    if WindowState = wsNormal then
      WindowState := wsMaximized
    else
      WindowState := wsNormal
  end;

  DefaultHandler(Msg);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  WriteIniFile;
end;

procedure TMainForm.CreateStyleMenu;
var
  FilePath, FileName, StyleName, ActionCaption: string;
  StyleInfo: TStyleInfo;
  ActionClientItem: TActionClientItem;
  Action: TAction;

  procedure SetMenuItem;
  var
    i: Integer;
  begin
    ActionClientItem := GetActionClientItem(VIEW_MENU_ITEMINDEX, VIEW_STYLE_MENU_ITEMINDEX);
    { alphabet submenu }
    for i := 0 to ActionClientItem.Items.Count - 1 do
    begin
      ActionCaption := StringReplace(ActionClientItem.Items[i].Caption, '&', '', [rfReplaceAll]);
      if ActionCaption = StyleName[1] then
      begin
        ActionClientItem := ActionClientItem.Items[i];
        Break;
      end;
    end;
    ActionCaption := StringReplace(ActionClientItem.Caption, '&', '', [rfReplaceAll]);
    if ActionCaption <> StyleName[1] then
    begin
      ActionClientItem := ActionClientItem.Items.Add;
      ActionClientItem.Caption := StyleName[1];
    end;
    ActionClientItem := ActionClientItem.Items.Add;
  end;

begin
  ActionViewStyle.Enabled := False;
  FilePath := IncludeTrailingPathDelimiter(Format('%s%s', [ExtractFilePath(ParamStr(0)), 'Styles']));
  if not DirectoryExists(FilePath) then
    Exit;

  for FileName in TDirectory.GetFiles(FilePath, '*.vsf') do
  begin
    if TStyleManager.IsValidStyle(FileName, StyleInfo) then
    begin
      StyleName := ExtractFilename(FileName);
      { Style menu item }
      SetMenuItem;
      Action := TAction.Create(ActionManager);
      Action.Name := StringReplace(StyleInfo.Name, ' ', '', [rfReplaceAll]) + 'StyleSelectAction';
      Action.Caption := FileName;
      Action.OnExecute := ActionSelectStyleExecute;
      Action.Checked := TStyleManager.ActiveStyle.Name = StyleInfo.Name;
      ActionClientItem.Action := Action;
      ActionClientItem.Caption := StyleInfo.Name;
    end;
  end;
  { Windows }
  StyleName := 'Windows.vsf';
  SetMenuItem;
  Action := TAction.Create(ActionManager);
  Action.Name := 'WindowsStyleSelectAction';
  Action.Caption := STYLENAME_WINDOWS;
  Action.OnExecute := ActionSelectStyleExecute;
  Action.Checked := TStyleManager.ActiveStyle.Name = STYLENAME_WINDOWS;
  ActionClientItem.Action := Action;
  ActionViewStyle.Enabled := True;
end;

end.
