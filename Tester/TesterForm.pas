UNIT TesterForm;

{=============================================================================================================
  NGC Demo Program
  ------------------------------------------------------------------------------------------------------------
  2024.12
  www.GabrielMoraru.com
  ------------------------------------------------------------------------------------------------------------
  Speed is exponentially proportional to the size of the input.
  Therefore, it is recommended to scale down the main image in order to improve speed.
=============================================================================================================}

INTERFACE

USES
  WinApi.Windows, WinApi.Messages, System.SysUtils, System.Classes,
  Vcl.StdCtrls, Vcl.Forms, LightVcl.Visual.AppDataForm,Vcl.Controls, Vcl.Samples.Spin, Vcl.ExtCtrls, Vcl.Graphics, Vcl.Dialogs, Vcl.ComCtrls,
  ngcAppUtils, LightCore.AppData, LightVcl.Visual.AppData
, ngcCorrel2, LightVcl.Visual.INIFile;

TYPE
 TfrmTester = class(TLightForm)
    btnStep1        : TButton;
    btnLoadInput    : TButton;
    btnLoadOutput   : TButton;
    btnRegions      : TButton;
    chkStretch      : TCheckBox;
    edtMain         : TEdit;
    edtPattern      : TEdit;
    imgOutput       : TImage;
    imgOutput2      : TImage;
    Label1          : TLabel;
    lblBrightness   : TLabel;
    lbxResults      : TListBox;
    Panel1          : TPanel;
    pnlCoordinates  : TPanel;
    pnlMain         : TPanel;
    pnlMainSettings : TPanel;
    pnlStep3        : TPanel;
    Splitter        : TSplitter;
    Splitter1       : TSplitter;
    spnBrightness   : TSpinEdit;
    spnFilterRes    : TSpinEdit;
    PageControl1    : TPageControl;
    TabSheet1       : TTabSheet;
    TabSheet2       : TTabSheet;
    btnSaveGray     : TButton;
    btnIsGray       : TButton;
    edtTestGray     : TEdit;
    btnLoadGray     : TButton;
    imgTestGray     : TImage;
    Panel2: TPanel;
    imgPattern: TImage;
    Pattern: TLabel;
    procedure btnStep1Click       (Sender: TObject);
    procedure btnRegionsClick     (Sender: TObject);
    procedure FormDestroy         (Sender: TObject);
    procedure spnBrightnessChange (Sender: TObject);
    procedure btnLoadInputClick   (Sender: TObject);
    procedure btnLoadOutputClick  (Sender: TObject);
    procedure chkStretchClick     (Sender: TObject);
    procedure edtPatternChange    (Sender: TObject);
    procedure btnIsGrayClick      (Sender: TObject);
    procedure btnLoadGrayClick    (Sender: TObject);
    procedure btnSaveGrayClick    (Sender: TObject);
  private
    Correl: TCorrel2;
    procedure LoadPattern;
  public
    procedure FormPostInitialize; override;
 end;

VAR
   frmTester: TfrmTester;


IMPLEMENTATION  {$R *.dfm}

USES
   ngcCorrel, ngcImageUtils, LightCore.IO, LightCore.INIFile, LightCore.TextFile, LightVcl.Common.IO, LightVcl.Graph.UtilGray, LightVcl.Graph.Loader;



{--------------------------------------------------------------------------------------------------
   APP START
--------------------------------------------------------------------------------------------------}
procedure TfrmTester.FormPostInitialize;
VAR sFile: string;
begin
  inherited FormPostInitialize;

  sFile:= GetAppDir+ 'MainImage.bmp';
  if FileExists(sFile)
  then edtMain.Text:= sFile;

  sFile:= GetAppDir+ 'Pattern.bmp';
  if FileExists(sFile)
  then edtPattern.Text:= sFile;

  //LoadForm;
  LoadPattern;
end;


procedure TfrmTester.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Correl);
  //SaveForm;
end;






{--------------------------------------------------------------------------------------------------
   START PROCESSING
--------------------------------------------------------------------------------------------------}

procedure TfrmTester.btnStep1Click(Sender: TObject);
begin
  SetPriorityMax;

  // Checks
  if NOT FileExistsMsg(edtMain.Text) then EXIT;
  if NOT FileExistsMsg(edtPattern.Text) then EXIT;

  // GUI
  Caption:= 'Processing...';
  Update;

  if Correl = NIL
  then Correl:= TCorrel2.Create
  else Correl.Clear;

  // Load images
  Correl.LoadMain   (edtMain.Text);
  Correl.Loadpattern(edtPattern.Text);

  // MEASURE TIME
  // Time for 805x773px inp img = 23.5 sec (debug mode with optimizations).
  // Accuracy 100%
  TimerStart;

  // Compute!
  Correl.CalculateNGC(imgOutput);

  {$IFDEF Debug}
  Caption:= 'Time (debug mode): '+ TimerElapsedS;
  {$ELSE}
  Caption:= 'Time (release mode): '+ TimerElapsedS;
  {$EndIF}

  // Save output
  imgOutput.Picture.Assign(Correl.OutputBMP);
  Correl.OutputBMP.SaveToFile(ExtractFilePath(edtMain.Text)+ 'Correlation.bmp');
  /////////put it back? Assert(Correl.OutputBMP.PixelFormat= pf8bit);

  // STEP 2
  btnRegionsClick(Sender);

  btnRegions.Enabled:= TRUE;
  Application.BringToFront;
  Beep;
end;




{--------------------------------------------------------------------------------------------------
   INPUTS
--------------------------------------------------------------------------------------------------}

procedure TfrmTester.btnLoadInputClick(Sender: TObject);
begin
  if FileExists(edtMain.Text)
  then imgOutput.Picture.LoadFromFile(edtMain.Text);
end;


procedure TfrmTester.btnLoadOutputClick(Sender: TObject);
begin
  VAR OutPut:= ExtractFilePath(edtMain.Text)+ 'Correlation.bmp';
  if FileExists(OutPut)
  then imgOutput.Picture.LoadFromFile(OutPut);
end;


procedure TfrmTester.LoadPattern;
begin
  if FileExists(edtPattern.Text)
  then imgPattern.Picture.LoadFromFile(edtPattern.Text);
end;


procedure TfrmTester.edtPatternChange(Sender: TObject);
begin
  LoadPattern;
end;


procedure TfrmTester.chkStretchClick(Sender: TObject);
begin
  imgOutput.Stretch := chkStretch.Checked;
  imgOutput2.Stretch:= chkStretch.Checked;
end;


procedure TfrmTester.btnIsGrayClick(Sender: TObject);
begin
  if HasGrayscalePalette(edtTestGray.Text)
  then Caption:= 'Is grayscale'
  else Caption:= 'Not grayscale';
end;




{ REGIONS }

procedure TfrmTester.spnBrightnessChange(Sender: TObject);
begin
  if Correl <> NIL
  then btnRegionsClick(Sender);
end;


procedure TfrmTester.btnRegionsClick(Sender: TObject);
begin
  //del Caption:= 'Objects are detected and shown on screen in dark gray color. "Main" pixels are shown in brighter color.';

  Correl.copyBrightPixels(spnBrightness.Value);
  Correl.GetRegions;
  Correl.ShowPixels;
  Correl.LoadMain(edtMain.Text);
  Correl.DrawBoxes(imgOutput, spnFilterRes.Value);           // Show results in the main image
  Correl.PopulateResults(lbxResults, spnFilterRes.Value);    // Keep in the list only the first x values

  imgOutput2.Picture.Assign(Correl.FinalBMP);
end;





procedure TfrmTester.btnLoadGrayClick(Sender: TObject);
begin
  VAR BMP:= LoadGraphAsGrayScale(edtTestGray.Text);
  TRY
    imgTestGray.Picture.Assign(BMP);

    if HasGrayscalePalette(BMP)
    then Caption:= 'Is grayscale'
    else Caption:= 'Not grayscale!';
  FINALLY
    FreeAndNil(BMP);
  END;
end;


procedure TfrmTester.btnSaveGrayClick(Sender: TObject);
begin
  VAR BMP:= LoadGraphAsGrayScale(edtTestGray.Text);
  TRY
    imgTestGray.Picture.Assign(BMP);

    if HasGrayscalePalette(BMP)
    then Caption:= 'Is grayscale'
    else Caption:= 'Not grayscale!';

    BMP.SaveToFile('out.bmp');
  FINALLY
    FreeAndNil(BMP);
  END;
end;



end.
