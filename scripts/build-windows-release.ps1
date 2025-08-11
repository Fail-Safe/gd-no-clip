<#!
Windows Release build script for gd-no-clip
Usage:
  pwsh -File scripts/build-windows-release.ps1
!>
$ErrorActionPreference = "Stop"

Write-Host "[INFO] Ensuring Geode SDK clone (.geode-sdk)..." -ForegroundColor Cyan
if (-not (Test-Path ".geode-sdk")) {
  geode sdk install ".geode-sdk"
}

$env:GEODE_SDK = (Join-Path (Get-Location) ".geode-sdk")

if (-not (Test-Path "$env:GEODE_SDK/bin") -or -not (Get-ChildItem "$env:GEODE_SDK/bin" -Filter "*geode*" -ErrorAction SilentlyContinue)) {
  Write-Host "[INFO] Installing loader binaries..." -ForegroundColor Cyan
  geode sdk install-binaries --platform windows -v 4.7.0
}

if (Test-Path build) {
  Write-Host "[INFO] Removing existing build directory..." -ForegroundColor DarkGray
  Remove-Item build -Recurse -Force
}

Write-Host "[INFO] Building (Release)..." -ForegroundColor Cyan
geode build --config Release

Write-Host "`n[OK] Build complete. Packages:" -ForegroundColor Green
Get-ChildItem dist -Filter *.geode -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
