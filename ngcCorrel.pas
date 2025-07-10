UNIT ngcCorrel;

{=============================================================================================================
  NGC Pixel correlation
  ------------------------------------------------------------------------------------------------------------
  2023
  www.GabrielMoraru.com
  ------------------------------------------------------------------------------------------------------------
  An NGC algorithm is used to determine the position of a pattern in an image.
  The function generates output values that represent the correspondence between the structures of the pattern and those of the image.
  The position of the pattern is given relative to the center of Pattern.
  Because of this reason, in the resulting image half the pattern width and half the pattern height around the edges,
   do not contain any correlation results! This is normal.
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

 // Just in case
 Assert(Result >= -1);
 Assert(Result <=  1);
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
   iWidth, iHeight: Integer;            // Image width/height minus borders
   ChopMX: TIntegerMatrix;
   PatternMX: TIntegerMatrix;
   MainBmpMX: TByteMatrix;
   Line: PByte;
   c: Cardinal;

   SrcRect, ChopRect: TRect;
   ChopBMP: TBitmap;

   { Copy a piece from the main image. }
   procedure CreateChop(col, row: integer);
   begin
     Assert(Col >= 0);
     Assert(Row >= 0);

     Assert(Col < MainBMP.Width);
     Assert(Row < MainBMP.Height);

     SrcRect.Left:= cl;
     SrcRect.Top := rw;
     SrcRect.Width := PatternBMP.Width;
     SrcRect.Height:= PatternBMP.Height;
     ChopBMP.Canvas.CopyRect(ChopRect, MainBMP.Canvas, SrcRect);
     //ChopBMP.SaveToFile('ChopBMP.bmp');
   end;

begin
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

 { We ignore the last half of the row/column }
 iWidth := MainBMP.Width  -M;  //-1 ?
 iHeight:= MainBMP.Height -N;

 { Prepare the small image }
 ChopBMP:= TBitmap.Create;
 TRY
   ChopBMP.PixelFormat:= MainBMP.PixelFormat;
   ChopBMP.Palette    := MainBMP.Palette;
   ChopBMP.SetSize(PatternBMP.Width, PatternBMP.Height);
   SetLength(ChopMX, ChopBMP.Width, ChopBMP.Height);

   { We move the main bitmap to the array bitmap }
   SetLength(MainBmpMX, MainBMP.Width, MainBMP.Height);
   for rw:= 0 to MainBMP.Height-1 DO              // Vertical scan line by line
    begin
     Line:= MainBMP.ScanLine[rw];
     for cl:= 0 to MainBMP.Width-1 DO
       MainBmpMX[cl, rw]:= Line[cl];
    end;

   // Main loop - Move the window from left to right / top to bottom
   for rw:= N to iHeight-1{PaternBMP.Height} DO
    begin

     for cl:= M to iWidth-1{PaternBMP.Width} DO
      begin
        { Copy a small piece from the main image. }
        CreateChop(cl, rw);

        //ToDo: Speed optimization: When we move the window, most of the information (all except the next column of pixels) is already there, so we can reuse it in the next shift, and compute only the next column
        NormalizeColor(ChopBMP, ChopMX);

        { Compare chop with pattern }
        Pix:= RangeToByte(PixCorrelation(ChopMX, PatternMX));   //todo: use 8bit bitmap directly
        OutputBMP.Canvas.Pixels[cl, rw]:= RGB(Pix, Pix, Pix);   //todo: use scanline here. Canvas.Pixels adds quite a few seconds
      end;

      // Update from time to time
      if Preview <> NIL then
        begin
          Preview.Picture.Assign(OutputBMP);
          if GetTickCount-c > 400 {ms} then
           begin
             Preview.Update;
             c:= GetTickCount;
           end;
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
