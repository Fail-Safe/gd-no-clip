@echo off
REM Ultra-simple build script for gd-no-clip (Release)
REM Paren-free version to avoid "... was unexpected" parsing issues.
REM If cl.exe is missing just open: "x64 Native Tools Command Prompt for VS 2022" and run again.

setlocal
cd /d %~dp0\..

echo [INFO] Checking for MSVC compiler (cl.exe)...
where cl >nul 2>nul || goto need_compiler
echo [OK] C++ compiler available.

echo [INFO] Checking for Geode CLI...
where geode >nul 2>nul || goto need_geode

set "GEODE_SDK=%CD%\.geode-sdk"
if not exist "%GEODE_SDK%" goto install_sdk
if not exist "%GEODE_SDK%\bin" goto install_bins
goto have_sdk

install_sdk:
echo [INFO] Installing Geode SDK clone...
geode sdk install "%GEODE_SDK%" || goto err
goto check_bins

check_bins:
if not exist "%GEODE_SDK%\bin" goto install_bins
goto have_sdk

install_bins:
echo [INFO] Installing loader binaries (windows 4.7.0)...
geode sdk install-binaries --platform windows -v 4.7.0 || goto err
goto have_sdk

have_sdk:
echo [INFO] Cleaning old build directory...
if exist build rmdir /s /q build

echo [INFO] Building (Release)...
geode build --config Release || goto err

echo.
echo [OK] Build complete. Packaged file(s):
dir /b dist\*.geode 2>nul
echo.
pause
exit /b 0

need_compiler:
echo [ERROR] cl.exe not found.
echo Open the "x64 Native Tools Command Prompt for VS 2022" then run this script.
pause
exit /b 1

need_geode:
echo [ERROR] Geode CLI not found. Install with: cargo install geode-cli
pause
exit /b 1

err:
echo [FAIL] Build failed (%errorlevel%). See messages above.
pause
exit /b %errorlevel%
