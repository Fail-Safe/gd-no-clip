@echo off
REM Windows Release build script for gd-no-clip (robust version)
setlocal
cd /d %~dp0\..

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

echo [INFO] Cleaning previous build directory...
if exist build rmdir /s /q build

echo [INFO] Building (Release)...
geode build --config Release
if errorlevel 1 goto :err

echo.
echo [OK] Build complete. Package(s) in dist\
dir /b dist\*.geode 2>nul
exit /b 0

:err
echo [FAIL] Build failed (%errorlevel%)
exit /b %errorlevel%
