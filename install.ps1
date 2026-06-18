param (
  [string[]]$Modules
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


function Test-IsAdmin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)

  return $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

if (-not (Test-IsAdmin)) {

  Write-Host "Requesting Administrator privileges..."

  $shell = (Get-Process -Id $PID).Path

  $Arguments = @(
    '-NoExit',
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$PSCommandPath`""
  )

  Start-Process `
    -FilePath $shell `
    -Verb RunAs `
    -WorkingDirectory (Get-Location) `
    -ArgumentList ($Arguments + $args)
  
  exit
}

$CommonHelpers = Join-Path `
    $PSScriptRoot `
    "helpers\common.ps1"

if (-not (Test-Path $CommonHelpers)) {
    throw "helpers\common.ps1 not found."
}

. $CommonHelpers

$Global:DotfilesRoot = $PSScriptRoot
$ModulePath = Join-Path $DotfilesRoot 'modules'


Write-Host ""
Write-Host "========================================"
Write-Host "Dotfiles Installer" -ForegroundColor Yellow
Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Red
Write-Host "Running as Administrator" -ForegroundColor Green
Write-Host "========================================"
Write-Host ""


$ModuleFiles = Get-ChildItem `
  -Path $ModulePath `
  -Filter '*.ps1' `
  -File | 
Sort-Object Name

if ($Modules) {

  $RequestedModules = $Modules | ForEach-Object {
    $_.ToLower().Trim()
  }

  $ModuleFiles = $ModuleFiles | Where-Object {

    $ModuleName = (
      $_.BaseName `
        -replace '^\d+[-_]?', ''
    ).ToLower()

    $ModuleName -in $RequestedModules
  }

  if (-not $ModuleFiles) {
    throw "No matching modules found."
  }
}


# Executing the files
foreach ($Module in $ModuleFiles) {



  Write-ModuleHeader "Running: $($Module.Name)"

  try {
    & $Module.FullName

    Write-Host "[SUCCESS] $($Module.Name)"
  }
  catch {
    Write-Host "[FAILED] $($Module.Name)"
    throw
  }
}


Write-ModuleHeader "Installation Complete"
Start-Sleep -Seconds 15
Restart-Computer -Force
