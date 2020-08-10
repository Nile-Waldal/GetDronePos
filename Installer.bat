@ECHO off
CD /D %~dp0
SET location=%cd%
IF NOT EXIST "C:\Program Files (x86)\Updating 3D Coordinates\" MD "C:\Program Files (x86)\Updating 3D Coordinates" "C:\Program Files (x86)\Updating 3D Coordinates\Files"
IF NOT EXIST "C:\Program Files (x86)\Updating 3D Coordinates\Files\Updating 3D Drone Coordinates.bat" XCOPY /s "%location%\Files" "C:\Program Files (x86)\Updating 3D Coordinates\Files"