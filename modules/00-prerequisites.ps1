Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Checking Prerequisites" -ForegroundColor Yellow
Write-ModuleHeader "Checking Internet Connectivity"

try {
  $null = Invoke-WebRequest `
    -Uri "https://microsoft.com" `
    -Method Head `
    -TimeoutSec 10 -UseBasicParsing
  Write-Host "[SUCCESS] Internet Connectivity" -ForegroundColor Green
}
catch {
  throw "Internet Connection is required"
}

Write-ModuleHeader "Verify Winget"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {

  Write-Host "[INFO] WinGet not detected. Installing..." -ForegroundColor Yellow

  $WingetBundle = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"

  Invoke-WebRequest `
    -Uri "https://aka.ms/getwinget" `
    -OutFile $WingetBundle

  Add-AppxPackage $WingetBundle

  Remove-Item $WingetBundle -Force

  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "WinGet installation failed."
  }

  Write-Host "[SUCCESS] WinGet installed" -ForegroundColor Green
}
else {
  Write-Host "[SUCCESS] WinGet detected" -ForegroundColor Green
}

Write-ModuleHeader "Verify Windows Version"

$WindowsVersion = [System.Environment]::OSVersion.Version

if ($WindowsVersion.Major -lt 10) {
  throw "Windows 10 or newer is required."
}
Write-Host "[SUCCESS] Windows version '$($WindowsVersion)' supported" -ForegroundColor Green

Write-ModuleHeader "Create Common Directories"

$Directories = @(
  "$HOME\.config",
  "$HOME\Documents\PowerShell",
  "$HOME\Documents\WindowsPowerShell",
  "$HOME\workspace"
)
foreach ($Directory in $Directories) {
  if (-not (Test-Path $Directory)) {
    New-Item `
      -ItemType Directory `
      -Path $Directory `
      -Force | Out-Null

    Write-Host "[CREATED] $Directory" -ForegroundColor Green
  }

}

Write-ModuleHeader "Refresh PATH"

$env:Path = [System.Environment]::GetEnvironmentVariable(
  'Path',
  'Machine'
) + ';' + [System.Environment]::GetEnvironmentVariable(
  'Path',
  'User'
)

Write-Host "[SUUCESS] PATH refreshed" -ForegroundColor Green

Write-ModuleHeader "Configure NuGet + PowerShellGet (Fully Silent)"

# Force TLS 1.2 (required for PSGallery bootstrap)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -----------------------------
# STEP 1: Pre-register PSGallery WITHOUT triggers
# -----------------------------

if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository `
        -Default `
        -InstallationPolicy Trusted `
        -ErrorAction SilentlyContinue | Out-Null
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# -----------------------------
# STEP 2: Pre-install NuGet provider (CRITICAL FIX)
# -----------------------------

$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue

if (-not $nuget) {

    Write-Host "[INFO] Preloading NuGet provider..." -ForegroundColor Yellow

    # This forces download WITHOUT PowerShellGet triggering interactive fallback
    Install-PackageProvider `
        -Name NuGet `
        -MinimumVersion 2.8.5.208 `
        -Force `
        -Scope CurrentUser `
        -Confirm:$false `
        -ForceBootstrap `
        -ErrorAction Stop | Out-Null

    Write-Host "[SUCCESS] NuGet provider installed" -ForegroundColor Green
}
else {
    Write-Host "[SUCCESS] NuGet already available" -ForegroundColor Green
}

# -----------------------------
# STEP 3: Pre-warm PowerShellGet (prevents lazy prompt later)
# -----------------------------

Import-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue

Write-Host "Prerequisites checks completed" -ForegroundColor Green
