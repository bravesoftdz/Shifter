unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls,
  ThdTimer, BlockPanel, BCControls.ProgressPanel, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, Vcl.ToolWin, Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.StdStyleActnCtrls, Vcl.ImgList,
  BCControls.ImageList, System.Actions;

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
    ImageList: TImageList;
    MenuImageList: TBCImageList;
    SelectStyleAction: TAction;
    ViewStyleAction: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure ThreadedTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure NewGameActionExecute(Sender: TObject);
    procedure ScoresActionExecute(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure AboutActionExecute(Sender: TObject);
    procedure SelectStyleActionExecute(Sender: TObject);
    procedure ViewStyleActionExecute(Sender: TObject);
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
  Common, System.Math, Score, About, Vcl.Themes, BigIni, StyleHooks, System.IOUtils, System.Types;

const
  VIEW_MENU_ITEMINDEX = 1;
  VIEW_STYLE_MENU_ITEMINDEX = 0;

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
  BlockPanel.Idle := False;
end;

procedure TMainForm.OnGameStartWaiting(Sender: TObject);
begin
  ThreadedTimer.Enabled := True;
  ThreadedTimerTimer(Sender);
end;

procedure TMainForm.OnGameEndWaiting(Sender: TObject);
begin
  ThreadedTimer.Enabled := False;
end;

function TMainForm.GetActionClientItem(MenuItemIndex, SubMenuItemIndex: Integer): TActionClientItem;
begin
  Result := ActionMainMenuBar.ActionClient.Items[MenuItemIndex];
  Result := Result.Items[SubMenuItemIndex];
end;

procedure TMainForm.SelectStyleActionExecute(Sender: TObject);
var
  i, j: Integer;
  ActionCaption: string;
  Action: TAction;
  ActionClientItem: TActionClientItem;
  StyleInfo: TStyleInfo;
begin
  Action := Sender as TAction;
  ActionCaption := StringReplace(Action.Caption, '&', '', [rfReplaceAll]);

  if Action.Caption = StyleHooks.STYLENAME_WINDOWS then
    TStyleManager.TrySetStyle(ActionCaption)
  else
  if TStyleManager.IsValidStyle(ActionCaption, StyleInfo) then
  begin
    if Assigned(TStyleManager.Style[StyleInfo.Name]) then
      TStyleManager.TrySetStyle(StyleInfo.Name)
    else
      TStyleManager.SetStyle(TStyleManager.LoadFromFile(ActionCaption));
  end;

  with TBigIniFile.Create(Common.GetINIFilename) do
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

procedure TMainForm.ViewStyleActionExecute(Sender: TObject);
begin
  { dummy action }
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
  ViewStyleAction.Enabled := False;
  FilePath := IncludeTrailingPathDelimiter(Format('%s%s', [ExtractFilePath(ParamStr(0)), 'Styles']));
  if not DirectoryExists(FilePath) then
    Exit;

  for FileName in TDirectory.GetFiles(FilePath, '*.vsf') do
  begin
    if TStyleManager.IsValidStyle(FileName, StyleInfo) then
    begin
      StyleName := ExtractFileName(FileName);
      { Style menu item }
      SetMenuItem;
      Action := TAction.Create(ActionManager);
      Action.Name := StringReplace(StyleInfo.Name, ' ', '', [rfReplaceAll]) + 'StyleSelectAction';
      Action.Caption := FileName;
      Action.OnExecute := SelectStyleActionExecute;
      Action.Checked :=  TStyleManager.ActiveStyle.Name = StyleInfo.Name;
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
  Action.OnExecute := SelectStyleActionExecute;
  Action.Checked :=  TStyleManager.ActiveStyle.Name = STYLENAME_WINDOWS;
  ActionClientItem.Action := Action;
  ViewStyleAction.Enabled := True;
end;
    (*
procedure TMainForm.CreateStyleMenu;
var
  FilePath, FileName: string;
  StyleInfo: TStyleInfo;
  ActionClientItem: TActionClientItem;
  Action: TAction;
begin
  FilePath := IncludeTrailingPathDelimiter(Format('%s%s', [ExtractFilePath(ParamStr(0)), 'Styles']));
  if not DirectoryExists(FilePath) then
    Exit;

  for FileName in TDirectory.GetFiles(FilePath, '*.vsf') do
  begin
    if TStyleManager.IsValidStyle(FileName, StyleInfo) then
    begin
      ActionClientItem := GetActionClientItem(VIEW_MENU_ITEMINDEX, VIEW_STYLE_MENU_ITEMINDEX);
      ActionClientItem := ActionClientItem.Items.Add;

      Action := TAction.Create(ActionManager);
      Action.Name := StringReplace(StyleInfo.Name, ' ', '', [rfReplaceAll]) + 'StyleSelectAction';
      Action.Caption := FileName;
      Action.OnExecute := SelectStyleActionExecute;
      Action.Checked :=  TStyleManager.ActiveStyle.Name = StyleInfo.Name;
      ActionClientItem.Action := Action;
      ActionClientItem.Caption := StyleInfo.Name;
    end;
  end;
  { Windows }
  ActionClientItem := GetActionClientItem(VIEW_MENU_ITEMINDEX, VIEW_STYLE_MENU_ITEMINDEX);
  ActionClientItem := ActionClientItem.Items.Add;
  Action := TAction.Create(ActionManager);
  Action.Name := 'WindowsStyleSelectAction';
  Action.Caption := STYLENAME_WINDOWS;
  Action.OnExecute := SelectStyleActionExecute;
  Action.Checked :=  TStyleManager.ActiveStyle.Name = STYLENAME_WINDOWS;
  ActionClientItem.Action := Action;
end; *)

end.
