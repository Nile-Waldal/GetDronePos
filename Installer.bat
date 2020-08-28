@ECHO off

::Sets location to the current folder
CD /D %~dp0
SET location=%cd%

:file

ECHO Select an installation folder

::Opens File Browser
set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose an installation folder.',0,0).self.path""

::Sets folder chosen as install
for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "install=%%I"
setlocal enableDelayedExpansion
endlocal

IF NOT DEFINED "%install%" (
GOTO :file
)

ECHO Installing...

::Moves files to Updating 3D Coordinates if it hasn't yet been installed
IF NOT EXIST "%install%\Updating 3D Coordinates" (
MD "%install%\Updating 3D Coordinates" "%install%\Updating 3D Coordinates\Files" "%install%\Updating 3D Coordinates\Output"
XCOPY /s "%location%\Files" "%install%\Updating 3D Coordinates\Files"
MOVE "%install%\Updating 3D Coordinates\Files\Updating 3D Drone Coordinates.bat" "%install%\Updating 3D Coordinates"
)

ECHO Installed. Create PPP direct configuration before running program.
PAUSE
