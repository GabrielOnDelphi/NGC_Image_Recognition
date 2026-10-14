program NGC_ImageDetection;

uses
  Fastmm4,
  Forms,
  LightCore.AppData, LightVcl.Visual.AppData,
  ngcAppUtils in '..\ngcAppUtils.pas',
  ngcImageUtils in '..\ngcImageUtils.pas',
  ngcCorrel2 in '..\ngcCorrel2.pas',
  ngcCorrel in '..\ngcCorrel.pas',
  {$IFDEF AUTOPILOT}Autopilot.Bridge.Vcl in 'c:\Projects\Projects AI\Autopilot for Delphi\Source\Bridge\Autopilot.Bridge.Vcl.pas',{$ENDIF}{Optional}
  TesterForm in 'TesterForm.pas';

{$R *.res}

begin
  AppData:= TAppData.Create('Light NgcTester4', '');
  Application.MainFormOnTaskbar:= TRUE;
  AppData.CreateMainForm(TfrmTester, frmTester, asFull);

  { Optional: Via Autopilot, Claude can run/debug/test this program for you.
    For example, press "1. Calculate", then "2. Show results regions" & read the coordinates of the matches in lbxResults.
    Don't have AUTOPILOT? Undefine $AUTOPILOT or get it from www.GabrielMoraru.com }
  {$IFDEF AUTOPILOT}
   Autopilot.Bridge.Vcl.StartBridge;
  {$ENDIF}
  AppData.Run;
end.
