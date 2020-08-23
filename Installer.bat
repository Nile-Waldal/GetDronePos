@ECHO off

::Sets location to the current folder
CD /D %~dp0
SET location=%cd%

::Moves files to Desktop\Updating 3D Coordinates if it hasn't yet been installed
IF NOT EXIST "%USERPROFILE%\Desktop\Updating 3D Coordinates" MD "%USERPROFILE%\Desktop\Updating 3D Coordinates" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Output"
IF NOT EXIST "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files\Updating 3D Drone Coordinates.bat" XCOPY /s "%location%\Files" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files"
