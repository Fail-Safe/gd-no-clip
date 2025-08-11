@echo off
REM Ultra-simple build script for gd-no-clip (Release)
REM Assumes you run it from a Developer Command Prompt for VS 2022 (so cl.exe is on PATH).
REM If it fails complaining about the compiler, open the "x64 Native Tools Command Prompt" and run again.

setlocal
cd /d %~dp0\..

echo [INFO] Checking compiler availability...
where cl >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cl.exe not found. Open a "x64 Native Tools Command Prompt for VS 2022" and re-run this script.
  pause
  exit /b 1
)

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

:err
echo [FAIL] Build failed (%errorlevel%). See messages above.
pause
exit /b %errorlevel%
