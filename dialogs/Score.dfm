object ScoreDialog: TScoreDialog
  Left = 525
  Top = 126
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Score'
  ClientHeight = 446
  ClientWidth = 398
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ClientPanel: TPanel
    Left = 0
    Top = 0
    Width = 398
    Height = 409
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    TabOrder = 0
    object StringGrid: TBCStringGrid
      Left = 6
      Top = 6
      Width = 386
      Height = 403
      Align = alClient
      DefaultRowHeight = 18
      FixedCols = 0
      RowCount = 21
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
      ScrollBars = ssNone
      TabOrder = 0
      Alignment = taLeftJustify
      FixedFont.Charset = DEFAULT_CHARSET
      FixedFont.Color = clWindowText
      FixedFont.Height = -11
      FixedFont.Name = 'Tahoma'
      FixedFont.Style = []
      ColWidths = (
        31
        116
        84
        50
        97)
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 409
    Width = 398
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    Padding.Bottom = 6
    TabOrder = 1
    object OKButton: TButton
      Left = 6
      Top = 6
      Width = 88
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Action = OKAction
      Align = alLeft
      Default = True
      TabOrder = 0
    end
    object ResetRecordsButton: TButton
      Left = 304
      Top = 6
      Width = 88
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Action = ResetRecordsAction
      Align = alRight
      TabOrder = 1
    end
  end
  object ActionList: TActionList
    Left = 168
    Top = 254
    object OKAction: TAction
      Caption = '&OK'
      OnExecute = OKActionExecute
    end
    object ResetRecordsAction: TAction
      Caption = '&Reset Records'
      OnExecute = ResetRecordsActionExecute
    end
  end
end
