object frmTester: TfrmTester
  Left = 450
  Top = 311
  Anchors = []
  Caption = 'Image recognition demo'
  ClientHeight = 688
  ClientWidth = 1043
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 690
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesigned
  ScreenSnap = True
  ShowHint = True
  SnapBuffer = 4
  OnDestroy = FormDestroy
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 1043
    Height = 688
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Main'
      object Splitter: TSplitter
        Left = 1032
        Top = 0
        Height = 660
        Align = alRight
        ResizeStyle = rsUpdate
      end
      object pnlMain: TPanel
        Left = 0
        Top = 0
        Width = 596
        Height = 660
        Align = alClient
        TabOrder = 0
        object imgOutput: TImage
          Left = 1
          Top = 1
          Width = 594
          Height = 516
          Align = alClient
          Proportional = True
          Stretch = True
        end
        object pnlMainSettings: TPanel
          Left = 1
          Top = 534
          Width = 594
          Height = 125
          Align = alBottom
          TabOrder = 0
          DesignSize = (
            594
            125)
          object edtMain: TEdit
            AlignWithMargins = True
            Left = 4
            Top = 4
            Width = 586
            Height = 21
            Align = alTop
            TabOrder = 0
            TextHint = 'c:\MainImage.bmp'
          end
          object edtPattern: TEdit
            AlignWithMargins = True
            Left = 4
            Top = 31
            Width = 586
            Height = 21
            Align = alTop
            TabOrder = 1
            TextHint = 'c:\Pattern.bmp'
            OnChange = edtPatternChange
          end
          object btnStep1: TButton
            Left = 7
            Top = 80
            Width = 163
            Height = 38
            Anchors = [akLeft, akBottom]
            Caption = '1. Calculate'
            TabOrder = 2
            OnClick = btnStep1Click
          end
          object btnLoadInput: TButton
            Left = 266
            Top = 87
            Width = 85
            Height = 25
            Anchors = [akLeft, akBottom]
            Caption = 'Show input'
            TabOrder = 3
            OnClick = btnLoadInputClick
          end
          object btnLoadOutput: TButton
            Left = 355
            Top = 87
            Width = 85
            Height = 25
            Anchors = [akLeft, akBottom]
            Caption = 'Show output'
            TabOrder = 4
            OnClick = btnLoadOutputClick
          end
          object Panel2: TPanel
            Left = 528
            Top = 55
            Width = 65
            Height = 69
            Align = alRight
            TabOrder = 5
            object imgPattern: TImage
              Left = 1
              Top = 14
              Width = 63
              Height = 54
              Align = alClient
              Center = True
              Proportional = True
            end
            object Pattern: TLabel
              Left = 1
              Top = 1
              Width = 63
              Height = 13
              Align = alTop
              Caption = 'Pattern img:'
            end
          end
        end
        object chkStretch: TCheckBox
          Left = 1
          Top = 517
          Width = 594
          Height = 17
          Align = alBottom
          Caption = 'Stretch'
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = chkStretchClick
        end
      end
      object pnlStep3: TPanel
        Left = 596
        Top = 0
        Width = 436
        Height = 660
        Align = alRight
        TabOrder = 1
        object imgOutput2: TImage
          Left = 1
          Top = 1
          Width = 434
          Height = 349
          Align = alClient
          Proportional = True
          Stretch = True
        end
        object Splitter1: TSplitter
          Left = 1
          Top = 350
          Width = 434
          Height = 3
          Cursor = crVSplit
          Align = alBottom
        end
        object btnRegions: TButton
          AlignWithMargins = True
          Left = 4
          Top = 620
          Width = 428
          Height = 36
          Hint = 
            'Show detected regions.'#13#10#13#10'This is the final result. The program ' +
            'should show you where the pattern image was discovered into the ' +
            'larger image.'
          Align = alBottom
          Caption = '2. Show results regions'
          Enabled = False
          TabOrder = 0
          OnClick = btnRegionsClick
        end
        object Panel1: TPanel
          Left = 1
          Top = 353
          Width = 434
          Height = 42
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 1
          object lblBrightness: TLabel
            Left = 12
            Top = 16
            Width = 93
            Height = 13
            Caption = 'Minimum brightness'
          end
          object spnBrightness: TSpinEdit
            Left = 111
            Top = 13
            Width = 42
            Height = 22
            Hint = 'Eliminate all regions with brightness under this threshold'
            MaxValue = 255
            MinValue = 100
            TabOrder = 0
            Value = 213
            OnChange = spnBrightnessChange
          end
        end
        object pnlCoordinates: TPanel
          Left = 1
          Top = 395
          Width = 434
          Height = 222
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 2
          object Label1: TLabel
            Left = 5
            Top = 199
            Width = 173
            Height = 13
            Caption = 'Show only the first                 results'
          end
          object lbxResults: TListBox
            Left = 0
            Top = 0
            Width = 434
            Height = 186
            Align = alTop
            ItemHeight = 13
            TabOrder = 0
          end
          object spnFilterRes: TSpinEdit
            Left = 101
            Top = 196
            Width = 35
            Height = 22
            MaxValue = 10000
            MinValue = 1
            TabOrder = 1
            Value = 10
          end
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Test grayscale'
      ImageIndex = 1
      object imgTestGray: TImage
        AlignWithMargins = True
        Left = 3
        Top = 112
        Width = 1029
        Height = 545
        Align = alBottom
        Anchors = [akLeft, akTop, akRight, akBottom]
        Center = True
        Proportional = True
      end
      object btnSaveGray: TButton
        Left = 247
        Top = 63
        Width = 105
        Height = 25
        Caption = 'Save as grayscale'
        TabOrder = 0
        OnClick = btnSaveGrayClick
      end
      object btnIsGray: TButton
        Left = 29
        Top = 63
        Width = 95
        Height = 25
        Caption = 'Is grayscale'
        TabOrder = 1
        OnClick = btnIsGrayClick
      end
      object edtTestGray: TEdit
        AlignWithMargins = True
        Left = 27
        Top = 36
        Width = 630
        Height = 21
        TabOrder = 2
        TextHint = 'c:\MainImage.bmp'
      end
      object btnLoadGray: TButton
        Left = 133
        Top = 63
        Width = 105
        Height = 25
        Caption = 'Load as grayscale'
        TabOrder = 3
        OnClick = btnLoadGrayClick
      end
    end
  end
end
