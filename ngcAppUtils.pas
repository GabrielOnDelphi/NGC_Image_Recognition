UNIT ngcAppUtils;

{=============================================================================================================
  NGC App Utils
  ------------------------------------------------------------------------------------------------------------
  2024.12
  www.GabrielMoraru.com
  ------------------------------------------------------------------------------------------------------------
  General functions.
  All these are available in my LightSaber library, but I wanted to decrease dependency on that library,
   so I copied them here.
==============================================================================================================}

INTERFACE

USES
   Winapi.Windows, Winapi.ShellAPI, System.SysUtils, Vcl.Dialogs, Vcl.Forms, LightVcl.Visual.AppDataForm,Vcl.Graphics,
   System.Diagnostics;

CONST
   CRLF  = #13#10;

function  FileExistsMsg(CONST FileName: string): Boolean;
function  GetAppDir: string;                        { Returns path ended with backslash. Works with UNC paths }
function  CommandLinePath: string;                  { Tested ok. Returns the path sent as command line param }

procedure TimerStart;                               { use it with: SetPriorityMax }
function  TimerElapsed: Double;                     { In miliseconds }
function  TimerElapsedS: string;                    { In seconds/miliseconds }

procedure SetPriorityMax;                           { Set this process to maximum priority. Usefull when measuring time }
function  RangeToByte(x: Double): Byte;             { Converts numbers in -1 +1 range to 0..255 range }

function  ExecuteShell(CONST ExeFile: string; Params: string= ''; ShowErrorMsg: Boolean= TRUE; WindowState: Integer= WinApi.Windows.SW_SHOWNORMAL): Boolean;


IMPLEMENTATION



function RangeToByte(x: Double): Byte; // Converts numbers in -1 +1 range to 0..255 range
begin
 Result:= round(127.5 + 127.5 * x);   //ToDo: decide what kind of rounding we need here. See RoundEx
end;



function FileExistsMsg(CONST FileName: string): Boolean;
begin
 Result:= FileExists(FileName);
 if NOT Result then
   if FileName= ''
   then ShowMessage('No file specified!')
   else ShowMessage('File does not exist!'+ CRLF+ FileName);
end;


function GetAppDir: string;          { Returns path ended with backslash. Works with UNC paths }
begin
 Result:= ExtractFilePath(Application.ExeName);
end;


function CommandLinePath: string;    { Tested ok. Returns the path sent as command line param }
begin
 if ParamCount > 0
 then Result:= Trim(ParamStr(1))     { Do we have parameter into the command line? }
 else Result := '';
end;




{--------------------------------------------------------------------------------------------------
   CODE TIMING
--------------------------------------------------------------------------------------------------

   How to use it:
      Call TimerStart, call the function that needs to be timed then call TimerElapsed

   Use it only for small intervals (way under 1 day)!

   Source: http://stackoverflow.com/questions/6420051/why-queryperformancecounter-timed-different-from-wall-clock
   https://blogs.msdn.microsoft.com/oldnewthing/20050902-00/?p=34333
--------------------------------------------------------------------------------------------------}
VAR
   sw: TStopWatch;

procedure TimerStart;   //use it with: SetPriorityMax
begin
  sw := TStopWatch.Create;      //I can use directly: TStopWatch.CreateNew
  if NOT TStopWatch.IsHighResolution
  then ShowMessage('High resolution timer not availalbe!');
  sw.Start;
end;


function TimerElapsed: Double;        { In miliseconds }
begin
  Result:= sw.ElapsedMilliseconds;
  sw.Stop;
end;


function TimerElapsedS: string;       { In seconds/miliseconds }
var
   elapsedMilliseconds : Int64;
begin
 elapsedMilliseconds:= sw.ElapsedMilliseconds;
 if elapsedMilliseconds < 1000
 then Result:= floattostrf(elapsedMilliseconds, ffGeneral, 4, 2)+ 'ms'
 else Result:= floattostrf(elapsedMilliseconds / 1000, ffGeneral, 4, 2)+ 's';
 sw.Stop;
end;


{ Set this process to maximum priority. Usefull when measuring time.
  Note: On Win7 real time priority cannot be set unless the program is runnin with administrator priviledges.
  Instead it will run as high priority! }
procedure SetPriorityMax;
begin
 SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
end;



procedure FillBitmap(InputBitmap: TBitmap; Color: TColor);
begin
 InputBitmap.Canvas.Brush.Color:= Color;
 InputBitmap.Canvas.Brush.Style:= bsSolid;
 InputBitmap.Canvas.FillRect(InputBitmap.Canvas.ClipRect);
end;








{-------------------------------------------------------------------------------------------------------------
 WindowState
     Can be as defined in Windows.pas:
     SW_HIDE, SW_SHOWNORMAL, SW_NORMAL, SW_SHOWMINIMIZED, SW_SHOWMAXIMIZED, SW_MAXIMIZE, SW_SHOWNOACTIVATE, SW_SHOW, SW_MINIMIZE, SW_SHOWMINNOACTIVE, SW_SHOWNA, SW_RESTORE, SW_SHOWDEFAULT, SW_MAX

 Description of each parameter:  http://msdn.microsoft.com/en-us/library/windows/desktop/ms633548%28v=vs.85%29.aspx

 Official documentation:
      https://msdn.microsoft.com/en-US/bb762153?f=255&MSPPError=-2147217396
 More:
     http://tekreaders.com/blog/2011/08/03/shellexecute-in-delphi-launch-external-applications/

 This does not work well with *.scr programs: https://stackoverflow.com/questions/46672282/how-to-run-a-screensaver-in-config-mode-with-shellexecute

 ShellExecute return codes:
   If the function succeeds, it sets the hInstApp member of the SHELLEXECUTEINFO structure to a value greater than 32. If the function fails, hInstApp is set to the SE_ERR_XXX error value that best indicates the cause of the failure. Although hInstApp is declared as an HINSTANCE for compatibility with 16-bit Windows applications, it is not a true HINSTANCE. It can be cast only to an int and can be compared only to either the value 32 or the SE_ERR_XXX error codes.
   The SE_ERR_XXX error values are provided for compatibility with ShellExecute.
   To retrieve more accurate error information, use GetLastError. It may return one of the following values:
      // Error code definitions for the Win32 API functions
      { 02  ERROR_FILE_NOT_FOUND    : Msg:= 'The specified file was not found.';
      { 03  ERROR_PATH_NOT_FOUND    : Msg:= 'The specified path was not found.';
      { 08  ERROR_NOT_ENOUGH_MEMORY : Msg:= 'There is not enough memory to perform the specified action!';
      { 11  ERROR_BAD_FORMAT        : Msg:= 'The .exe file is invalid (non-Win32 .EXE or error in .EXE image).';
      { 32  ERROR_SHARING_VIOLATION : Msg:= 'A sharing violation occurred!';
      {1156 ERROR_DDE_FAIL          : Msg:= 'The Dynamic Data Exchange (DDE) transaction failed!';
            ERROR_ACCESS_DENIED     : Msg:= 'Access to the specified file is denied!';
            ERROR_CANCELLED         : Msg:= 'The function prompted the user for additional information, but the user canceled the request!';
            ERROR_DLL_NOT_FOUND     : Msg:= 'One of the library files necessary to run the application can't be found!';
            ERROR_NO_ASSOCIATION    : Msg:= 'There is no application associated with the specified file name extension!'
-------------------------------------------------------------------------------------------------------------}
function ExecuteShell(CONST ExeFile: string; Params: string= ''; ShowErrorMsg: Boolean= TRUE; WindowState: Integer= WinApi.Windows.SW_SHOWNORMAL): Boolean;
VAR
   i: integer;
   Msg: string;
begin
 i:= ShellExecute(0, 'open', PChar(ExeFile), Pointer(Params), NIL, WindowState);   //  See this about using 'Pointer' instead of 'PChar': http://stackoverflow.com/questions/3048188/shellexecute-not-working-from-ide-but-works-otherwise
 Result:= i > 32;
 if NOT Result AND ShowErrorMsg then
  begin
   case i of
      // What are these?
      0  : Msg:= 'The operating system is out of memory or resources.';
      12 : Msg:= 'Application was designed for a different operating system.';
      13 : Msg:= 'Application was designed for MS-DOS 4.0';
      15 : Msg:= 'Attempt to load a real-mode program.';
      16 : Msg:= 'Attempt to load a second instance of an application with non-readonly data segments.';
      19 : Msg:= 'Attempt to load a compressed application file.';
      20 : Msg:= 'Dynamic-link library (DLL) file failure.';

      // Regular WinExec codes
      { 02} SE_ERR_FNF            : Msg:= 'Exe file not found!'+ ExeFile;
      { 03} SE_ERR_PNF            : Msg:= 'Path not found!';
      { 08} SE_ERR_OOM            : Msg:= 'Out of memory!';

      // Error values for ShellExecute beyond the regular WinExec() codes
      { 26} SE_ERR_SHARE          : Msg:= 'A sharing violation occurred!';
      { 27} SE_ERR_ASSOCINCOMPLETE: Msg:= 'The file name association is incomplete or invalid!';
      { 28} SE_ERR_DDETIMEOUT     : Msg:= 'The DDE transaction could not be completed because the request timed out!';
      { 29} SE_ERR_DDEFAIL        : Msg:= 'The DDE transaction failed!';
      { 30} SE_ERR_DDEBUSY        : Msg:= 'The DDE transaction could not be completed because other DDE transactions were being processed!';
      { 31} SE_ERR_NOASSOC        : Msg:= 'There is no application associated with the given file name extension!';

      { 05} SE_ERR_ACCESSDENIED   : Msg:= 'The operating system denied access! Do you have admin rights?';       // https://answers.microsoft.com/en-us/windows/forum/windows_7-windows_programs/getting-error-shellexecuteex-failed-code-5-access/3af7bea3-5733-426c-9e12-6ec68bf7b38b?auth=1
      { 32} SE_ERR_DLLNOTFOUND    : Msg:= 'The specified DLL was not found!'
     else
        Msg:= 'ShellExecute error '+ IntToStr(i);
   end;

   ShowMessage(Msg);
  end;
end;





end.
