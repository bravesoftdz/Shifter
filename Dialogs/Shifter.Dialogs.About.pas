unit Shifter.Dialogs.About;

interface

uses
  System.SysUtils, Winapi.Windows, System.Classes, Vcl.Graphics, BCCommon.Dialog.Base, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TAboutDialog = class(TBCBaseDialog)
    ButtonOK: TButton;
    Image: TImage;
    LabelCopyright: TLabel;
    LabelMemoryAvailable: TLabel;
    LabelOperatingSystem: TLabel;
    LabelProgramName: TLabel;
    LabelThanksTo: TLabel;
    LabelVersion: TLabel;
    LinkLabelEmbarcadero: TLinkLabel;
    PanelMiddle: TPanel;
    PanelTop: TPanel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
    procedure FormShow(Sender: TObject);
  private
    procedure Initialize;
  public
    class procedure ClassShowModal(AOwner: TComponent);
  end;

implementation

{$R *.dfm}

uses
  BCCommon.FileUtils, BCCommon.Utils;

class procedure TAboutDialog.ClassShowModal(AOwner: TComponent);
begin
  with TAboutDialog.Create(AOwner) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TAboutDialog.Initialize;
var
  MemoryStatus: TMemoryStatusEx;
begin
  LabelVersion.Caption := Format(LabelVersion.Caption, [BCCommon.FileUtils.GetFileVersion(Application.ExeName),
{$IFDEF WIN64}64{$ELSE}32{$ENDIF}]);
  { initialize the structure }
  FillChar(MemoryStatus, SizeOf(MemoryStatus), 0);
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  { check return code for errors }
{$WARNINGS OFF}
  Win32Check(GlobalMemoryStatusEx(MemoryStatus));
{$WARNINGS ON}
  LabelOperatingSystem.Caption := GetOSInfo;
  LabelMemoryAvailable.Caption := Format(LabelMemoryAvailable.Caption, [FormatFloat('#,###" KB"',
    MemoryStatus.ullAvailPhys div 1024)]);
end;

procedure TAboutDialog.LinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  BrowseURL(Link);
end;

procedure TAboutDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TAboutDialog.FormShow(Sender: TObject);
begin
  Initialize;
end;

end.
