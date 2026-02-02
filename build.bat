@echo off
setlocal enabledelayedexpansion

:: SSRWin Build Script
:: Builds the ShadowsocksR for Windows application
:: Requires Visual Studio 2019 or 2022 with C++ build tools

echo ============================================
echo   SSRWin Build Script
echo ============================================
echo.

:: Default configuration
set CONFIG=Release
set PLATFORM=x64

:: Parse command line arguments
:parse_args
if "%~1"=="" goto :find_msbuild
if /i "%~1"=="debug" set CONFIG=Debug
if /i "%~1"=="release" set CONFIG=Release
if /i "%~1"=="x86" set PLATFORM=Win32
if /i "%~1"=="x64" set PLATFORM=x64
if /i "%~1"=="win32" set PLATFORM=Win32
shift
goto :parse_args

:find_msbuild
echo [1/4] Finding MSBuild...

:: Try Visual Studio 2022
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
        set "MSBUILD=%%i"
    )
)

:: Fallback: Try common VS paths
if not defined MSBUILD (
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
        set "MSBUILD=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    )
)
if not defined MSBUILD (
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
        set "MSBUILD=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    )
)
if not defined MSBUILD (
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
        set "MSBUILD=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    )
)
if not defined MSBUILD (
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
        set "MSBUILD=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
    )
)

if not defined MSBUILD (
    echo ERROR: MSBuild not found. Please install Visual Studio 2019 or 2022 with C++ build tools.
    echo.
    echo You can download Visual Studio from:
    echo   https://visualstudio.microsoft.com/downloads/
    echo.
    echo Make sure to select "Desktop development with C++" workload during installation.
    exit /b 1
)

echo   Found: %MSBUILD%
echo.

:: Check if submodules are initialized
echo [2/4] Checking submodules...
if not exist "depends\ssr-native\src" (
    echo   Initializing git submodules...
    git submodule update --init --recursive
    if errorlevel 1 (
        echo ERROR: Failed to initialize submodules.
        exit /b 1
    )
) else (
    echo   Submodules already initialized.
)
echo.

:: Build the solution
echo [3/4] Building %CONFIG%^|%PLATFORM%...
echo.

"%MSBUILD%" "src\ssrWin.sln" /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /m /verbosity:minimal

if errorlevel 1 (
    echo.
    echo ============================================
    echo   BUILD FAILED
    echo ============================================
    exit /b 1
)

echo.
echo [4/4] Build completed successfully!
echo.

:: Show output location
if "%PLATFORM%"=="x64" (
    set "OUTDIR=src\x64\%CONFIG%"
) else (
    set "OUTDIR=src\%CONFIG%"
)

echo ============================================
echo   BUILD SUCCESSFUL
echo ============================================
echo.
echo Output directory: %OUTDIR%
echo.
echo Executable: %OUTDIR%\ssrWin.exe
echo.

if exist "%OUTDIR%\ssrWin.exe" (
    echo File size:
    for %%A in ("%OUTDIR%\ssrWin.exe") do echo   %%~zA bytes
)

echo.
echo Usage:
echo   build.bat [debug^|release] [x86^|x64]
echo.
echo Examples:
echo   build.bat              - Build Release x64
echo   build.bat debug        - Build Debug x64
echo   build.bat release x86  - Build Release x86
echo.

endlocal
