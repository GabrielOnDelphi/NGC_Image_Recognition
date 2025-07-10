UNIT ngcImageUtils;

{=============================================================================================================
  NGC Image Utils
  ------------------------------------------------------------------------------------------------------------
  2024.12
  www.GabrielMoraru.com
  ------------------------------------------------------------------------------------------------------------
  Helper functions for the NGC algorithm
=============================================================================================================}

INTERFACE

USES
   Winapi.Windows, System.SysUtils, Vcl.Graphics, Vcl.ExtCtrls;

TYPE
   TIntegerMatrix= array of array of Integer;
   TByteMatrix   = array of array of Byte;


procedure FillBitmap      (InputBitmap: TBitmap; Color: TColor);
function  GetAverageValue (Bmp: TIntegerMatrix): Byte;            { Get the average value for all data in this array }
procedure NormalizeColor  (BMP: TBitmap; Mx: TIntegerMatrix);     { Substract average gray value from each pixel Returns the output in Prec }
procedure NormalizeColorMx(BMP: TIntegerMatrix);                  { unused } { Substract average gray value from each pixel }

procedure IncreaseClrDepth(Img: TImage);                          { Increase color depth from 8bit to 24bit }


IMPLEMENTATION

USES
  LightVcl.Graph.Loader, LightVcl.Graph.UtilGray;



procedure FillBitmap(InputBitmap: TBitmap; Color: TColor);  { copy }
begin
 InputBitmap.Canvas.Brush.Color:= Color;
 InputBitmap.Canvas.Brush.Style:= bsSolid;
 InputBitmap.Canvas.FillRect(InputBitmap.Canvas.ClipRect);
end;


{ Get the average value for all data in this array }
function GetAverageValue(Bmp: TIntegerMatrix): Byte;
VAR
   Row, Col: Integer;
   Summ: Int64;
begin
 if (Length(bmp) < 1) OR (Length(bmp[0]) < 1)
 then RAISE Exception.Create('Array is empty!');

 Summ:= 0;
 for Row := Low(Bmp) to High(Bmp) do
   for Col := Low(Bmp[Row]) to High(Bmp[Row]) do
     Summ := Summ + bmp[Col, Row];

 VAR TotalElements := Length(Bmp) * Length(Bmp[0]);
 Result := Round(Summ / TotalElements);
end;


{ Substract average gray value from each pixel
  Returns the output in the 'Prec' array }
procedure NormalizeColor(BMP: TBitmap; Mx: TIntegerMatrix);
VAR
   BmpLine: PByte;                           // Line of pixels in Pattern and Main img.
   Col, Row: Integer;
begin
 VAR AvrgColor := LightVcl.Graph.UtilGray.GetAverageColorPf8(BMP);  // Average gray value for the pattern image

 for Row:= 0 to BMP.Height-1 DO               // Vertical scan line by line
  begin
   BmpLine:= BMP.ScanLine[Row];
   for Col:= 0 to BMP.Width-1 DO
     Mx[Col, Row]:= BmpLine[Col] - AvrgColor; // Calculate value of the pixel according to the formula
  end;
end;


{ unused }
{ Substract average gray value from each pixel }
procedure NormalizeColorMx(BMP: TIntegerMatrix); // NEEDS BIG NUMBERS!   HOW BIG?  Can I use byte?
VAR
   Row, Col: Integer;
begin
 VAR AvrgColor := GetAverageValue(BMP);  // Average gray value for the pattern image

 if (Length(BMP)    < 1)
 OR (Length(BMP[0]) < 1)
 then RAISE Exception.Create('Array is empty!');

 for Row := Low(BMP) to High(BMP) do
   for Col := Low(BMP[Row]) to High(BMP[Row]) do
     BMP[Col, Row] := BMP[Row, Row]- AvrgColor;
end;


{ Increase color depth from 8bit to 24bit }
procedure IncreaseClrDepth(Img: TImage);
var
  ColorBitmap: TBitmap;
begin
  // Create a new color bitmap with the same dimensions as the grayscale bitmap
  ColorBitmap := TBitmap.Create;
  try
    ColorBitmap.Assign(Img.Picture.Bitmap);
    ColorBitmap.PixelFormat := pf24bit; // Set to a 24-bit color format

    // Draw on the color bitmap
    Img.Picture.Assign(ColorBitmap);
  finally
    ColorBitmap.Free;
  end;
end;



end.
