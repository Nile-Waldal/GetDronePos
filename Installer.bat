@ECHO off
CD /D %~dp0
SET location=%cd%
IF NOT EXIST "%USERPROFILE%\Desktop\Updating 3D Coordinates" MD "%USERPROFILE%\Desktop\Updating 3D Coordinates" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files"
IF NOT EXIST "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files\Updating 3D Drone Coordinates.bat" XCOPY /s "%location%\Files" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files"
