Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:POWERSHELLGET_SKIP_NOISE = "true"
$env:PSDisableModuleAnalysisCacheCleanup = "1"

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

Write-ModuleHeader "NuGet Check"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Step 1: Force install NuGet provider without PowerShellGet fallback
$nugetPath = "$env:LOCALAPPDATA\PackageManagement\ProviderAssemblies\NuGet\2.8.5.201"

if (-not (Test-Path $nugetPath)) {

    Write-Host "[INFO] Installing NuGet provider (forced mode)..." -ForegroundColor Yellow

    $provider = Install-PackageProvider `
        -Name NuGet `
        -MinimumVersion 2.8.5.201 `
        -Force `
        -Scope CurrentUser `
        -Confirm:$false `
        -ErrorAction Stop

    Import-PackageProvider -Name NuGet -Force | Out-Null
}

# Step 2: Preload into session (IMPORTANT)
Import-PackageProvider NuGet -Force -ErrorAction SilentlyContinue

# Step 3: Stop PSGallery from triggering bootstrap prompt
Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

Write-Host "[OK] NuGet fully bootstrapped (no interactive fallback possible)" -ForegroundColor Green

Write-Host "Prerequisites checks completed" -ForegroundColor Green
