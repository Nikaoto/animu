REM This script must be launched from right outside the 'src' dir
REM 'src' is the source dir (where main.lua is)
REM 'build_tmp' is the temporary working dir
REM 'dist' is the dir of the final package

setlocal enabledelayedexpansion
mkdir /p dist
mkdir /p build_tmp

where 7z.exe >nul 2>&1
if errorlevel 1 (
        echo 7z.exe not found
        pause
        exit /b 1
)

REM Create a ZIP file using 7-Zip
cd src
7z a -r -tzip ..\build_tmp\animu.zip .
if errorlevel 1 (
    echo Failed to create the ZIP file.
    pause
    exit /b 1
)
cd ..

REM Rename the ZIP file to have the ".love" extension
cd build_tmp
del animu.love
ren animu.zip animu.love
cd ..

REM Make .exe
copy /b build\love.exe+build_tmp\animu.love build_tmp\animu.exe
copy /b build\lovec.exe+build_tmp\animu.love build_tmp\animu_dbg.exe
del build_tmp\animu.love

REM Copy dlls and license file
copy /Y build\*.dll build_tmp\.
copy /Y build\*.txt build_tmp\.

REM Create zip package
move build_tmp dist\animu_windows
cd dist
7z a -r -tzip animu_windows.zip animu_windows
rmdir /s /q animu_windows
cd ..

rmdir /s /q build_tmp

echo done
pause
exit /b 0


