inherited ScoreDialog: TScoreDialog
  Left = 525
  Top = 126
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Score'
  ClientHeight = 446
  ClientWidth = 398
  Position = poMainFormCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PanelClient: TPanel
    Left = 0
    Top = 0
    Width = 398
    Height = 409
    Align = alClient
    BevelOuter = bvNone
    Color = clWindow
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    ParentBackground = False
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
      ColWidths = (
        31
        116
        84
        50
        97)
    end
  end
  object PanelBottom: TPanel
    Left = 0
    Top = 409
    Width = 398
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    Color = clWindow
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    Padding.Bottom = 6
    ParentBackground = False
    TabOrder = 1
    object ButtonOK: TButton
      Left = 6
      Top = 6
      Width = 88
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Action = ActionOK
      Align = alLeft
      Default = True
      TabOrder = 0
    end
    object ButtonResetRecords: TButton
      Left = 304
      Top = 6
      Width = 88
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Action = ActionResetRecords
      Align = alRight
      TabOrder = 1
    end
  end
  object ActionList: TActionList
    Left = 168
    Top = 254
    object ActionOK: TAction
      Caption = '&OK'
      OnExecute = ActionOKExecute
    end
    object ActionResetRecords: TAction
      Caption = '&Reset Records'
      OnExecute = ActionResetRecordsExecute
    end
  end
end
