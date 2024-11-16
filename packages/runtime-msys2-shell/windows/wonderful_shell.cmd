@echo off
setlocal EnableDelayedExpansion

rem Based on msys2_shell.cmd (BSD-3-Clause)
set "WD=%~dp0\..\..\usr\bin\"
set "LOGINSHELL=bash"
set /a msys2_shiftCounter=0

rem Wonderful shell configuration
set MSYS2_PATH_TYPE=inherit
set MSYSTEM=UCRT64
set "PATH=%WD%../../opt/wonderful/bin;%PATH%"
set "CONTITLE=Wonderful Toolchain Shell"
set "CONICON=wonderful_shell.ico"

set BLOCKSDS=/opt/wonderful/thirdparty/blocksds/core
set BLOCKSDSEXT=/opt/wonderful/thirdparty/blocksds/external
set WONDERFUL_TOOLCHAIN=/opt/wonderful

:checkparams
rem Help option
if "x%~1" == "x-help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x--help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x-?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x/?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
rem Console types
if "x%~1" == "x-mintty" shift& set /a msys2_shiftCounter+=1& set MSYSCON=mintty.exe& goto :checkparams
if "x%~1" == "x-conemu" shift& set /a msys2_shiftCounter+=1& set MSYSCON=conemu& goto :checkparams
if "x%~1" == "x-defterm" shift& set /a msys2_shiftCounter+=1& set MSYSCON=defterm& goto :checkparams
rem Other parameters
if "x%~1" == "x-full-path" shift& set /a msys2_shiftCounter+=1& set MSYS2_PATH_TYPE=inherit& goto :checkparams
if "x%~1" == "x-use-full-path" shift& set /a msys2_shiftCounter+=1& set MSYS2_PATH_TYPE=inherit& goto :checkparams
if "x%~1" == "x-here" shift& set /a msys2_shiftCounter+=1& set CHERE_INVOKING=enabled_from_arguments& goto :checkparams
if "x%~1" == "x-where" (
  if "x%~2" == "x" (
    echo Working directory is not specified for -where parameter. 1>&2
    exit /b 2
  )
  cd /d "%~2" || (
    echo Cannot set specified working diretory "%~2". 1>&2
    exit /b 2
  )
  set CHERE_INVOKING=enabled_from_arguments

  rem Ensure parentheses in argument do not interfere with FOR IN loop below.
  set msys2_arg="%~2"
  call :substituteparens msys2_arg
  call :removequotes msys2_arg

  rem Increment msys2_shiftCounter by number of words in argument (as cmd.exe saw it).
  rem (Note that this form of FOR IN loop uses same delimiters as parameters.)
  for %%a in (!msys2_arg!) do set /a msys2_shiftCounter+=1
)& shift& shift& set /a msys2_shiftCounter+=1& goto :checkparams
if "x%~1" == "x-no-start" shift& set /a msys2_shiftCounter+=1& set MSYS2_NOSTART=yes& goto :checkparams
if "x%~1" == "x-shell" (
  if "x%~2" == "x" (
    echo Shell not specified for -shell parameter. 1>&2
    exit /b 2
  )
  set LOGINSHELL="%~2"
  call :removequotes LOGINSHELL
  
  set msys2_arg="%~2"
  call :substituteparens msys2_arg
  call :removequotes msys2_arg
  for %%a in (!msys2_arg!) do set /a msys2_shiftCounter+=1
)& shift& shift& set /a msys2_shiftCounter+=1& goto :checkparams

rem Collect remaining command line arguments to be passed to shell
if %msys2_shiftCounter% equ 0 set SHELL_ARGS=%* & goto cleanvars
set msys2_full_cmd=%*
for /f "tokens=%msys2_shiftCounter%,* delims=,;=	 " %%i in ("!msys2_full_cmd!") do set SHELL_ARGS=%%j

:cleanvars
set msys2_arg=
set msys2_shiftCounter=
set msys2_full_cmd=

if "x%MSYSCON%" == "xmintty.exe" goto startmintty
if "x%MSYSCON%" == "xconemu" goto startconemu
if "x%MSYSCON%" == "xdefterm" goto startsh

if NOT EXIST "%WD%mintty.exe" goto startsh
set MSYSCON=mintty.exe
:startmintty
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%WD%mintty" -i "%WD%../../opt/wonderful/%CONICON%" -t "%CONTITLE%" "/usr/bin/%LOGINSHELL%" -l !SHELL_ARGS!
) else (
  "%WD%mintty" -i "%WD%../../opt/wonderful/%CONICON%" -t "%CONTITLE%" "/usr/bin/%LOGINSHELL%" -l !SHELL_ARGS!
)
exit /b %ERRORLEVEL%

:startconemu
call :conemudetect || (
  echo ConEmu not found. Exiting. 1>&2
  exit /b 1
)
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%ComEmuCommand%" /Here /Icon "%WD%../../opt/wonderful/%CONICON%" /cmd "%WD%\%LOGINSHELL%" -l !SHELL_ARGS!
) else (
  "%ComEmuCommand%" /Here /Icon "%WD%../../opt/wonderful/%CONICON%" /cmd "%WD%\%LOGINSHELL%" -l !SHELL_ARGS!
)
exit /b %ERRORLEVEL%

:startsh
set MSYSCON=
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%WD%\%LOGINSHELL%" -l !SHELL_ARGS!
) else (
  "%WD%\%LOGINSHELL%" -l !SHELL_ARGS!
)
exit /b %ERRORLEVEL%

:EOF
exit /b 0

:conemudetect
set ComEmuCommand=
if defined ConEmuDir (
  if exist "%ConEmuDir%\ConEmu64.exe" (
    set "ComEmuCommand=%ConEmuDir%\ConEmu64.exe"
    set MSYSCON=conemu64.exe
  ) else if exist "%ConEmuDir%\ConEmu.exe" (
    set "ComEmuCommand=%ConEmuDir%\ConEmu.exe"
    set MSYSCON=conemu.exe
  )
)
if not defined ComEmuCommand (
  ConEmu64.exe /Exit 2>nul && (
    set ComEmuCommand=ConEmu64.exe
    set MSYSCON=conemu64.exe
  ) || (
    ConEmu.exe /Exit 2>nul && (
      set ComEmuCommand=ConEmu.exe
      set MSYSCON=conemu.exe
    )
  )
)
if not defined ComEmuCommand (
  FOR /F "tokens=*" %%A IN ('reg.exe QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu64.exe" /ve 2^>nul ^| find "REG_SZ"') DO (
    set "ComEmuCommand=%%A"
  )
  if defined ComEmuCommand (
    call set "ComEmuCommand=%%ComEmuCommand:*REG_SZ    =%%"
    set MSYSCON=conemu64.exe
  ) else (
    FOR /F "tokens=*" %%A IN ('reg.exe QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu.exe" /ve 2^>nul ^| find "REG_SZ"') DO (
      set "ComEmuCommand=%%A"
    )
    if defined ComEmuCommand (
      call set "ComEmuCommand=%%ComEmuCommand:*REG_SZ    =%%"
      set MSYSCON=conemu.exe
    )
  )
)
if not defined ComEmuCommand exit /b 2
exit /b 0

:printhelp
echo Usage:
echo     %~1 [options] [login shell parameters]
echo.
echo Options:
echo     -defterm ^| -mintty ^| -conemu                            Set terminal type
echo     -here                            Use current directory as working
echo                                      directory
echo     -where DIRECTORY                 Use specified DIRECTORY as working
echo                                      directory
echo     -[use-]full-path                 Use full current PATH variable
echo                                      instead of trimming to minimal
echo     -no-start                        Do not use "start" command and
echo                                      return login shell resulting 
echo                                      errorcode as this batch file 
echo                                      resulting errorcode
echo     -shell SHELL                     Set login shell
echo     -help ^| --help ^| -? ^| /?         Display this help and exit
echo.
echo Any parameter that cannot be treated as valid option and all
echo following parameters are passed as login shell command parameters.
echo.
exit /b 0

:removequotes
FOR /F "delims=" %%A IN ('echo %%%1%%') DO set %1=%%~A
GOTO :eof

:substituteparens
SETLOCAL
FOR /F "delims=" %%A IN ('echo %%%1%%') DO (
    set value=%%A
    set value=!value:^(=x!
    set value=!value:^)=x!
)
ENDLOCAL & set %1=%value%
GOTO :eof
