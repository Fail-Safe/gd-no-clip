@echo off
REM Simple one-click build script for gd-no-clip (Release)
REM Locates Visual Studio, sets env, ensures Geode SDK + binaries, builds & packages.

setlocal
cd /d %~dp0\..

echo [INFO] Locating Visual Studio installation...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo [ERROR] vswhere.exe not found. Install Visual Studio 2022 (C++ workload) first.
  pause & exit /b 1
)
for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do set "VS_PATH=%%I"
if not defined VS_PATH (
  echo [ERROR] Could not find a Visual Studio installation with C++ tools.
  pause & exit /b 1
)
echo [INFO] VS path: %VS_PATH%

echo [INFO] Setting up MSVC environment...
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 (
  echo [ERROR] Failed to initialize MSVC environment.
  pause & exit /b 1
)

where geode >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Geode CLI not found on PATH. Install with: cargo install geode-cli
  pause & exit /b 1
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

:err
echo [FAIL] Build failed (%errorlevel%). See messages above.
pause
exit /b %errorlevel%
