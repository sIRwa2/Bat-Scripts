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

:: Get the folder name and set the output file name
for %%f in ("%input_folder%") do set "folder_name=%%~nxf"

:: Set the output file path to be in the same folder as the script
set "script_folder=%~dp0"
set "output_folder=%script_folder%Merged"
set "output_file_ext=wav"
set "has_aif_files=false"

:: Create the Merged folder if it doesn't exist
if not exist "%output_folder%" mkdir "%output_folder%"

:: Create a temporary file to store the lengths of the audio files
set "lengths_file=%temp%\lengths.txt"
if exist "%lengths_file%" del "%lengths_file%"

:: Analyze the length of each audio file and find the longest one
set "max_length=0"
for %%f in ("%input_folder%\*.wav") do (
    for /f "tokens=1" %%a in ('%ffmpeg_path% -i "%%f" 2^>^&1 ^| findstr /r /c:"Duration: \([0-9]\+[.0-9]*\)"') do (
        set "length=%%a"
        call :convert_length_to_seconds "!length!"
        if !length! gtr !max_length! set "max_length=!length!"
    )
)
for %%f in ("%input_folder%\*.aif") do (
    for /f "tokens=1" %%a in ('%ffmpeg_path% -i "%%f" 2^>^&1 ^| findstr /r /c:"Duration: \([0-9]\+[.0-9]*\)"') do (
        set "length=%%a"
        set "has_aif_files=true"
        call :convert_length_to_seconds "!length!"
        if !length! gtr !max_length! set "max_length=!length!"
    )
)

:: Add half a second (0.5 seconds) to the longest length
set /a "max_length+=500"

:: Pad all audio files to the new length and convert to WAV format
for %%f in ("%input_folder%\*.wav") do (
    %ffmpeg_path% -i "%%f" -af "apad=whole_dur=!max_length!ms" -ac 1 -acodec pcm_s16le "%output_folder%\padded_%%~nxf.wav"
)
for %%f in ("%input_folder%\*.aif") do (
    %ffmpeg_path% -i "%%f" -af "apad=whole_dur=!max_length!ms" -ac 1 -acodec pcm_s16be "%output_folder%\padded_%%~nxf.aif"
)

:: Create a temporary text file to list all padded audio files
set "filelist=%temp%\filelist.txt"
if exist "%filelist%" del "%filelist%"

:: Iterate through all padded WAV and AIF files in the output folder and add to the file list
for %%f in ("%output_folder%\padded_*.wav") do (
    echo file '%%f' >> "%filelist%"
)
for %%f in ("%output_folder%\padded_*.aif") do (
    echo file '%%f' >> "%filelist%"
)

:: If there are any AIF files, set the output file extension to AIF
if "%has_aif_files%"=="true" (
    set "output_file_ext=aif"
)

set "output_file=%output_folder%\%folder_name%_merged.%output_file_ext%"

:: Run FFmpeg to merge the padded files
%ffmpeg_path% -f concat -safe 0 -i "%filelist%" -c copy "%output_file%"

:: Clean up temporary padded files
for %%f in ("%output_folder%\padded_*.wav") do (
    del "%%f"
)
for %%f in ("%output_folder%\padded_*.aif") do (
    del "%%f"
)

:: Clean up
del "%filelist%"
del "%lengths_file%"

:: Inform the user and close the CMD window
echo Merging completed! The merged file is located at: "%output_file%"
timeout /t 3 >nul
exit

:convert_length_to_seconds
setlocal
set "length=%~1"
set "length=!length:~10,2!!length:~13,2!!length:~16,2!!length:~19,2!"
set /a "length=!length:~0,2!*3600 + !length:~2,2!*60 + !length:~4,2! + !length:~6,2!"
endlocal & set "length=%length%"
goto :eof