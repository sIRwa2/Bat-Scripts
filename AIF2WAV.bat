@echo off
setlocal enabledelayedexpansion

:: Check if FFmpeg is in the same directory as the script, or specify the path to FFmpeg
set "ffmpeg_path=ffmpeg.exe"

:: Check if a folder was dragged and dropped onto the script
if "%~1"=="" (
    echo Please drag and drop a folder onto this script.
    pause
    exit /b
)

:: Get the folder path from the dropped argument
set "input_folder=%~1"

:: Create the output folder for converted files
set "output_folder=%input_folder%\converted"
if not exist "%output_folder%" mkdir "%output_folder%"

:: Convert all .aif files to .wav and place them in the "converted" subfolder
for %%f in ("%input_folder%\*.aif") do (
    echo Processing "%%~nxf"...
    "%ffmpeg_path%" -i "%%f" -acodec pcm_s16le -ar 44100 "%output_folder%\%%~nf.wav"
)

echo Conversion completed! Converted .wav files are located in: "%output_folder%"
pause
exit
::

//


###
