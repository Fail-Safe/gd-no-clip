@echo off
setlocal EnableDelayedExpansion
REM Windows Debug build script for gd-no-clip
REM Usage: scripts\build-windows-debug.bat

if not exist ".geode-sdk" (
  echo [INFO] Installing Geode SDK clone (.geode-sdk)...
  geode sdk install ".geode-sdk" || goto :err
)

set "GEODE_SDK=%CD%\.geode-sdk"

if not exist "%GEODE_SDK%\bin" (
  echo [INFO] Installing pre-built loader binaries...
  geode sdk install-binaries --platform windows -v 4.7.0 || goto :err
) else (
  dir /b "%GEODE_SDK%\bin" | findstr /i "geode" >NUL || (
    echo [INFO] Loader binaries not found, installing...
    geode sdk install-binaries --platform windows -v 4.7.0 || goto :err
  )
)

echo [INFO] Cleaning previous debug build (optional)...
if exist build rmdir /s /q build

echo [INFO] Building (Debug)...
geode build --config Debug || goto :err

echo.
echo [OK] Debug build complete. Package(s) in dist\ (names may include debug suffix)
dir /b dist\*.geode 2>nul
exit /b 0

:err
echo [FAIL] Build failed (%errorlevel%)
exit /b %errorlevel%
