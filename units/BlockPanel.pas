unit BlockPanel;

interface

uses
  Vcl.ExtCtrls, System.Classes, Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.Graphics, System.SysUtils,
  ThdTimer, System.Types;

type
  TGameState = (gsRunning, gsIdle, gsDemo, gsGameOver, gsInitialize, gsStartLevel, gsScrollBlocks,
                gsCheckPossibleMoves, gsWaitingForFirstSelection, gsRemoveBlocks1,
                gsWaitingForSecondSelection, gsChangeBlocks, gsRemoveBlocks2, gsChangeBlocksBack,
                gsGivePoints, gsFillEmptyBlocks, gsScrollNewBlocks, gsGoNextLevel, gsRemoveBlocks3);

  TBlockPanel = class;

  TBlockType = (btSolid, btChanger);

  TBlock = class(TComponent)
  private
    FBlockType: TBlockType;
    FLocation: TPoint;
    FBlockRect: TRect;
    FBorderRect: TRect;
    FSelectionRect: TRect;
    FBkgColor: TColor;
    FBorderColor: TColor;
    FParent: TBlockPanel;
    FText: String;
    FTextColor: TColor;
    FSelected: Boolean;
    FRemove: Boolean;
    FImageList: TImageList;
    function GetImageIndex(Character: Char): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Parent: TBlockPanel read FParent;
    function PaintTo(Canvas: TCanvas): Boolean;
  published
    property BlockType: TBlockType read FBlockType write FBlockType;
    property X: Integer read FLocation.X write FLocation.X;
    property Y: Integer read FLocation.Y write FLocation.Y;
    property Color: TColor read FBkgColor write FBkgColor;
    property BorderColor: TColor read FBorderColor write FBorderColor;
    property Text: String read FText write FText;
    property TextColor: TColor read FTextColor write FTextColor;
    property Selected: Boolean read FSelected write FSelected;
    property BlockRect: TRect read FBlockRect write FBlockRect;
    property BorderRect: TRect read FBorderRect write FBorderRect;
    property SelectionRect: TRect read FSelectionRect write FSelectionRect;
    property ImageList: TImageList write FImageList;
  end;

  TTextBlock = class(TBlock)
  public
    function PaintTo(Canvas: TCanvas): Boolean;
  end;

  TPointsBlock = class(TBlock)
  public
    function PaintTo(Canvas: TCanvas): Boolean;
  end;

  TBlockPanel = class(TPanel)
  private
    FBitmap: TBitmap;
    FBkgBitmap: TBitmap;
    FPaintBox: TPaintBox;
    FTimer: TThreadedTimer;
    FBlocks: array [0..7, 0..7] of TBlock;
    FDemoBlocks: TList;
    FDemoTextBlocks: TList;
    FPointBlocks: TList;
    FDemoRunning: Boolean;
    FAngle, FTextAngle: Real;
    FGameState: TGameState;
    FMouseX: Integer;
    FMouseY: Integer;
    FMouseXClick: Integer;
    FMouseYClick: Integer;
    FSelection: array [0..1] of TPoint;
    FMouseClicked: Boolean;
    FBlockChangeSpeed: Integer;
    FBlockScrollSpeed: Integer;
    FPoints: Integer;
    FScore: Integer;
    FOnScoreChange: TNotifyEvent;
    FOnLevelChange: TNotifyEvent;
    FOnStartWaiting: TNotifyEvent;
    FOnEndWaiting: TNotifyEvent;
    FLevel: Integer;
    FBlockCounts: array [0..7] of Integer;
    FGameOver: Boolean;
    FOwner: TForm;
    FIdle: Boolean;
    FIdleState: TGameState;
    FImageList: TImageList;
    procedure SetInterval(const Value: Integer);
    function GetInterval: Integer;
    function GetRunning: Boolean;
    procedure SetRunning(const Value: Boolean);
    procedure DoTimer(sender: TObject);
    procedure CreateBackgroundBitmap;
    procedure CreateDemoBlocks;
    procedure CreateDemoTextBlocks;
    procedure CreateBlocks;
    procedure DestroyBlocks;
    function GetColor(Tag: Integer): TColor;
    function GetBorderColor(Tag: Integer): TColor;
    function GetText(Tag: Integer): String;
    function GetBlockWidth: Real;
    function GetBlockHeight: Real;
    procedure SetSelectionsDisabled;
    procedure SetSelectedBlock(Index: Integer);
    function AreSelectionBlocksSame: Boolean;
    function IsMouseOverPlayArea(Y: Integer): Boolean;
    function IsMouseOverSecondSelection(X, Y: Integer): Boolean;
    function ScrollBlocks: Boolean;
    function MoveSelectedBlocks: Boolean;
    procedure ChangeSelectedBlocks;
    procedure RunDemo;
    function GetBlockRect(X, Y, Border: Integer): TRect;
    procedure SetBlockRects(Block: TBlock);
    function RemoveBlocks1: Boolean;
    function RemoveBlocks2: Boolean;
    function RemoveMarkedBlocks: Boolean;
    procedure FillEmptyBlocks;
    procedure CreatePointBlocks;
    procedure DestroyPointBlocks;
    function CheckPossibleMoves: Boolean;
    function RemoveBlocks3: Boolean;
    procedure SetBlockCounts;
    function GetSeed: Integer;
    function GoNextLevel: Boolean;
    procedure SetIdle(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent; ImageList: TImageList); reintroduce; overload;
    destructor Destroy; override;
    procedure SetGameOver;
    procedure NewGame;
  protected
    procedure Display;
    procedure BlockPanelPaint(sender: TObject);
    procedure BlockPanelResize(Sender: TObject);
    procedure BlockPanelMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure BlockPanelMouseClick(Sender: TObject);
    procedure ReDraw;
    procedure DrawBackGround(Bitmap: TBitmap);
    procedure DrawBlocksLeft(Bitmap: TBitmap);
  published
    property Interval: Integer read GetInterval write SetInterval;
    property Running: Boolean read GetRunning write SetRunning;
    property DemoRunning: Boolean read FDemoRunning write FDemoRunning;
    property BlockWidth: Real read GetBlockWidth;
    property BlockHeight: Real read GetBlockHeight;
    property Score: Integer read FScore;
    property Level: Integer read FLevel;
    property OnScoreChange: TNotifyEvent read FOnScoreChange write FOnScoreChange;
    property OnLevelChange: TNotifyEvent read FOnLevelChange write FOnLevelChange;
    property OnStartWaiting: TNotifyEvent read FOnStartWaiting write FOnStartWaiting;
    property OnEndWaiting: TNotifyEvent read FOnEndWaiting write FOnEndWaiting;
    property GameOver: Boolean read FGameOver write FGameOver;
    property Idle: Boolean read FIdle write SetIdle;
  end;


implementation

uses
  BCCommon.Lib, BCCommon.Messages, Math;

{ TBlock }

constructor TBlock.Create(AOwner: TComponent);

  function RandomBlockType: TBlockType;
  var
    Seed1, Seed2: Integer;
  begin
    Randomize;
    Seed1 := Random(400);
    Seed2 := Random(400);
    if Seed1 = Seed2 then
      Result := btChanger
    else
      Result := btSolid
  end;

begin
  inherited;
  X := 0;
  Y := 0;
  FSelected := False;
  FRemove := False;
  FBlockType := RandomBlockType;
  if AOwner is TBlockPanel then
    FParent := TBlockPanel(AOwner);
end;

destructor TBlock.Destroy;
begin
  inherited;
end;

function TBlock.GetImageIndex(Character: Char): Integer;
begin
  case Character of
    'S': Result := 0;
    'H': Result := 1;
    'I': Result := 2;
    'F': Result := 3;
    'T': Result := 4;
    'E': Result := 5;
    'R': Result := 6
  else
    Result := 7;
  end;
end;

function TBlock.PaintTo(Canvas: TCanvas): Boolean;
var
  TmpBmp: TBitmap;
  IsPointInRect: Boolean;
  Seed: Integer;
begin

  IsPointInRect := PointInRect(Point(Parent.FMouseX, Parent.FMouseY), BorderRect);

  if Selected or
     ((Parent.FGameState = gsWaitingForSecondSelection) and IsPointInRect and
     Parent.IsMouseOverSecondSelection(Parent.FMouseX, Parent.FMouseY)) then
  with Canvas do
  begin
    Pen.Width := 2;
    Pen.Style := psInsideFrame;
    Pen.Color := clRed;
    Rectangle(SelectionRect);
    Pen.Style := psSolid;
    Pen.Width := 1;
  end;

  if FBlockType = btChanger then
  begin
    Seed := FParent.GetSeed;
    Tag := Random(Seed);
    FBkgColor := FParent.GetColor(Tag);
    FBorderColor := FParent.GetBorderColor(Tag);
    FText := FParent.GetText(Tag);
    FTextColor := FBorderColor;
  end;

  Canvas.Pen.Color := clBlack;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FBorderColor;
  Canvas.Rectangle(BorderRect);

  TmpBmp := TBitmap.Create;
  if Assigned(FImageList) then
  begin
    TmpBmp.Width := 200;
    TmpBmp.Height := 200;
    FImageList.GetBitmap(GetImageIndex(FText[1]), TmpBmp);
    Canvas.CopyRect(BlockRect, TmpBmp.Canvas, Rect(0,0,199,199));
  end;
  TmpBmp.Free;

  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(BlockRect);

  Result := True;
end;

{ TTextBlock }

function TTextBlock.PaintTo(Canvas: TCanvas): Boolean;
begin
  with Canvas do
  begin
    Brush.Style := bsClear;
    Font.Style := [fsBold];
    Font.Color := FTextColor;
    TextOut(X,Y,FText);
  end;
  Result := True;
end;

{ TPointsBlock }

function TPointsBlock.PaintTo(Canvas: TCanvas): Boolean;
var
  TmpBmp: TBitmap;
begin
  TmpBmp := TBitmap.Create;
  TmpBmp.Width := 48;;
  TmpBmp.Height := 32;
  TmpBmp.Canvas.Font.Style := [fsBold];
  TmpBmp.Canvas.Font.Color := FTextColor;
  TmpBmp.Canvas.Font.Size := 22;
  TmpBmp.Canvas.TextRect(Rect(0,0,47,31),5,-2,FText);
  Canvas.CopyMode := cmSrcAnd;
  Canvas.CopyRect(BlockRect, TmpBmp.Canvas, Rect(0,0,47,31));
  Canvas.CopyMode := cmSrcCopy;
  TmpBmp.Free;

  Result := True;
end;

{ TBlockPanel }

constructor TBlockPanel.Create(AOwner: TComponent; ImageList: TImageList);
begin
  FTimer := TThreadedTimer.Create(self);
  inherited Create(AOwner);
  BevelOuter := bvNone;
  DoubleBuffered := True;
  FImageList := ImageList;
  FBitmap := TBitmap.Create;
  FPaintBox := TPaintBox.Create(self);
  OnResize := BlockPanelResize;
  FPaintBox.Parent := self;
  FPaintBox.OnPaint := BlockPanelPaint;
  FPaintBox.OnMouseMove := BlockPanelMouseMove;
  FPaintBox.OnClick := BlockPanelMouseClick;
  FTimer.OnTimer := DoTimer;
  FDemoRunning := True;
  Interval := 50;
  FAngle := 0;
  FTextAngle := 0;
  FLevel := 0;
  FGameState := gsInitialize;
  CreateBackgroundBitmap;
  CreateDemoBlocks;
  CreateDemoTextBlocks;
  FPointBlocks := TList.Create;
  FOwner := TForm(AOwner);
  FIdle := False;
end;

destructor TBlockPanel.Destroy;
begin
  inherited;
end;

function TBlockPanel.GetBlockRect(X, Y, Border: Integer): TRect;
begin
  Result := Rect(X+Border, Y+Border, Round(X+BlockWidth-Border), Round(Y+BlockHeight-Border));
end;

procedure TBlockPanel.SetBlockRects(Block: TBlock);
begin
  Block.FBlockRect := GetBlockRect(Block.X, Block.Y, 4);
  Block.FBorderRect := GetBlockRect(Block.X, Block.Y, 2);
  Block.FSelectionRect := GetBlockRect(Block.X, Block.Y, 0);
end;

function TBlockPanel.IsMouseOverSecondSelection(X, Y: Integer): Boolean;
var
  APoint: TPoint;
  bTop, bLeft, bRight, bBottom: Boolean;
begin
  APoint := Point(X, Y);

  bTop := False;
  bLeft := False;
  bRight := False;
  bBottom := False;

  if FSelection[0].X-1 >= 0 then
    bLeft := PointInRect(APoint, FBlocks[FSelection[0].X-1, FSelection[0].Y].FBorderRect);

  if FSelection[0].Y-1 >= 0 then
    bTop := PointInRect(APoint, FBlocks[FSelection[0].X, FSelection[0].Y-1].FBorderRect);

  if FSelection[0].X+1 <= 7 then
    bRight := PointInRect(APoint, FBlocks[FSelection[0].X+1, FSelection[0].Y].FBorderRect);

  if FSelection[0].Y+1 <= 7 then
    bBottom := PointInRect(APoint, FBlocks[FSelection[0].X, FSelection[0].Y+1].FBorderRect);

  Result := bLeft OR bTop OR bRight OR bBottom OR
    PointInRect(APoint, FBlocks[FSelection[0].X, FSelection[0].Y].FBorderRect);
end;

function TBlockPanel.GetBlockWidth: Real;
begin
  Result := FBitmap.Width / 8;
end;

function TBlockPanel.GetBlockHeight: Real;
begin
  Result := FBitmap.Height / 9;
end;

function TBlockPanel.GetColor(Tag: Integer): TColor;
begin
  case Tag of
    0: Result := clGray;
    1: Result := clMaroon;
    2: Result := clOlive;
    3: Result := clGreen;
    4: Result := clTeal;
    5: Result := clNavy;
    6: Result := clPurple;
  else
    Result := clBlack;
  end;
end;

function TBlockPanel.GetBorderColor(Tag: Integer): TColor;
begin
  case Tag of
    0: Result := clSilver;
    1: Result := clRed;
    2: Result := clYellow;
    3: Result := clLime;
    4: Result := clAqua;
    5: Result := clBlue;
    6: Result := clFuchsia;
  else
    Result := clWhite;
  end;
end;

function TBlockPanel.GetText(Tag: Integer): String;
begin
  case Tag of
    0: Result := 'S';
    1: Result := 'H';
    2: Result := 'I';
    3: Result := 'F';
    4: Result := 'T';
    5: Result := 'E';
    6: Result := 'R';
    else
      Result := '!';
  end;
end;

function TBlockPanel.GetSeed: Integer;
begin
  if FLevel < 8 then
    Result := 6
  else
  if FLevel < 12 then
    Result := 7
  else Result := 8;
end;

procedure TBlockPanel.CreateBlocks;
var
  Block: TBlock;
  x, y, Seed: Integer;
  function ThreeInARow(x, y, Tag: Integer): Boolean;
  var
    x1, x2, y1, y2: Integer;
  begin
    Result := True;
    x1 := x; x2 := x; y1 := y; y2 := y;
    Dec(x1,2); Dec(x2);
    Dec(y1,2); Dec(y2);
    { check horizontal }
    if x1 >= 0 then
    if (FBlocks[x1, y].Tag = Tag) and
       (FBlocks[x2, y].Tag = Tag) then
      exit;
    { check vertical }
    if y1 >= 0 then
    if (FBlocks[x, y1].Tag = Tag) and
       (FBlocks[x, y2].Tag = Tag) then
       exit;

    Result := False;
  end;
begin
  Randomize;
  Seed := GetSeed;

  for x := 0 to 7 do
    for y := 0 to 7 do
    begin
    Block := TBlock.Create(self);
    repeat
      Block.Tag := Random(Seed);
    until not ThreeInARow(x, y, Block.Tag);
    Block.Color := GetColor(Block.Tag);
    Block.BorderColor := GetBorderColor(Block.Tag);
    Block.ImageList := FImageList;
    Block.Text := GetText(Block.Tag);
    Block.TextColor := Block.BorderColor;
    { set blocks outside because those are scrolled later }
    Block.X := Round(x*BlockWidth);
    Block.Y := Round(y*BlockHeight) - Height;
    SetBlockRects(Block);
    FBlocks[x, y] := Block;
    end;
end;

procedure TBlockPanel.DestroyBlocks;
var
  x, y: Integer;
begin
  for x := 0 to 7 do
    for y := 0 to 7 do
    begin
      FBlocks[x, y].Free;
      FBlocks[x, y] := nil;
    end;
end;

procedure TBlockPanel.CreateDemoTextBlocks;
var
  Block: TTextBlock;
  Text: String;
  i: Integer;
begin
  FDemoTextBlocks := TList.Create;
  Text := 'Press F2 to start a new game!';
  for i := 0 to Length(Text) - 1 do
  begin
    Block := TTextBlock.Create(self);
    Block.X := 0;
    Block.Y := 0;
    Block.BorderColor := clBtnShadow;
    Block.TextColor := clBlack;
    Block.Text := Text[i+1];
    FDemoTextBlocks.Add(Block);
  end;
  { set 'F2' to red }
  TBlock(FDemoTextBlocks.Items[6]).TextColor := clRed;
  TBlock(FDemoTextBlocks.Items[7]).TextColor := clRed;
end;

procedure TBlockPanel.SetSelectionsDisabled;
var
  i: Integer;
begin
  for i := 0 to 1 do
    FBlocks[FSelection[i].X, FSelection[i].Y].Selected := False;
end;

procedure TBlockPanel.CreateDemoBlocks;
var
  Block: TBlock;
  Text: String;
  i: Integer;
begin
  FDemoBlocks := TList.Create;
  Text := 'SHIFTER';
  for i := 0 to Length(Text) - 1 do
  begin
    Block := TBlock.Create(self);
    Block.X := 0;
    Block.Y := 0;
    Block.ImageList := FImageList;
    Block.FBlockType := btSolid;
    SetBlockRects(Block);
    Block.Text := Text[i+1];
    FDemoBlocks.Add(Block);
  end;
  { set colors }
  TBlock(FDemoBlocks.Items[0]).Color := clGray;
  TBlock(FDemoBlocks.Items[0]).TextColor := clSilver;
  TBlock(FDemoBlocks.Items[0]).BorderColor := clSilver;
  TBlock(FDemoBlocks.Items[1]).Color := clMaroon;
  TBlock(FDemoBlocks.Items[1]).TextColor := clRed;
  TBlock(FDemoBlocks.Items[1]).BorderColor := clRed;
  TBlock(FDemoBlocks.Items[2]).Color := clOlive;
  TBlock(FDemoBlocks.Items[2]).TextColor := clYellow;
  TBlock(FDemoBlocks.Items[2]).BorderColor := clYellow;
  TBlock(FDemoBlocks.Items[3]).Color := clGreen;
  TBlock(FDemoBlocks.Items[3]).TextColor := clLime;
  TBlock(FDemoBlocks.Items[3]).BorderColor := clLime;
  TBlock(FDemoBlocks.Items[4]).Color := clTeal;
  TBlock(FDemoBlocks.Items[4]).TextColor := clAqua;
  TBlock(FDemoBlocks.Items[4]).BorderColor := clAqua;
  TBlock(FDemoBlocks.Items[5]).Color := clNavy;
  TBlock(FDemoBlocks.Items[5]).TextColor := clBlue;
  TBlock(FDemoBlocks.Items[5]).BorderColor := clBlue;
  TBlock(FDemoBlocks.Items[6]).Color := clPurple;
  TBlock(FDemoBlocks.Items[6]).TextColor := clFuchsia;
  TBlock(FDemoBlocks.Items[6]).BorderColor := clFuchsia;
end;

procedure TBlockPanel.Setinterval(const Value: Integer);
begin
  FTimer.Interval := Value;
end;

procedure TBlockPanel.CreateBackgroundBitmap;
var
  i, j, k: Integer;
begin
  FBkgBitmap := TBitmap.Create;
  FBkgBitmap.Width := 8;
  FBkgBitmap.Height := 9;
  for i := 0 to 7 do
  begin
    if i mod 2 = 0 then
      k := 0
    else k := 1;
    for j := 0 to 3 do
    begin
      FBkgBitmap.Canvas.Pixels[k,i] := clBtnFace;
      k := k + 2;
    end;
  end;

  FBkgBitmap.Canvas.Pixels[0,8] := clGray;
  FBkgBitmap.Canvas.Pixels[1,8] := clMaroon;
  FBkgBitmap.Canvas.Pixels[2,8] := clOlive;
  FBkgBitmap.Canvas.Pixels[3,8] := clGreen;
  FBkgBitmap.Canvas.Pixels[4,8] := clTeal;
  FBkgBitmap.Canvas.Pixels[5,8] := clNavy;
  FBkgBitmap.Canvas.Pixels[6,8] := clPurple;
  FBkgBitmap.Canvas.Pixels[7,8] := clBlack;
end;

function TBlockPanel.GetInterval: Integer;
begin
  Result := FTimer.Interval;
end;

procedure TBlockPanel.BlockPanelResize(sender:TObject);
var
  x, y: Integer;
  Block: TBlock;
begin
  FBitmap.Width := Width;
  FBitmap.Height := Height;
  FPaintbox.Width := Width;
  FPaintbox.Height := Height;

  FBlockChangeSpeed := (Width div 8) div 6;
  FBlockScrollSpeed := (Height div 9) div 3;

  if (FGameState <> gsInitialize) and
     (FGameState <> gsStartLevel) and
     (FGameState <> gsScrollBlocks) then
  for x := 0 to 7 do
    for y := 0 to 7 do
    begin
      Block := FBlocks[x, y];
      if Block <> nil then
      begin
      Block.X := Round(x*BlockWidth);
      Block.Y := Round(y*BlockHeight);
      SetBlockRects(Block);
      end;
    end;

  Display;
end;

procedure TBlockPanel.BlockPanelMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  FMouseX := X;
  FMouseY := Y;
end;

function TBlockPanel.IsMouseOverPlayArea(Y: Integer): Boolean;
begin
  Result := Y < BlockHeight * 8
end;

procedure TBlockPanel.BlockPanelMouseClick(Sender: TObject);
begin
  FMouseXClick := FMouseX;
  FMouseYClick := FMouseY;

  if (FGameState = gsWaitingForFirstSelection) and
      IsMouseOverPlayArea(FMouseYClick) then
    FMouseClicked := True
  else
  if (FGameState = gsWaitingForSecondSelection) and
     IsMouseOverPlayArea(FMouseYClick) and IsMouseOverSecondSelection(FMouseXClick, FMouseYClick) then
    FMouseClicked := True;
end;

procedure TBlockPanel.BlockPanelPaint(sender:TObject);
begin
  Display;
end;

function TBlockPanel.AreSelectionBlocksSame: Boolean;
begin
  Result := FBlocks[FSelection[0].X, FSelection[0].Y] =
            FBlocks[FSelection[1].X, FSelection[1].Y]
end;

procedure TBlockPanel.SetSelectedBlock(Index: Integer);
var
  i, j: Integer;
begin
  i := 0;
  while BlockWidth * i <= FMouseXClick do
    Inc(i);
  j := 0;
  while BlockHeight * j <= FMouseYClick do
    Inc(j);
  FSelection[Index].X := i - 1;
  FSelection[Index].Y := j - 1;

  FBlocks[i - 1, j - 1].Selected := True;
end;

function TBlockPanel.ScrollBlocks: Boolean;
var
  i, j: Integer;
  Block: TBlock;
begin
  Result := True;
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      Block := FBlocks[i, j];
      if Block <> nil then
        begin
          Block.X := Round(i*BlockWidth);
          if Block.Y < Round(j*BlockHeight) - FBlockScrollSpeed then
          begin
            Block.Y := Block.Y + FBlockScrollSpeed;
            Result := False
          end
          else
            Block.Y := Round(j*BlockHeight);
          SetBlockRects(Block);
        end;
    end;
end;

procedure TBlockPanel.ChangeSelectedBlocks;
var
  Block: TBlock;
  TmpPoint: TPoint;
begin
  Block := FBlocks[FSelection[0].X, FSelection[0].Y];
  FBlocks[FSelection[0].X, FSelection[0].Y] := FBlocks[FSelection[1].X, FSelection[1].Y];
  FBlocks[FSelection[1].X, FSelection[1].Y] := Block;
  TmpPoint := FSelection[0];
  FSelection[0] := FSelection[1];
  FSelection[1] := TmpPoint;
end;

function TBlockPanel.MoveSelectedBlocks: Boolean;
var
  SelectedBlock1, SelectedBlock2: TBlock;
begin
  Result := False;
  SelectedBlock1 := FBlocks[FSelection[0].X, FSelection[0].Y];
  SelectedBlock2 := FBlocks[FSelection[1].X, FSelection[1].Y];
  if FSelection[0].X < FSelection[1].X then
  begin
    SelectedBlock1.X := SelectedBlock1.X + FBlockChangeSpeed;
    SelectedBlock2.X := SelectedBlock2.X - FBlockChangeSpeed;
    if SelectedBlock2.X < FSelection[0].X * BlockWidth then
      Result := True;
  end;

  if FSelection[0].Y < FSelection[1].Y then
  begin
    SelectedBlock1.Y := SelectedBlock1.Y + FBlockChangeSpeed;
    SelectedBlock2.Y := SelectedBlock2.Y - FBlockChangeSpeed;
    if SelectedBlock2.Y < FSelection[0].Y * BlockHeight then
      Result := True;
  end;

  if FSelection[0].X > FSelection[1].X then
  begin
    SelectedBlock1.X := SelectedBlock1.X - FBlockChangeSpeed;
    SelectedBlock2.X := SelectedBlock2.X + FBlockChangeSpeed;
    if SelectedBlock1.X < FSelection[1].X * BlockWidth then
      Result := True;
  end;

  if FSelection[0].Y > FSelection[1].Y then
  begin
    SelectedBlock1.Y := SelectedBlock1.Y - FBlockChangeSpeed;
    SelectedBlock2.Y := SelectedBlock2.Y + FBlockChangeSpeed;
    if SelectedBlock1.Y < FSelection[1].Y * BlockHeight then
      Result := True;
  end;

  SetBlockRects(SelectedBlock1);
  SetBlockRects(SelectedBlock2);
end;

{ checks if there are blocks to remove }
function TBlockPanel.RemoveBlocks2: Boolean;
var
  SelectedBlock1, SelectedBlock2: TBlock;

  procedure MarkHorizontalBlocks(Block: TBlock; Selection: Integer);
  var
    i, j, k, Count: Integer;
  begin
    i := 0;
    while i < 8 do
    begin
      j := i;
      Count := 0;
      while (j < 8) and (Block.Tag = FBlocks[j, FSelection[Selection].Y].Tag) and
        (FBlocks[j, FSelection[Selection].Y].FBlockType = btSolid) do
      begin
        Inc(Count);
        Inc(j);
      end;
      if (Count > 2) then
        for k := i to j - 1 do
          FBlocks[k, FSelection[Selection].Y].FRemove := True;
      if i <> j then
        i := j
      else
        Inc(i);
    end;
  end;

  procedure MarkVerticalBlocks(Block: TBlock; Selection: Integer);
  var
    i, j, k, Count: Integer;
  begin
    i := 0;
    while i < 8 do
    begin
      j := i;
      Count := 0;
      while (j < 8) and (Block.Tag = FBlocks[FSelection[Selection].X, j].Tag) and
        (FBlocks[FSelection[Selection].X, j].FBlockType = btSolid) do
      begin
        Inc(Count);
        Inc(j);
      end;
      if (Count > 2) then
        for k := i to j - 1 do
          FBlocks[FSelection[Selection].X, k].FRemove := True;
      if i <> j then
        i := j
      else
        Inc(i);
    end;
  end;

begin
  SelectedBlock1 := FBlocks[FSelection[0].X, FSelection[0].Y];
  SelectedBlock2 := FBlocks[FSelection[1].X, FSelection[1].Y];
  { remove horizontal SelectedBlock1 }
  MarkHorizontalBlocks(SelectedBlock1, 0);
  { remove vertical SelectedBlock1 }
  MarkVerticalBlocks(SelectedBlock1, 0);
  { remove horizontal SelectedBlock2 }
  MarkHorizontalBlocks(SelectedBlock2, 1);
  { remove vertical SelectedBlock2 }
  MarkVerticalBlocks(SelectedBlock2, 1);
  SetSelectionsDisabled;

  Result := RemoveMarkedBlocks;
end;

function TBlockPanel.RemoveMarkedBlocks: Boolean;
var
  i, j: Integer;
begin
  Result := False;

  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      if FBlocks[i, j].FRemove then
      begin
        if FBlockCounts[FBlocks[i, j].Tag] > 0 then
          Dec(FBlockCounts[FBlocks[i, j].Tag]);
        Result := True;
        FBlocks[i, j].Free;
        FBlocks[i, j] := nil;
      end;
    end;
end;

procedure TBlockPanel.RunDemo;
var
  i: Integer;
  TextBlockWidth: Real;
  Block: TBlock;
  CosAngle, SinAngle: Real;
begin
  { demo logic }
  FAngle := FAngle + 0.1;
  CosAngle := Cos(FAngle);
  SinAngle := Sin(FAngle);
  for i := 0 to FDemoBlocks.Count-1 do
  begin
    Block := FDemoBlocks[i];
    Block.X := Round((i-3)*BlockWidth*CosAngle + SinAngle*BlockWidth + 7*BlockWidth / 2);
    Block.Y := Round((i-3)*BlockWidth*SinAngle + CosAngle*BlockWidth + 7*BlockWidth / 2);
    SetBlockRects(Block);
  end;

  FTextAngle := FTextAngle - 0.1 * (FDemoTextBlocks.Count-1);
  TextBlockWidth := Trunc(FBitmap.Width/(FDemoTextBlocks.Count+2));
  for i := 0 to FDemoTextBlocks.Count-1 do
  begin
    FTextAngle := FTextAngle + 0.1;
    Block := FDemoTextBlocks[i];
    Block.X := Round(i*TextBlockWidth + (FBitmap.Width-FDemoTextBlocks.Count*TextBlockWidth) / 2);
    Block.Y := Round(TextBlockWidth*Cos(FTextAngle) + FBitmap.Height - 8*TextBlockWidth);
  end;
end;

procedure TBlockPanel.SetIdle(const Value: Boolean);
begin
  FIdle := Value;

  if FIdle then
  begin
    FIdleState := FGameState;
    FGameState := gsIdle
  end
  else
    FGameState := FIdleState;
end;

procedure TBlockPanel.FillEmptyBlocks;
var
  i, j, k, Seed: Integer;
  Block: TBlock;

  function GetVerticalBlock(i, j: Integer): TBlock;
  var
    Found: Boolean;
  begin
    Found := False;
    Result := nil;

    while (j >= 0) and not Found do
    begin
      if FBlocks[i, j] <> nil then
      begin
        Found := True;
        Result := FBlocks[i, j];
        FBlocks[i, j] := nil;
      end;
      Dec(j);
    end;
  end;
begin
  Seed := GetSeed;
  { move blocks at the bottom... }
  for i := 0 to 7 do
    for j := 7 downto 0 do
      if FBlocks[i, j] = nil then
        FBlocks[i, j] := GetVerticalBlock(i, j-1);
  { and fill empty slots }
  for i := 0 to 7 do
  begin
    k := 1;
    for j := 7 downto 0 do
    if FBlocks[i, j] = nil then
    begin
      Block := TBlock.Create(self);
      Block.Tag := Random(Seed);
      Block.Color := GetColor(Block.Tag);
      Block.BorderColor := GetBorderColor(Block.Tag);
      Block.ImageList := FImageList;
      Block.Text := GetText(Block.Tag);
      Block.TextColor := Block.BorderColor;
      { set blocks outside because those are scrolled later }
      Block.X := Round(i*BlockWidth);
      Block.Y := -Round(k*BlockHeight);
      Inc(k);
      SetBlockRects(Block);
      FBlocks[i, j] := Block;
    end;
  end;
end;

procedure TBlockPanel.DestroyPointBlocks;
var
  i: Integer;
begin
  { release created blocks }
  for i := 0 to FPointBlocks.Count - 1 do
    TPointsBlock(FPointBlocks.Items[i]).Free;
  { clear a pointer list }
  FPointBlocks.Clear;
end;

procedure TBlockPanel.CreatePointBlocks;
var
  i, j: Integer;
  Block: TPointsBlock;
begin
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      if FBlocks[i, j] = nil then
      begin
        Block := TPointsBlock.Create(self);
        Block.Text := IntToStr(FPoints);
        FScore := FScore + FPoints;
        if Assigned(FOnScoreChange) then
          FOnScoreChange(Self);
        Block.TextColor := clBlack;
        Block.X := Round(i*BlockWidth);
        Block.Y := Round(j*BlockHeight);
        SetBlockRects(Block);
        FPointBlocks.Add(Block)
      end;
    end;
end;

{ checks if there is possible block moves }
function TBlockPanel.CheckPossibleMoves: Boolean;
var
  i, j, m, Count: Integer;
  
  function GetBlockTag(x, y: Integer): Integer;
  begin
    if (x < 0) or (y < 0) or (x > 7) or (y > 7) then
      Result := -1
    else Result := FBlocks[x, y].Tag
  end;
  function TestBlocks(x1, y1, x2, y2: Integer): Boolean;
  begin
    if GetBlockTag(x1, y1) = GetBlockTag(x2, y2) then
      Result := True
    else Result := False
  end;
begin
  Result := False;

  for i := 0 to 7 do
    for j := 0 to 7 do
      if (TestBlocks(i, j, i+1, j-1) and (TestBlocks(i, j, i+2, j) or TestBlocks(i, j, i+2, j-1))) or
         (TestBlocks(i, j, i+1, j+1) and (TestBlocks(i, j, i+2, j) or TestBlocks(i, j, i+2, j+1))) or
         (TestBlocks(i, j, i+1, j+1) and (TestBlocks(i, j, i, j+2) or TestBlocks(i, j, i+1, j+2))) or
         (TestBlocks(i, j, i-1, j+1) and (TestBlocks(i, j, i, j+2) or TestBlocks(i, j, i-1, j+2))) or
         (TestBlocks(i, j, i+1, j) and (TestBlocks(i, j, i+2, j-1) or TestBlocks(i, j, i+2, j+1))) or
         (TestBlocks(i, j, i, j+1) and (TestBlocks(i, j, i+1, j+2) or TestBlocks(i, j, i-1, j+2))) then
         begin
           Result := True;
           Exit;
         end;

   for i := 0 to 4 do
     for j := 0 to 7 do
     begin
       Count := 0;
       { horizontal }
       for m := 0 to 3 do
         if TestBlocks(i, j, i+m, j) then
           Inc(Count);
       if Count > 2 then
       begin
         Result := True;
         Exit
       end;
     end;

   for i := 0 to 7 do
     for j := 0 to 4 do
     begin
       Count := 0;
       { vertical }
       for m := 0 to 3 do
         if TestBlocks(i, j, i, j+m) then
           Inc(Count);
       if Count > 2 then
       begin
         Result := True;
         Exit
       end;
     end;

   for i := 0 to 7 do
     for j := 0 to 7 do
       if FBlocks[i, j].FBlockType = btChanger then
       begin
         Result := True;
         Exit
       end
end;

function TBlockPanel.RemoveBlocks1: Boolean;
var
  i, j: Integer;
begin
  for i := 0 to 7 do
    for j := 0 to 7 do
      if (FBlocks[FSelection[0].X, FSelection[0].Y].Tag = FBlocks[i, j].Tag) and
         (FBlocks[i, j].FBlockType = btSolid) then
        FBlocks[i, j].FRemove := True;

  Result := RemoveMarkedBlocks;
end;

function TBlockPanel.RemoveBlocks3: Boolean;
var
  m, i, j, k, count: Integer;
begin
  { horizontal }
  for m := 0 to 7 do
  begin
  i := 0;
  while i < 8 do
    begin
      j := i;
      Count := 0;
      while (j < 8) and (FBlocks[j, m].Tag = FBlocks[i, m].Tag) and
        (FBlocks[j, m].FBlockType = btSolid) and (FBlocks[i, m].FBlockType = btSolid) do
      begin
        Inc(Count);
        Inc(j);
      end;
      if (Count > 2) then
      for k := i to j - 1 do
        FBlocks[k, m].FRemove := True;
      if i <> j then
        i := j
      else
        Inc(i);
    end;
  end;
  { vertical }
  for m := 0 to 7 do
  begin
  i := 0;
  while i < 8 do
    begin
      j := i;
      Count := 0;
      while (j < 8) and (FBlocks[m, j].Tag = FBlocks[m, i].Tag) and
        (FBlocks[m, j].FBlockType = btSolid) and (FBlocks[m, i].FBlockType = btSolid) do
      begin
        Inc(Count);
        Inc(j);
      end;
      if (Count > 2) then
      for k := i to j - 1 do
        FBlocks[m, k].FRemove := True;
      if i <> j then
        i := j
      else
        Inc(i);
    end;
  end;

  Result := RemoveMarkedBlocks;
end;

procedure TBlockPanel.SetBlockCounts;
var
  i, j: Integer;
begin
  j := GetSeed - 1;

  for i := 0 to 7 do
    FBlockCounts[i] := 0;

  for i := 0 to j do
    FBlockCounts[i] := FLevel + 2;
end;

function TBlockPanel.GoNextLevel: Boolean;
var
  i, j: Integer;
begin
  Result := True;
  j := GetSeed - 1;

  for i := 0 to j do
    if FBlockCounts[i] > 0 then
      Result := False;
end;

procedure TBlockPanel.SetGameOver;
begin
  FGameState := gsGameOver;
end;

procedure TBlockPanel.DoTimer(Sender: TObject);
var
  bDraw: Boolean;
begin
  bDraw := False;

  if not DemoRunning then
  begin
    { game logic }
    case FGameState of
      gsIdle:
        ;

      gsGameOver:
        FGameOver := True;

      gsInitialize:
      begin
        Inc(FLevel);
        if Assigned(FOnLevelChange) then
          FOnLevelChange(Self);
        SetBlockCounts;
        FGameState := gsStartLevel;
      end;

      gsStartLevel:
      begin
        DestroyBlocks;
        CreateBlocks;
        FGameState := gsScrollBlocks;
      end;

      gsScrollBlocks:
      begin
         bDraw := True;
         if ScrollBlocks then
           FGameState := gsCheckPossibleMoves;
      end;

      gsCheckPossibleMoves:
      begin
        if not CheckPossibleMoves then
        begin
          BCCommon.Messages.ShowMessage('No more moves.');
          FGameState := gsStartLevel
        end
        else
        begin
          if Assigned(FOnStartWaiting) then
            FOnStartWaiting(Self);
          FGameState := gsWaitingForFirstSelection;
        end;
      end;

      gsWaitingForFirstSelection:
      begin
        bDraw := True;
        if FMouseClicked then
        begin
          SetSelectedBlock(0);
          FMouseClicked := False;
          if FBlocks[FSelection[0].X, FSelection[0].Y].BlockType = btSolid then
            FGameState := gsWaitingForSecondSelection
          else
          begin
            FBlocks[FSelection[0].X, FSelection[0].Y].BlockType := btSolid;
            Sleep(300);
            FGameState := gsRemoveBlocks1
          end;
        end;
      end;

      gsRemoveBlocks1:
      begin
        bDraw := True;
        if not RemoveBlocks1 then
          FGameState := gsWaitingForFirstSelection
        else
        begin
          FPoints := 10;
          CreatePointBlocks;
          FGameState := gsGivePoints;
        end
      end;

      gsWaitingForSecondSelection:
      begin
        bDraw := True;
        if FMouseClicked then
        begin
          if Assigned(FOnEndWaiting) then
            FOnEndWaiting(Self);
          SetSelectedBlock(1);
          FMouseClicked := False;
          FGameState := gsChangeBlocks
        end;
      end;

      gsChangeBlocks:
      begin
        bDraw := True;
        { do nothing if FSelectionBlocks are same }
        if AreSelectionBlocksSame then
        begin
          SetSelectionsDisabled;
          if Assigned(FOnStartWaiting) then
            FOnStartWaiting(Self);
          FGameState := gsWaitingForFirstSelection;
        end
        else { otherwise change blocks }
        if MoveSelectedBlocks then
        begin
          ChangeSelectedBlocks;
          FGameState := gsRemoveBlocks2;
          BlockPanelResize(Sender);
        end;
      end;

      gsRemoveBlocks2:
      begin
        bDraw := True;
        if not RemoveBlocks2 then
          { if there isn't any removable blocks, change blocks back }
          FGameState := gsChangeBlocksBack
        else
        begin
          FPoints := 10;
          CreatePointBlocks;
          FGameState := gsGivePoints;
        end
      end;

      gsChangeBlocksBack:
      begin
        bDraw := True;
        if MoveSelectedBlocks then
        begin
          ChangeSelectedBlocks;
          SetSelectionsDisabled;
          if Assigned(FOnStartWaiting) then
            FOnStartWaiting(Self);
          FGameState := gsWaitingForFirstSelection;
          BlockPanelResize(Sender);
        end;
      end;

      gsGivePoints:
      begin
        Sleep(300);
        DestroyPointBlocks;
        FGameState := gsFillEmptyBlocks;
      end;

      gsFillEmptyBlocks:
      begin
        bDraw := True;
        FillEmptyBlocks;
        FGameState := gsScrollNewBlocks;
      end;

      gsScrollNewBlocks:
      begin
        bDraw := True;
        if ScrollBlocks then
          FGameState := gsRemoveBlocks3;
      end;

      gsGoNextLevel:
      begin
        if not GoNextLevel then
          FGameState := gsCheckPossibleMoves
        else
        begin
          Sleep(300);
          FGameState := gsInitialize;
        end;
      end;

      gsRemoveBlocks3:
      begin
        bDraw := True;
        if not RemoveBlocks3 then
          FGameState := gsGoNextLevel
        else
        begin
          FPoints := FPoints + 10;
          CreatePointBlocks;
          FGameState := gsGivePoints;
        end
      end;
    end;
  end
  else
  begin
    bDraw := True;
    RunDemo;
  end;

  if bDraw then
    ReDraw;
end;

procedure TBlockPanel.Display;
begin
  FPaintBox.Canvas.Draw(0, 0, FBitmap);
end;

procedure TBlockPanel.DrawBlocksLeft(Bitmap: TBitmap);
var
  i, x, y: Integer;
begin
  Bitmap.Canvas.Font.Style := [fsBold];
  Bitmap.Canvas.Font.Size := 12;
  Bitmap.Canvas.Font.Color := clWhite;
  for i := 0 to 7 do
  begin
    x := Trunc(i*BlockWidth + (BlockWidth/2) - (Bitmap.Canvas.TextWidth(IntToStr(FBlockCounts[i]))/2));
    y := Trunc(8*BlockHeight + (BlockHeight/2) - (Bitmap.Canvas.TextHeight(IntToStr(FBlockCounts[i]))/2));
    Bitmap.Canvas.TextOut(x, y, IntToStr(FBlockCounts[i]));
  end;
end;

procedure TBlockPanel.ReDraw;
var
  i, j: Integer;
  Block: TBlock;
  TextBlock: TTextBlock;
  PointsBlock: TPointsBlock;
begin
  if not FDemoRunning then
  begin
    { draw background }
    DrawBackGround(FBitmap);

    { draw game blocks }
    for i := 0 to 7 do
      for j := 0 to 7 do
      begin
        Block := FBlocks[i, j];
        if Block <> nil then
          Block.PaintTo(FBitmap.canvas);
      end;
    { draw points }
    for i := 0 to FPointBlocks.Count - 1 do
    begin
      PointsBlock := FPointBlocks[i];
      PointsBlock.PaintTo(FBitmap.Canvas);
    end;
    { draw blocks left }
    DrawBlocksLeft(FBitmap);
    end
  else
  begin
    { draw demo blocks }
    DrawBackGround(FBitmap);
    for i := 0 to FDemoBlocks.Count-1 do
    begin
      Block := FDemoBlocks[i];
      Block.PaintTo(FBitmap.canvas);
    end;
    for i := 0 to FDemoTextBlocks.Count-1 do
    begin
      TextBlock := FDemoTextBlocks[i];
      TextBlock.PaintTo(FBitmap.canvas);
    end;
  end;
  Display;
end;

procedure TBlockPanel.DrawBackGround(Bitmap:TBitmap);
begin
  Bitmap.Canvas.CopyRect(Rect(0,0,Bitmap.Width, Bitmap.Height),
    FBkgBitmap.Canvas, Rect(0,0,FBkgBitmap.Width, FBkgBitmap.Height));
end;

function TBlockPanel.GetRunning: boolean;
begin
  Result := FTimer.Enabled;
end;

procedure TBlockPanel.NewGame;
begin
  FGameOver := False;
  FLevel := 0;
  FScore := 0;
  if Assigned(FOnScoreChange) then
    FOnScoreChange(Self);
  FGameState := gsInitialize;
end;

procedure TBlockPanel.SetRunning(const Value: boolean);
begin
  FTimer.Enabled := Value;
end;


end.
