@echo off
set rt11dsk=C:\bin\rt11dsk

del x-neonbtl\System.dsk
@if exist "x-neonbtl\System.dsk" (
  echo.
  echo ####### FAILED to delete old disk image file #######
  exit /b
)
copy x-neonbtl\SystemOrig.dsk System.dsk
%rt11dsk% a System.dsk HWYENC.SAV
%rt11dsk% a System.dsk HWYSCR.LZS
%rt11dsk% a System.dsk HWYENC.LZS
move System.dsk x-neonbtl\System.dsk

@if not exist "x-neonbtl\System.dsk" (
  echo ####### ERROR disk image file not found #######
  exit /b
)

start x-neonbtl\neonbtl.exe
