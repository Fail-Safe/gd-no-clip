@echo off
setlocal EnableDelayedExpansion
REM Windows Release build script for gd-no-clip
REM Usage: scripts\build-windows-release.bat

if not exist ".geode-sdk" (
  echo [INFO] Installing Geode SDK clone (.geode-sdk)...
  geode sdk install ".geode-sdk" || goto :err
)

set "GEODE_SDK=%CD%\.geode-sdk"

REM Install binaries only if missing loader (geode*.dll)
if not exist "%GEODE_SDK%\bin" (
  echo [INFO] Installing pre-built loader binaries...
  geode sdk install-binaries --platform windows -v 4.7.0 || goto :err
) else (
  dir /b "%GEODE_SDK%\bin" | findstr /i "geode" >NUL || (
    echo [INFO] Loader binaries not found, installing...
    geode sdk install-binaries --platform windows -v 4.7.0 || goto :err
  )
)

echo [INFO] Cleaning previous build (optional)...
if exist build rmdir /s /q build

echo [INFO] Building (Release)...
geode build --config Release || goto :err

echo.
echo [OK] Build complete. Package(s) in dist\
dir /b dist\*.geode 2>nul
exit /b 0

:err
echo [FAIL] Build failed (%errorlevel%)
exit /b %errorlevel%
