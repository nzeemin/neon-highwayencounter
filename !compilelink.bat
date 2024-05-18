@echo off
set rt11exe=C:\bin\rt11\rt11.exe

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "DATESTAMP=%YYYY%:%MM%:%DD%"
for /f %%i in ('git rev-list HEAD --count') do (set REVISION=%%i)
echo REV.%REVISION% %DATESTAMP%

echo 	.ASCII /REV;%REVISION%@%DATESTAMP%/ > VERSIO.MAC

@if exist TILES.OBJ del TILES.OBJ
@if exist HWMAIN.LST del HWMAIN.LST
@if exist HWMAIN.OBJ del HWMAIN.OBJ
@if exist HWMAIN.MAP del HWMAIN.MAP
@if exist HWMAIN.SAV del HWMAIN.SAV
@if exist HWMAIN.COD del HWMAIN.COD
@if exist HWYENC.LZS del HWYENC.LZS
@if exist HWBOOT.LST del HWBOOT.LST
@if exist HWBOOT.OBJ del HWBOOT.OBJ
@if exist HWBOOT.SAV del HWBOOT.SAV
@if exist HWYENC.SAV del HWYENC.SAV

%rt11exe% MACRO/LIST:DK: HWMAIN.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" HWMAIN.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo HWMAIN COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " HWMAIN.LST
  echo ======= %errdet% =======
  goto :Failed
)

%rt11exe% LINK HWMAIN /MAP:HWMAIN.MAP

for /f "delims=" %%a in ('findstr /B "Undefined globals" HWMAIN.MAP') do set "undefg=%%a"
if "%undefg%"=="" (
  type HWMAIN.MAP
  echo.
  echo HWMAIN LINKED SUCCESSFULLY
) ELSE (
  echo ======= LINK FAILED =======
  goto :Failed
)

rem Get HWMAIN.SAV code size and cut off parts we don't need
for /f "delims=" %%a in ('findstr /RC:"High limit = " HWMAIN.MAP') do set "codesize=%%a"
set "codesize=%codesize:~49,5%"
rem echo Code limit %codesize% words
set /a codesize="%codesize% * 2"
powershell gc HWMAIN.SAV -Encoding byte -TotalCount %codesize% ^| sc HWMAIN.CO0 -Encoding byte
set /a codesize="%codesize% - 1024"
powershell gc HWMAIN.CO0 -Encoding byte -Tail %codesize% ^| sc HWMAIN.COD -Encoding byte
del HWMAIN.CO0
rem echo Code size %codesize% bytes
dir /-c HWMAIN.COD|findstr /R /C:"HWMAIN.COD"

tools\lzsa3.exe HWMAIN.COD HWYENC.LZS
dir /-c HWYENC.LZS|findstr /R /C:"HWYENC.LZS"
call :FileSize HWYENC.LZS
set "codelzsize=%fsize%"
rem echo Compressed size %codelzsize%

rem Reuse VERSIO.MAC to pass parameters into HWBOOT.MAC
echo HWLZSZ = %codelzsize%. >> VERSIO.MAC

%rt11exe% MACRO/LIST:DK: HWBOOT.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" HWBOOT.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo HWBOOT COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " HWBOOT.LST
  echo ======= %errdet% =======
  goto :Failed
)

%rt11exe% LINK HWBOOT /MAP:HWBOOT.MAP

for /f "delims=" %%a in ('findstr /B "Undefined globals" HWBOOT.MAP') do set "undefg=%%a"
if "%undefg%"=="" (
  type HWBOOT.MAP
  echo.
  echo HWBOOT LINKED SUCCESSFULLY
) ELSE (
  echo ======= LINK FAILED =======
  goto :Failed
)

rename HWBOOT.SAV HWYENC.SAV

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b

:FileSize
set fsize=%~z1
exit /b 0
