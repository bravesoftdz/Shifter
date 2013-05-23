unit YourName;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Vcl.ExtCtrls, Dlg;

type
  TYourNameDialog = class(TDialog)
    Panel1: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    Panel2: TPanel;
    OKButton: TButton;
    procedure OKButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    function GetName: string;
  public
    { Public declarations }
    property Name: String read GetName;
  end;

function YourNameDialog: TYourNameDialog;

implementation

{$R *.dfm}

uses
  StyleHooks, Common;

var
  FYourNameDialog: TYourNameDialog;

function YourNameDialog: TYourNameDialog;
begin
  if FYourNameDialog = nil then
    Application.CreateForm(TYourNameDialog, FYourNameDialog);
  Result := FYourNameDialog;
  StyleHooks.SetStyledFormSize(Result);
end;

procedure TYourNameDialog.FormDestroy(Sender: TObject);
begin
  FYourNameDialog := nil;
end;

function TYourNameDialog.GetName: string;
begin
  Result := NameEdit.Text;
end;

procedure TYourNameDialog.NameEditKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #8) { space }
    or ((Key >= 'a') and (Key <= 'z'))
    or ((Key >= 'A') and (Key <= 'Z')) then
  else
    Key := #0;
end;

procedure TYourNameDialog.OKButtonClick(Sender: TObject);
begin
  if Trim(NameEdit.Text) = '' then
  begin
    NameEdit.SetFocus;
    Common.ShowErrorMessage('Enter name.');
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
