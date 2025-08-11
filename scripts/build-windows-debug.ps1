<#!
Windows Debug build script for gd-no-clip
Usage:
  pwsh -File scripts/build-windows-debug.ps1
!>
$ErrorActionPreference = "Stop"

Write-Host "[INFO] Ensuring Geode SDK clone (.geode-sdk) for debug build..." -ForegroundColor Cyan
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

Write-Host "[INFO] Building (Debug)..." -ForegroundColor Cyan
geode build --config Debug

Write-Host "`n[OK] Debug build complete. Packages:" -ForegroundColor Green
Get-ChildItem dist -Filter *.geode -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
