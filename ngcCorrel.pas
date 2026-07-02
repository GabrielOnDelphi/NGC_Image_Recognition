UNIT ngcCorrel;

{=============================================================================================================
  NGC Pixel correlation
  ------------------------------------------------------------------------------------------------------------
  www.GabrielMoraru.com
  2026.07.01
  Github.com/GabrielOnDelphi/Delphi-LightSaber/blob/main/System/Copyright.txt
  ------------------------------------------------------------------------------------------------------------
  An NGC algorithm is used to determine the position of a pattern in an image.
  The function generates output values that represent the correspondence between the structures of the pattern and those of the image.
  The reported position is the pattern's top-left corner (NOT its center) in the Main image.
  Because of this, the resulting image has no correlation results in a border margin: about half the pattern size on the left and top edges, and nearly a full pattern size on the right and bottom edges. This is normal.
  ------------------------------------------------------------------------------------------------------------
  Possible optimizations:
     https://en.wikipedia.org/wiki/DBSCAN
     https://stackoverflow.com/questions/36034455/counting-number-of-pixels-in-a-cluster-kmeans-color-detection
=============================================================================================================}

INTERFACE

USES
  WinApi.Windows, System.SysUtils, Vcl.ExtCtrls, Vcl.Graphics, ngcImageUtils;

TYPE
   TCorrel= class(TObject)
    private
      function getBorderW: Integer;
      function getBorderH: Integer;
      function pixCorrelation(Chop, Ptrn: TIntegerMatrix): Double;
    protected
    public
      MainBMP, PatternBMP: TBitmap;
      OutputBMP: TBitmap;
      procedure CalculateNGC(Preview: TImage= NIL);
    public
     constructor Create; virtual;
     destructor Destroy; override;

     property BorderW: Integer read getBorderW;
     property BorderH: Integer read getBorderH;

     procedure LoadMain   (AGraphFile: string);
     procedure LoadPattern(AGraphFile: string);
   end;


IMPLEMENTATION

USES ngcAppUtils, LightVcl.Graph.Loader;


constructor TCorrel.Create;
begin
  inherited Create;
  MainBMP   := TBitmap.Create;
  PatternBMP:= TBitmap.Create;
  OutputBMP := TBitmap.Create;
end;


destructor TCorrel.Destroy;
begin
  FreeAndNil(OutputBMP);
  FreeAndNil(PatternBMP);
  FreeAndNil(MainBMP);
  inherited;
end;




procedure TCorrel.LoadMain(AGraphFile: string);
begin
  LightVcl.Graph.Loader.LoadGraphAsGrayScale(AGraphFile, MainBMP); // Converts image to gray-scale. DOES NOT WORK YET!
end;


procedure TCorrel.LoadPattern(AGraphFile: string);
begin
  LoadGraphAsGrayScale(AGraphFile, PatternBMP); // Converts image to gray-scale
end;



function TCorrel.getBorderW: Integer;
begin
  Result:= PatternBMP.Width;
end;

function TCorrel.getBorderH: Integer;
begin
  Result:= PatternBMP.Height;
end;


{--------------------------------------------------------------------------------------------------
   Pixel correlation
   Implementation of the main algorithm.

   xm, ym= Pix coordinates in Main img
   The result is always in the -1 +1 range, with 1 for black and -1 for white .
--------------------------------------------------------------------------------------------------}
function TCorrel.pixCorrelation(Chop, Ptrn: TIntegerMatrix): Double;
VAR
   u, v: Integer;
   PrecalcPixM, PrecalcPixP: Integer;
   ResultN: Double;                             // numerator
   ResultD1, ResultD2: Double;                  // denominator
begin
 ResultN := 0;
 ResultD1:= 0;
 ResultD2:= 0;

 // Numerator
 for v:= 0 to PatternBMP.Height-1 DO
   for u:= 0 to PatternBMP.Width-1 DO
    begin
     PrecalcPixP:= Ptrn[u, v];              // Pixel in pattern
     PrecalcPixM:= Chop[u, v];              // Pixel in main img
     ResultN:= ResultN+ PrecalcPixP*PrecalcPixM;
    end;

 // Denominator
 for v:= 0 to PatternBMP.Height-1 DO
   for u:= 0 to PatternBMP.Width-1 DO
    begin
     PrecalcPixP:= Ptrn[u, v];
     ResultD1:= ResultD1+ PrecalcPixP*PrecalcPixP;
    end;

 for v:= 0 to PatternBMP.Height-1 DO
   for u:= 0 to PatternBMP.Width-1 DO
    begin
     PrecalcPixM:= Chop[u, v];
     ResultD2:= ResultD2+ PrecalcPixM*PrecalcPixM;
    end;

 if (ResultD1 = 0) OR (ResultD2 = 0)
 then Result:= ResultN
 else Result:= ResultN / sqrt(ResultD1 * ResultD2);

 // Just in case. Tolerance needed: on a perfect match, floating-point rounding can push the value epsilon-outside the -1..+1 range
 Assert(Result >= -1.000001);
 Assert(Result <=  1.000001);

 // Clamp the floating-point noise so RangeToByte always receives a value in -1..+1
 if Result >  1 then Result:=  1;
 if Result < -1 then Result:= -1;
end;



{--------------------------------------------------------------------------------------------------
   Main function
   Normalized gray correlation
   Preview is where we display the output, line by line, as we process it. Optional.
--------------------------------------------------------------------------------------------------}
procedure TCorrel.CalculateNGC(Preview: TImage= NIL);
VAR
   Pix: Integer;
   rw, cl: Integer;
   M,N: Integer;                        // half size
   iWidth, iHeight: Integer;            // Last valid top-left coordinate for the sliding window
   ChopMX: TIntegerMatrix;
   PatternMX: TIntegerMatrix;
   c: Cardinal;

   SrcRect, ChopRect: TRect;
   ChopBMP: TBitmap;

   { Copy a piece from the main image. }
   procedure CreateChop(Col, Row: integer);
   begin
     Assert(Col >= 0);
     Assert(Row >= 0);

     Assert(Col + PatternBMP.Width  <= MainBMP.Width );  // The chop must fit entirely into the main image
     Assert(Row + PatternBMP.Height <= MainBMP.Height);

     SrcRect.Left:= Col;
     SrcRect.Top := Row;
     SrcRect.Width := PatternBMP.Width;
     SrcRect.Height:= PatternBMP.Height;
     ChopBMP.Canvas.CopyRect(ChopRect, MainBMP.Canvas, SrcRect);
     //ChopBMP.SaveToFile('ChopBMP.bmp');
   end;

begin
 // The whole pipeline (ScanLine used as PByte, GetAverageColorPf8, palette handling) requires 8-bit grayscale input
 if MainBMP.PixelFormat <> pf8bit
 then raise EInvalidGraphic.Create('CalculateNGC: MainBMP must be an 8-bit grayscale bitmap! Did LoadMain fail?');
 if PatternBMP.PixelFormat <> pf8bit
 then raise EInvalidGraphic.Create('CalculateNGC: PatternBMP must be an 8-bit grayscale bitmap! Did LoadPattern fail?');

 c:= GetTickCount;

 // Prepare output image
 OutputBMP.Assign(MainBMP);

 //OutputBMP.SetSize(MainBMP.Width, MainBMP.Height);
 //OutputBMP.PixelFormat:= pf8bit; ?
 //LightVcl.Graph.UtilGray.SetBitmapGrayPalette(OutputBMP); // Set grayscale palette
 //FillBitmap(OutputBMP, clBlack);

 { Precalculate pattern }
 SetLength(PatternMX, PatternBMP.Width {Cols}, PatternBMP.Height {Rows});
 NormalizeColor(PatternBMP, PatternMX);

 { This is the size of the chop }
 ChopRect.Top := 0;
 ChopRect.Left:= 0;
 ChopRect.Width := PatternBMP.Width;
 ChopRect.Height:= PatternBMP.Height;

 { Main loop coordinates }
 M:= Trunc(PatternBMP.Width  / 2);     // Middle point in the pattern image
 N:= Trunc(PatternBMP.Height / 2);     // Middle point in the pattern image

 { Last valid top-left position for the chop: the window must stay fully inside the image.
   Going further right/bottom would make CopyRect read outside MainBMP, leaving stale pixels in ChopBMP. }
 iWidth := MainBMP.Width  - PatternBMP.Width;
 iHeight:= MainBMP.Height - PatternBMP.Height;

 { Prepare the small image }
 ChopBMP:= TBitmap.Create;
 TRY
   ChopBMP.PixelFormat:= MainBMP.PixelFormat;
   ChopBMP.Palette    := CopyPalette(MainBMP.Palette);   // CopyPalette because TBitmap takes ownership of the assigned HPALETTE and deletes it on destroy. Assigning MainBMP.Palette directly would make both bitmaps delete the same GDI handle!
   ChopBMP.SetSize(PatternBMP.Width, PatternBMP.Height);
   SetLength(ChopMX, ChopBMP.Width, ChopBMP.Height);

   // Main loop - Move the window from left to right / top to bottom
   for rw:= N to iHeight DO
    begin

     for cl:= M to iWidth DO
      begin
        { Copy a small piece from the main image. }
        CreateChop(cl, rw);

        //ToDo: Speed optimization: When we move the window, most of the information (all except the next column of pixels) is already there, so we can reuse it in the next shift, and compute only the next column
        NormalizeColor(ChopBMP, ChopMX);

        { Compare chop with pattern }
        Pix:= RangeToByte(PixCorrelation(ChopMX, PatternMX));   //todo: use 8bit bitmap directly
        OutputBMP.Canvas.Pixels[cl, rw]:= RGB(Pix, Pix, Pix);   //todo: use scanline here. Canvas.Pixels adds quite a few seconds
      end;

      // Update the preview from time to time
      if (Preview <> NIL) AND (GetTickCount-c > 400 {ms}) then
        begin
          Preview.Picture.Assign(OutputBMP);
          Preview.Update;
          c:= GetTickCount;
        end;
    end;

 FINALLY
   FreeAndNil(ChopBMP);
 END;
end;





{--------------------------------------------------------------------------------------------------
   Precalculate GPix, FPix

   Because the pattern image is always the same,
     instead of computing the value of the pixels each time, we can pre-calculate them.
     Precalcualted values are stored in a two-dimensional array.
   The speed optimization is high.
--------------------------------------------------------------------------------------------------}


{ UNUSED! }

{ Copy a piece from the main image.
  Returns the output in ChopMX }
procedure CreateChop(MainBmp: TByteMatrix; ChopMX: TIntegerMatrix; Cl, Rw: integer);
VAR
   Row, Col: Integer;
   r, c: Integer;
begin
 if (Length(MainBmp)    < 1)
 OR (Length(MainBmp[0]) < 1)
 then RAISE Exception.Create('MainBmp is empty!');

 if (Cl < 0)
 OR (Rw < 0)
 then raise Exception.Create('Invalid cl/rw for creating Chop!');

 r:= 0;
 for Row := Rw to Rw+ High(ChopMX) do
  begin
   if Rw + High(ChopMX) >= Length(MainBmp[0])
   then RAISE Exception.Create('Invalid Row indices for creating Chop!');

   c:= 0;
   for Col := Cl to Cl+ High(ChopMX[Rw]) do
     begin
      if (Cl + High(ChopMX[0]) >= Length(MainBmp))
      then RAISE Exception.Create('Invalid Col indices for creating Chop!');

      ChopMX[c, r] := MainBmp[Col, Row];
      Inc(c);
     end;
   Inc(r);
  end;
end;



end.
