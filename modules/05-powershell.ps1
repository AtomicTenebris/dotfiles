Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Powershell"

$PowerShellConfigDir = Join-Path $HOME ".config\powershell"

if (-not (Test-Path $PowerShellConfigDir)) {
  New-Item `
    -ItemType Directory `
    -Path $PowerShellConfigDir `
    -Force | Out-Null
}

$BackupDir = New-BackupDirectory "powershell"

Backup-Item `
    -Source $PROFILE.CurrentUserAllHosts `
    -Destination (Join-Path $BackupDir "Microsoft.PowerShell_profile.ps1")

Backup-Item `
    -Source (Join-Path $HOME ".config\powershell\user_profile.ps1") `
    -Destination (Join-Path $BackupDir "user_profile.ps1")
   
# Deploy profile bootstrap
Copy-Item `
  -Path (Join-Path $Global:DotfilesRoot "configs\powershell\Microsoft.PowerShell_profile.ps1") `
  -Destination $PROFILE.CurrentUserAllHosts `
  -Force

# Deploy User Profile
Copy-Item `
  -Path (Join-Path $Global:DotfilesRoot "configs\powershell\user_profile.ps1") `
  -Destination (Join-Path $PowerShellConfigDir "user_profile.ps1") `
  -Force

$ModuleFile = Join-Path `
  $Global:DotfilesRoot `
  "configs\powershell\modules.txt"

$Modules = Get-Content $ModuleFile |
Where-Object {
  $_.Trim() -and -not $_.StartsWith('#')
}

foreach ($Module in $Modules) {
  if (-not (Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue)) {

    Write-Host "[INSTALL] $Module" -ForegroundColor Yellow

    Install-Module `
      -Name $Module `
      -Scope CurrentUser `
      -Force `
      -AllowClobber
  }
  else {

    Write-Host "[UPDATE] $Module" -ForegroundColor Cyan

    Update-Module `
      -Name $Module `
      -Force `
      -ErrorAction SilentlyContinue
  }
}

Write-Host "[SUCCESS] Powershell Configured..." -ForegroundColor Green