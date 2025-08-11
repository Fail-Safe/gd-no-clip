<#
Ultra-simple PowerShell build script for gd-no-clip (Release)
Run in a Developer PowerShell for VS 2022 (or normal PowerShell if cl.exe already available).
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot
Write-Host "[INFO] Repo root: $repoRoot"

# Check compiler
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
  Write-Host "[ERROR] cl.exe not found. Open 'Developer PowerShell for VS 2022' and run again." -ForegroundColor Red
  pause
  exit 1
}
Write-Host "[OK] C++ compiler available." -ForegroundColor Green

# Check geode
if (-not (Get-Command geode -ErrorAction SilentlyContinue)) {
  Write-Host "[ERROR] Geode CLI not found. Install with: cargo install geode-cli" -ForegroundColor Red
  pause
  exit 1
}

$env:GEODE_SDK = Join-Path $repoRoot '.geode-sdk'
if (-not (Test-Path $env:GEODE_SDK)) {
  Write-Host "[INFO] Installing Geode SDK clone..."
  geode sdk install $env:GEODE_SDK
}
if (-not (Test-Path (Join-Path $env:GEODE_SDK 'bin'))) {
  Write-Host "[INFO] Installing loader binaries (windows 4.7.0)..."
  geode sdk install-binaries --platform windows -v 4.7.0
}

if (Test-Path 'build') {
  Write-Host "[INFO] Removing old build directory..."
  Remove-Item -Recurse -Force 'build'
}

Write-Host "[INFO] Building (Release)..."
if (-not (geode build --config Release)) {
  Write-Host "[FAIL] Build failed." -ForegroundColor Red
  pause
  exit 1
}

Write-Host "`n[OK] Build complete. Packaged file(s):" -ForegroundColor Green
Get-ChildItem -ErrorAction SilentlyContinue -Path dist -Filter *.geode | ForEach-Object { $_.Name }
Write-Host ""
# Keep window open if double-clicked
pause
