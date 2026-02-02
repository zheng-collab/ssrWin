@echo off
setlocal enabledelayedexpansion

:: SSRWin Package Script
:: Builds and packages the application into a distributable folder

echo ============================================
echo   SSRWin Package Script
echo ============================================
echo.

set CONFIG=Release
set PLATFORM=x64
set OUTDIR=dist\ssrWin-x64

:: Parse arguments
:parse_args
if "%~1"=="" goto :start
if /i "%~1"=="x86" (
    set PLATFORM=Win32
    set OUTDIR=dist\ssrWin-x86
)
if /i "%~1"=="debug" set CONFIG=Debug
shift
goto :parse_args

:start
echo Configuration: %CONFIG%
echo Platform: %PLATFORM%
echo Output: %OUTDIR%
echo.

:: Step 1: Build the project
echo [1/4] Building project...
call build.bat %CONFIG% %PLATFORM%
if errorlevel 1 (
    echo ERROR: Build failed!
    exit /b 1
)
echo.

:: Step 2: Create output directory
echo [2/4] Creating distribution folder...
if exist "%OUTDIR%" rmdir /s /q "%OUTDIR%"
mkdir "%OUTDIR%"

:: Step 3: Copy files
echo [3/4] Copying files...

:: Determine source directory
if "%PLATFORM%"=="x64" (
    set SRCDIR=src\x64\%CONFIG%
) else (
    set SRCDIR=src\%CONFIG%
)

:: Copy main executable
copy "%SRCDIR%\ssrWin.exe" "%OUTDIR%\" >nul
if errorlevel 1 (
    echo ERROR: ssrWin.exe not found in %SRCDIR%
    exit /b 1
)
echo   Copied: ssrWin.exe

:: Copy route service if exists
if exist "%SRCDIR%\routeService.exe" (
    copy "%SRCDIR%\routeService.exe" "%OUTDIR%\" >nul
    echo   Copied: routeService.exe
)

:: Copy TAP driver files
echo   Copying TAP drivers...
mkdir "%OUTDIR%\tap-windows6" 2>nul
if "%PLATFORM%"=="x64" (
    xcopy /s /q "tap-windows6\amd64\*" "%OUTDIR%\tap-windows6\" >nul 2>&1
    xcopy /s /q "tap-windows6\include\*" "%OUTDIR%\tap-windows6\" >nul 2>&1
) else (
    xcopy /s /q "tap-windows6\i386\*" "%OUTDIR%\tap-windows6\" >nul 2>&1
    xcopy /s /q "tap-windows6\include\*" "%OUTDIR%\tap-windows6\" >nul 2>&1
)
echo   Copied: TAP driver files

:: Copy any DLLs from source directory
for %%f in ("%SRCDIR%\*.dll") do (
    copy "%%f" "%OUTDIR%\" >nul
    echo   Copied: %%~nxf
)

:: Step 4: Create info file
echo [4/4] Creating package info...
(
echo SSRWin - ShadowsocksR for Windows
echo ==================================
echo.
echo Version: Built from source
echo Platform: %PLATFORM%
echo Configuration: %CONFIG%
echo Build Date: %date% %time%
echo.
echo Files included:
echo   - ssrWin.exe          : Main application
echo   - tap-windows6\       : TAP network driver
echo.
echo Installation:
echo   1. Run ssrWin.exe
echo   2. If prompted, install TAP driver from tap-windows6 folder
echo.
echo Language Support:
echo   - English ^(default^)
echo   - Chinese Simplified ^(auto-detected from system^)
echo.
echo GitHub: https://github.com/ShadowsocksR-Live/ssrWin
) > "%OUTDIR%\README.txt"

echo.
echo ============================================
echo   PACKAGING COMPLETE
echo ============================================
echo.
echo Distribution folder: %OUTDIR%
echo.
dir /b "%OUTDIR%"
echo.

:: Show file sizes
echo File sizes:
for %%f in ("%OUTDIR%\*.exe") do (
    for %%A in ("%%f") do echo   %%~nxf: %%~zA bytes
)
echo.

echo To create a ZIP archive, run:
echo   powershell Compress-Archive -Path "%OUTDIR%\*" -DestinationPath "dist\ssrWin-%PLATFORM%.zip"
echo.

endlocal
