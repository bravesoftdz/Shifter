unit Shifter.Dialogs.YourName;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, Vcl.ExtCtrls,
  BCCommon.Dialogs.Base, BCControls.Edit, sEdit;

type
  TYourNameDialog = class(TBCBaseDialog)
    ButtonOK: TButton;
    EditName: TBCEdit;
    LabelName: TLabel;
    PanelBottom: TPanel;
    PanelClient: TPanel;
    procedure ButtonOKClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EditNameKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    function GetName: string;
  public
    { Public declarations }
    property Name: string read GetName;
  end;

function YourNameDialog: TYourNameDialog;

implementation

{$R *.dfm}

uses
  BCCommon.Messages;

var
  FYourNameDialog: TYourNameDialog;

function YourNameDialog: TYourNameDialog;
begin
  if FYourNameDialog = nil then
    Application.CreateForm(TYourNameDialog, FYourNameDialog);
  Result := FYourNameDialog;
end;

procedure TYourNameDialog.FormDestroy(Sender: TObject);
begin
  FYourNameDialog := nil;
end;

function TYourNameDialog.GetName: string;
begin
  Result := EditName.Text;
end;

procedure TYourNameDialog.EditNameKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, [#8, 'a'..'z', 'A'..'Z']) then
    Key := #0;
end;

procedure TYourNameDialog.ButtonOKClick(Sender: TObject);
begin
  if Trim(EditName.Text) = '' then
  begin
    EditName.SetFocus;
    BCCommon.Messages.ShowErrorMessage('Enter name.');
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
