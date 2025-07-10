UNIT ngcCorrel2;

{=============================================================================================================
  NGC Region detection
  ------------------------------------------------------------------------------------------------------------
  2023
  www.GabrielMoraru.com
  ------------------------------------------------------------------------------------------------------------
  The Pattern could appear several times in the MainImage.
  This unit returns a sorted list of the best correlation (top positions).
     The first item in the list is the best result.
     The list only contains isolated, independent sources.
     For each entry, it shows X,Y and gray value.
  Regions:
    Pixels that have a good brightness but belong to a position that has already been found
    are not counted as found locations again.
=============================================================================================================}

INTERFACE

USES
  WinApi.Windows, System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  System.Math, Vcl.Graphics, Vcl.ExtCtrls, Vcl.StdCtrls,
  ngcImageUtils, ngcCorrel;

TYPE
   RBrightPoint = record
     Brightness: Byte;
     X, Y: Integer;       // Coordinates where the pattern was found in the image
     procedure Clear;
   end;

   PBrightPoint= ^RBrightPoint;

TYPE
   TBrightnessList= class(TList<PBrightPoint>)    // Stores the final list of brightest points. Later we sort and truncate the list
   end;

TYPE
  PPixelArray = PByte;

TYPE
   TCorrel2= class(TCorrel)
    private
     { Region in which we have to found the brightest pixel The region is expanded dynamically as new bright points belonging to this cluster are discovered }
     RegStartX, RegEndX: Integer;    //Note: TRect could be used instead of this
     RegStartY, RegEndY: Integer;
     function findBrigthPxOnLine(LineNr, XPixel: Integer; var BrPoint: RBrightPoint): Boolean;
    public
     FinalBMP: TBitmap;               // Final black image withthe white dots
     Regions : TBrightnessList;

     constructor Create; override;
     destructor Destroy; override;

     procedure Clear;
     procedure GetRegions;
     procedure ShowPixels;
     procedure DrawBoxes(Image: TImage; BrightnessThresh: Integer);
     procedure ReleaseRegions;        // Clean up regions
     procedure PopulateResults(ListBox: TListBox; TopResultsCount: Integer);
    public
     procedure CopyBrightPixels(BrightnessThresh: Integer); // This is public only for demonstrational purposes (GUI)
   end;


IMPLEMENTATION

CONST
   Bkg= 0;  //Default= 0 but we use a slight shade of gray (50) so we can visualize the detected objects


constructor TCorrel2.Create;
begin
  inherited Create;
  FinalBMP:= TBitmap.Create;
end;


destructor TCorrel2.Destroy;
begin
  Clear;
  FreeAndNil(FinalBMP);
  FreeAndNil(Regions);
  inherited Destroy;
end;


procedure TCorrel2.Clear;
begin
  ReleaseRegions;
  OutputBMP.Assign(NIL);
end;




{--------------------------------------------------------------------------------------------------
   Step 2

   Copy all pixels with brighness over the threshold from main image to the result image.
--------------------------------------------------------------------------------------------------}
procedure TCorrel2.copyBrightPixels(BrightnessThresh: Integer);
VAR
  y, x: Integer;
  LineI, LineO: PPixelArray;
begin
 //Load input img into the output image
 FinalBMP.Assign(OutputBMP);
 FinalBMP.Palette:= OutputBMP.Palette;

 // Blank the output image
 FillBitmap(FinalBMP, clBlack);

 for y:= BorderH to OutputBMP.Height -1 -BorderH DO
  begin
   // Pointer to line's raw data
   LineI := OutputBMP.ScanLine[y];   // Input
   LineO := FinalBMP.ScanLine[y];    // Output

   // Copy in a secondary BMP pixels that are over the threshold
   for x := BorderW to OutputBMP.Width -1 -BorderW DO
     if LineI[x] >= BrightnessThresh
     then LineO[x]:= LineI[x];
  end;
end;



{--------------------------------------------------------------------------------------------------
   Step 3

   Find the brightes point on this line
   Find how large is the region (on this line)
--------------------------------------------------------------------------------------------------}
function TCorrel2.findBrigthPxOnLine(LineNr, XPixel: Integer; VAR BrPoint: RBrightPoint): Boolean;
VAR
   x2: Integer;
   BlackFound: Boolean;
   CurLine: PPixelArray;
begin
 Result:= FALSE;
 CurLine:= FinalBMP.ScanLine[LineNr];

 if CurLine[XPixel] > Bkg then
  begin
    Result:= TRUE;

    if RegStartX < 0
    then RegStartX:= XPixel;  // We start a new region
    if RegStartY < 0
    then RegStartY:= LineNr;

    RegEndY:= LineNr;

    // SCAN TO RIGHT
    x2:= XPixel;
    REPEAT
     // Search for the next black pixel. When found, we know that our region ended
     BlackFound:= CurLine[x2] <= Bkg;
     if NOT BlackFound then
       if CurLine[x2]> BrPoint.Brightness then
        begin
         BrPoint.Brightness:= CurLine[x2];  // Highest brightness in the region (until now)
         BrPoint.X:= x2;
         BrPoint.Y:= LineNr;
        end;

     CurLine[x2]:= Bkg;                 // We know we don't need this pixel anymore. Clear it.
     Inc(x2);                           // Keep scanning this line until the first back pixel is found
    UNTIL BlackFound OR (x2 >= FinalBMP.Width-BorderW);

    if x2> RegEndX
    then RegEndX:= x2;                  // Expand region to the right


    // SCAN TO LEFT
    x2:= XPixel;
    REPEAT
     Dec(x2);                           // Keep scanning this line until the first back pixel is found

     // Search for the next black pixel. When found, we know that our region ended
     BlackFound:= CurLine[x2] <= Bkg;   //ToDo: This could be written as a sub-procedure because it is identical with the code above
     if NOT BlackFound then
       if CurLine[x2]> BrPoint.Brightness then
        begin
         BrPoint.Brightness := CurLine[x2];  // Highest brightness in the region (until now)
         BrPoint.X:= x2;
         BrPoint.Y:= LineNr;
        end;

     CurLine[x2]:= Bkg;                 // We know we don't need this pixel anymore. Clear it.
    UNTIL BlackFound OR (x2 <= 0);

    if x2< RegStartX
    then RegStartX:= x2;                // Expand region to the left
   end;
end;


{ Return a list containing the brightest regions }
procedure TCorrel2.GetRegions;
VAR
   Line: PPixelArray;
   x, y, y2: Integer;
   BrightPointP: PBrightPoint;
   BrightPoint: RBrightPoint;

 procedure Reset;
 begin
   BrightPoint.Clear;
   RegStartX:= -1;
   RegEndX  := -1;
   RegStartY:= -1;
   RegEndY  := -1;
 end;

begin
 if Regions = NIL
 then Regions:= TBrightnessList.Create
 else ReleaseRegions;  // Clean up

 Reset;

 // Find regions and decimate non-interesting pixels from these regions
 for y:= BorderH to FinalBMP.Height -1 -BorderH DO
  begin
   x:= 0;
   Line:= FinalBMP.ScanLine[y];

   WHILE x < FinalBMP.Width -BorderW DO                     // Cannot use a 'for' loop because we want to increment x manualy to be equal with the end of the region (once the region is found)
    begin

     //todo: use a "while" here
     //done: calling a function is extremelly expensive. test the pixel here directly.
     if Line[x] > Bkg then
      begin
       // We scan pixels on this line for white values, starting from pixel x
       y2:= y-1;

       REPEAT                                             // Scan next line(s)
         Inc(y2);
       UNTIL NOT FindBrigthPxOnLine(y2, x, BrightPoint) OR (y2 >= FinalBMP.Height-BorderH);

       x:= RegEndX+1;                                     // Increment x manualy to be equal with the end of the region (once the region is found) so we don't have to rescan this region
      end;

     Inc(x);

     if BrightPoint.Brightness > 0 then
      begin
       // Found brightest point in this region. Store it.
       System.New(BrightPointP);
       BrightPointP.Brightness:= BrightPoint.Brightness;
       BrightPointP.X:= BrightPoint.x;
       BrightPointP.Y:= BrightPoint.y;
       Regions.Add(BrightPointP);

       Reset;  // Prepare for the next cycle
      end;
    end;
  end;

 // Sort points by brightness
 Regions.Sort(TComparer<PBrightPoint>.Construct(
      function(CONST A,B: PBrightPoint): Integer
      begin
        Result:= System.Math.CompareValue(B.Brightness, A.Brightness);
      end));
end;


{ Put the brightest pixels back (only for demonstrational purposes) }
procedure TCorrel2.ShowPixels;
VAR
   Line: PPixelArray;
begin
   for VAR Region in Regions DO
    begin
      Line:= FinalBMP.ScanLine[Region.Y];  //ToDo: minify
      Line[Region.x]:= Region.Brightness;
    end;
end;



{ Eliminate all regions with brightness under this threshold }
procedure TCorrel2.DrawBoxes(Image: TImage; BrightnessThresh: Integer);
begin
  MainBMP.PixelFormat:= pf32bit;
  IncreaseClrDepth(Image);

  for VAR i:= 0 to Regions.Count- 1 DO
   begin
    VAR Region:= Regions[i];
    if Region.Brightness > BrightnessThresh then
      begin
       MainBMP.Canvas.Pen.Color  := clRed;
       MainBMP.Canvas.Brush.Style:= bsClear;
       MainBMP.Canvas.Rectangle(Region.x, Region.y, Region.x+ BorderW, Region.y+ BorderH);
      end;
   end;

  //MainBMP.SaveToFile('DrawBoxes.bmp');  //For debug
  Image.Picture.Assign(MainBMP);
end;


{ Clean up }
procedure TCorrel2.ReleaseRegions;
begin
  if Regions = NIL then EXIT;

  for VAR i:= Regions.Count-1 downto 0
    DO System.Dispose(Regions[i]);
  Regions.Clear;
end;


procedure RBrightPoint.Clear;
begin
  X:= 0;
  Y:= 0;
  Brightness := 0;
end;



// Keep in the list only the first x values
procedure TCorrel2.PopulateResults(ListBox: TListBox; TopResultsCount: Integer);
begin
  ListBox.Items.Clear;
  ListBox.Items.BeginUpdate;
  for VAR i:= 0 to TopResultsCount- 1 DO
   begin
    if i >= Regions.Count then Break;  // Do we have enough results to show?
    ListBox.Items.Add(' Br= '+ IntToStr(Regions[i].Brightness)
                    + '  X= '+ IntToStr(Regions[i].X)
                    + '  Y= '+ IntToStr(Regions[i].Y));
   end;
  ListBox.Items.EndUpdate;
end;


end.
