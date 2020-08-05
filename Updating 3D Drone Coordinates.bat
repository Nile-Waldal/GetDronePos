@ECHO off
::Prompts User for directory of drone files, i.e. the pictures, .mrk file and .obs file
SET /p photos="Enter path to directory: "
::Creates folder for outputs
MD "%photos%\Output"

::This location is where the matlab code, RinexPrep.exe and NRC desktop app are located
SET location=C:\Program Files (x86)\Updating 3D Coordinates

::Formats .obs file to proper specifications
CD "%photos%"
START /WAIT "" "%location%\Files\RinexPrep.exe"

::Sends Rinex.txt to NRC
FOR /r "%photos%" %%a in ("Rinex.txt") DO SET file=%%~nxa
START /WAIT "" "C:\Program Files (x86)\NRCan CGS\PPP direct\PPP direct.exe" "Updating 3D" %file%

::Unzips output
CD "%location%"
powershell Expand-Archive Rinex_full_output.zip '%location%'

::Moves all files to proper locations for execution of Matlab script
FOR /r "%location%" %%a in ("Rinex.pos") DO SET file=%%~nxa
CD "%photos%"
MOVE "%photos%\Rinex.txt" "%photos%\Output"
CD "%location%"
REN "%location%\Rinex.pos" Rinex.txt
MOVE "%location%\Rinex.txt" "%photos%"
FOR /r "%location%\Files" %%a in ("GetDronePos.m") DO SET file=%%~nxa
move "%location%\Files\%file%" "%photos%"

::Runs Matlab Script and moves it back to original location
matlab -wait -batch "try; run('%photos%\GetDronePos.m'); catch; end; quit;"
move "%photos%\%file%" "%location%\Files"

::Cleans up directories and sends all outputs to the output files
CD "%location%"
DEL Rinex_full_output.zip
MOVE "%photos%\UAV_camera_coords_*.txt" "%photos%\Output"
CD "%photos%"
REN "%photos%\Rinex.txt" RinexNRC.txt
MOVE "%photos%\RinexNRC.txt" "%photos%\Output"
MOVE "%location%\errors.txt" "%photos%\Output"
MOVE "%location%\output_descriptions.txt" "%photos%\Output"
MOVE "%location%\Rinex.csv" "%photos%\Output"
MOVE "%location%\Rinex.pdf" "%photos%\Output"
MOVE "%location%\Rinex.sum" "%photos%\Output"
