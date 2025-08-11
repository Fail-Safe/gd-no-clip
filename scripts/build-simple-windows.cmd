@echo off
REM Ultra-simple build script for gd-no-clip (Release)
REM Tries to auto-configure MSVC environment if not already in a Developer Command Prompt.
REM If that fails, manually open: "x64 Native Tools Command Prompt for VS 2022" and run again.

setlocal
cd /d %~dp0\..

echo [INFO] Checking compiler availability...
where cl >nul 2>nul
if errorlevel 1 goto :try_bootstrap_msvc
goto :compiler_ready

:try_bootstrap_msvc
echo [INFO] cl.exe not on PATH. Attempting to locate Visual Studio via vswhere...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto :no_compiler

for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSVC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
if not defined VSINSTALL goto :no_compiler

REM Prefer vcvars64.bat (sets up 64-bit MSVC environment)
set "VSCMD=%VSINSTALL%\VC\Auxiliary\Build\vcvars64.bat"
if not exist "%VSCMD%" goto :no_compiler
echo [INFO] Calling Visual Studio environment script...
call "%VSCMD%" >nul 2>&1

where cl >nul 2>nul
if errorlevel 1 goto :no_compiler

:compiler_ready
echo [OK] C++ compiler available: cl.exe

where geode >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Geode CLI not found on PATH. Install with: cargo install geode-cli
  pause
  exit /b 1
)

set "GEODE_SDK=%CD%\.geode-sdk"
if not exist "%GEODE_SDK%" (
  echo [INFO] Installing Geode SDK clone...
  geode sdk install "%GEODE_SDK%"
  if errorlevel 1 goto :err
)
if not exist "%GEODE_SDK%\bin" (
  echo [INFO] Installing loader binaries (windows 4.7.0)...
  geode sdk install-binaries --platform windows -v 4.7.0
  if errorlevel 1 goto :err
)

echo [INFO] Cleaning old build directory...
if exist build rmdir /s /q build

echo [INFO] Building (Release)...
geode build --config Release
if errorlevel 1 goto :err

echo.
echo [OK] Build complete. Packaged file(s):
dir /b dist\*.geode 2>nul
echo.
pause
exit /b 0

:no_compiler
echo [ERROR] Unable to set up MSVC compiler automatically.
echo         1) Ensure Visual Studio (Desktop C++ workload) is installed.
echo         2) Open the "x64 Native Tools Command Prompt for VS 2022".
echo         3) Re-run this script from that prompt.
pause
exit /b 1

:err
echo [FAIL] Build failed (%errorlevel%). See messages above.
pause
exit /b %errorlevel%
