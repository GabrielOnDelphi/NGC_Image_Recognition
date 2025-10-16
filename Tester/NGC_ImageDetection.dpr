program NGC_ImageDetection;

uses
  Fastmm4,
  Forms,
  LightCore.AppData, LightVcl.Visual.AppData,
  ngcAppUtils in '..\ngcAppUtils.pas',
  ngcImageUtils in '..\ngcImageUtils.pas',
  ngcCorrel2 in '..\ngcCorrel2.pas',
  ngcCorrel in '..\ngcCorrel.pas',
  TesterForm in 'TesterForm.pas';

{$R *.res}

begin
  AppData:= TAppData.Create('Light NgcTester4', '');
  AppData.CreateMainForm(TfrmTester, frmTester, TRUE, TRUE);
  AppData.Run;
end.
