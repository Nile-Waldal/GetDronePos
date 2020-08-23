@ECHO off

::Declares a counter variable for future use
SET /a cnt=1

::This location is where the matlab code, RinexPrep.exe and NRC desktop app are located
SET "location=%USERPROFILE%\Desktop\Updating 3D Coordinates"
IF NOT EXIST "%location%" (
ECHO "Program Not Installed. Run Installer."
PAUSE
EXIT
)
::Checks for NRC shortcut
IF NOT EXIST "%location%\Files\PPP direct (Updating 3D).lnk" (
IF NOT EXIST "%USERPROFILE%\Desktop\PPP direct (Updating 3D).lnk" (
ECHO No or invalid NRC configuration created. Run ppp direct program to create configuration.
PAUSE
EXIT
) ELSE (
MOVE "%USERPROFILE%\Desktop\PPP direct (Updating 3D).lnk" "%USERPROFILE%\Desktop\Updating 3D Coordinates\Files"
)
)

::Clears Output files for reuse
IF EXIST "%location%\UAV_camera_coords_all.txt" DEL "%location%\UAV_camera_coords_all.txt"
CD "%USERPROFILE%\Desktop\Updating 3D Coordinates\Output"
FOR /f "usebackq" %%G in (`DIR /A /B "%location%\Output\*"`) DO DEL %%~G

:begin

::Prompts User for directory of drone files, i.e. the pictures, .mrk file and .obs file
setlocal

::Opens file browser
set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose a folder.',0,0).self.path""

::Sets folder chosen as photos
for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "photos=%%I"
setlocal enableDelayedExpansion
endlocal

::Checks to see if the path is a valid directory
IF NOT EXIST "%photos%" (
ECHO "Invalid path to directory"
PAUSE
EXIT
)

::Checks to see if the path has a timestamp file
FOR /r "%photos%" %%a in ("*_Timestamp.MRK") DO SET tmsp=%%~nxa
IF NOT DEFINED tmsp (
ECHO "Directory missing Timestamp file"
PAUSE
EXIT
)

::Checks to see if the path has a Rinex file
FOR /r "%photos%" %%a in ("*.obs") DO SET rn=%%~nxa
IF NOT DEFINED rn (
ECHO "Directory missing Rinex file"
PAUSE
EXIT
)

::Checks to see if the path has photos
FOR /r "%photos%" %%a in ("*.jpg") DO SET ph1=%%~nxa
FOR /r "%photos%" %%a in ("*.png") DO SET ph2=%%~nxa
FOR /r "%photos%" %%a in ("*.jpeg") DO SET ph3=%%~nxa
IF NOT DEFINED ph1 (
IF NOT DEFINED ph2 (
IF NOT DEFINED ph3 (
ECHO "Directory missing image files"
PAUSE
EXIT
)
)
)

::Creates folder for outputs
MD "%photos%\Output"
IF EXIST "%location%\%photos%" (
ECHO "Invalid path to directory"
DEL "%location%\%photos%"
PAUSE
EXIT
)

::Formats .obs file to proper specifications
CD "%photos%"
START /WAIT "" "%location%\Files\RinexPrep.exe"

::Sends Rinex.txt to NRC
FOR /r "%photos%" %%a in ("Rinex.txt") DO SET file=%%~nxa
START /WAIT "" "C:\Program Files (x86)\NRCan CGS\PPP direct\PPP direct.exe" "Updating 3D" %file%
IF EXIST "%location%\errors.zip" (
ECHO "Invalid Data sent to NRC"
DEL "%location%\errors.zip"
PAUSE
EXIT
)

::Unzips output
CD "%location%"
powershell Expand-Archive Rinex_full_output.zip '%location%'

::Moves all files to proper locations for execution of Matlab script
CD "%photos%"
MOVE "%photos%\Rinex.txt" "%photos%\Output"
CD "%location%"
REN "%location%\Rinex.pos" Rinex.txt
MOVE "%location%\Rinex.txt" "%photos%"
FOR /r "%location%\Files" %%a in ("*.m") DO SET file=%%~nxa
move "%location%\Files\%file%" "%photos%"

::Runs Matlab Script and moves it back to original location
matlab -wait -batch "try; run('%photos%\GetDronePos.m'); catch; end; quit;"
move "%photos%\%file%" "%location%\Files"
FOR /r "%photos%" %%a in ("UAV_camera_coords_*") DO SET uav=%%~na
IF NOT DEFINED uav (
ECHO "Error in MATLAB Script; UAV_camera_coords.txt not created, check input files"
)

::Cleans up directories and sends all outputs to the output files
CD "%location%"
DEL Rinex_full_output.zip
IF EXIST "%location%\Output\%uav%.txt" (
REN "%location%\Output\%uav%.txt" "%uav%_%cnt%.txt"
cnt+=1
)
XCOPY "%photos%\UAV_camera_coords_*.txt" "%location%\Output"
MOVE "%photos%\UAV_camera_coords_*.txt" "%photos%\Output"
CD "%photos%"
MOVE "%photos%\DronePath.fig" "%photos%\Output"
REN "%photos%\Rinex.txt" RinexNRC.txt
MOVE "%photos%\RinexNRC.txt" "%photos%\Output"
MOVE "%location%\errors.txt" "%photos%\Output"
MOVE "%location%\output_descriptions.txt" "%photos%\Output"
MOVE "%location%\Rinex.csv" "%photos%\Output"
MOVE "%location%\Rinex.pdf" "%photos%\Output"
MOVE "%location%\Rinex.sum" "%photos%\Output"
ECHO "Program succesfully executed"

::Reruns program for more flight data
:rerunstep
SET /p "rerun=Enter more flight data? (y/n)"
IF /I "%rerun%" EQU "y" (
GOTO :begin
) ELSE (
IF /I "%rerun%" EQU "n" (
GOTO :multiple
:end
PAUSE
EXIT
) ELSE (
GOTO :rerunstep
)
)

::Appends all UAV text files into one
:multiple
CD "%location%\Output"
FOR /f "tokens=1,*" %%i in ('dir "UAV_camera_coords_*.txt" ^| findstr "File(s)"') do if %%i gtr 1 type "UAV_camera_coords_*.txt">>"%location%\UAV_camera_coords_all.txt"
GOTO :end
