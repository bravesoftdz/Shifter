unit Shifter.Dialogs.Score;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, BCCommon.Dialogs.Base,
  ExtCtrls, StdCtrls, Vcl.Grids, BCControls.StringGrid, Vcl.ActnList, System.Actions;

const
  SCORECOLUMNS = 5;
  SCOREROWS = 20;
  MSGASKAREYOUSURE = 'Reset records, are you sure?';
  SECTION_SCORETABLE = 'ScoreTable';

type
  TScoreDialog = class(TBCBaseDialog)
    ActionList: TActionList;
    ActionOK: TAction;
    ActionResetRecords: TAction;
    ButtonOK: TButton;
    ButtonResetRecords: TButton;
    PanelBottom: TPanel;
    PanelClient: TPanel;
    StringGrid: TBCStringGrid;
    procedure ActionOKExecute(Sender: TObject);
    procedure ActionResetRecordsExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    function InTopTwenty(Score: Integer): Boolean;
    procedure ClearScores;
    procedure ReadIniFile;
    procedure WriteIniFile;
  public
    { Public declarations }
    procedure InsertNewScore(Name: string; Level, Score: Integer);
    procedure Open(Score: Integer = -1; Level: Integer = -1);
  end;

function ScoreDialog: TScoreDialog;

implementation

{$R *.dfm}

uses
  BCCommon.FileUtils, BCCommon.StringUtils, BCCommon.Messages, Shifter.Dialogs.YourName, BigIni;

var
  FScoreDialog: TScoreDialog;

function ScoreDialog: TScoreDialog;
begin
  if FScoreDialog = nil then
    Application.CreateForm(TScoreDialog, FScoreDialog);
  Result := FScoreDialog;
end;

procedure TScoreDialog.FormDestroy(Sender: TObject);
begin
  FScoreDialog := nil;
end;

function TScoreDialog.InTopTwenty(Score: Integer): Boolean;
begin
  Result := False;
  if (StringGrid.Cells[4, SCOREROWS] = '') or
    ((StringGrid.Cells[4, SCOREROWS] <> '') and (StrToInt(StringGrid.Cells[4, SCOREROWS]) <= Score)) then
    Result := True;
end;

procedure TScoreDialog.ActionOKExecute(Sender: TObject);
begin
  WriteIniFile;
  ModalResult := mrOk;
end;

procedure TScoreDialog.WriteIniFile;
var
  i: Integer;
begin
  with TBigIniFile.Create(GetINIFilename) do
  try
    EraseSection(SECTION_SCORETABLE);
    for i := 1 to SCOREROWS do
    begin
      if StringGrid.Cells[4, i] <> '' then
        WriteString(SECTION_SCORETABLE, IntToStr(i),
          EncryptString(Format('%s;%s;%s;%s', [StringGrid.Cells[1, i],
          StringGrid.Cells[2, i], StringGrid.Cells[3, i], StringGrid.Cells[4, i]])));
    end;
  finally
    Free;
  end;
end;

procedure TScoreDialog.ReadIniFile;
var
  i: Integer;
  s: string;
  ScoreTable: TStrings;

begin
  ScoreTable := TStringList.Create;
  with TBigIniFile.Create(GetINIFilename) do
  try
    ReadSectionValues(SECTION_SCORETABLE, ScoreTable);
    for i := 0 to ScoreTable.Count - 1 do
    begin
      s := DecryptString(RemoveTokenFromStart('=', ScoreTable.Strings[i]));
      StringGrid.Cells[0, i + 1] := IntToStr(i + 1); { position }
      StringGrid.Cells[1, i + 1] := GetNextToken(';', s);
      s := RemoveTokenFromStart(';', s);
      StringGrid.Cells[2, i + 1] := GetNextToken(';', s);
      s := RemoveTokenFromStart(';', s);
      StringGrid.Cells[3, i + 1] := GetNextToken(';', s);
      s := RemoveTokenFromStart(';', s);
      StringGrid.Cells[4, i + 1] := s;
    end;
  finally
    ScoreTable.Free;
    Free;
  end;
end;

procedure TScoreDialog.Open(Score: Integer; Level: Integer);
begin
  ClearScores;
  ReadIniFile;

  if Score <> -1 then
    if InTopTwenty(Score) then
    with YourNameDialog do
    try
      ShowModal;
      InsertNewScore(Name, Level, Score);
    finally
      Release;
    end;

  ShowModal;
end;

procedure TScoreDialog.InsertNewScore(Name: string; Level, Score: Integer);
var
  i: integer;
begin
  { get index }
  i := 1;
  while i <= SCOREROWS do
  begin
    if (StringGrid.Cells[4, i] = '') or
      ((StringGrid.Cells[4, i] <> '') and (StrToInt(StringGrid.Cells[4, i]) <= Score)) then
      Break;
    Inc(i);
  end;
  { insert row }
  StringGrid.InsertRow(i);
  StringGrid.Cells[1, i] := Name;
  StringGrid.Cells[2, i] := DateToStr(Now);
  StringGrid.Cells[3, i] := IntToStr(Level);
  StringGrid.Cells[4, i] := IntToStr(Score);
  StringGrid.Row := i;
  { remove rows over 20 }
  while StringGrid.RowCount > SCOREROWS + 1 do { +1: header }
    StringGrid.RemoveRow(StringGrid.RowCount - 1); { -1: grid index 0 based }
  { update positions }
  for i := 1 to SCOREROWS do
    StringGrid.Cells[0, i] := IntToStr(i);
end;

procedure TScoreDialog.ClearScores;
var
  i: Integer;
begin
  StringGrid.Clear;
  StringGrid.Cells[0, 0] := 'Pos.';
  StringGrid.Cells[1, 0] := 'Name';
  StringGrid.Cells[2, 0] := 'Date';
  StringGrid.Cells[3, 0] := 'Level';
  StringGrid.Cells[4, 0] := 'Score';
  { set last col width }
  StringGrid.ColWidths[4] := StringGrid.Width;
  for i := 0 to 3 do
    StringGrid.ColWidths[4] := StringGrid.ColWidths[4] - StringGrid.ColWidths[i];
end;

procedure TScoreDialog.ActionResetRecordsExecute(Sender: TObject);
begin
  if AskYesOrNo(MSGASKAREYOUSURE) then
    ClearScores;
end;

end.
