Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Powershell"

# -------------------------------------------------
# Paths
# -------------------------------------------------

$Documents = [Environment]::GetFolderPath("MyDocuments")

# Bootstrap locations (Documents)
$PwshDir   = Join-Path $Documents "PowerShell"
$LegacyDir = Join-Path $Documents "WindowsPowerShell"

$PwshProfile   = Join-Path $PwshDir "Microsoft.PowerShell_profile.ps1"
$LegacyProfile = Join-Path $LegacyDir "profile.ps1"

# Source of truth (user config)
$ConfigRoot     = Join-Path $HOME ".config\powershell"
$UserProfile    = Join-Path $ConfigRoot "user_profile.ps1"

# -------------------------------------------------
# Ensure directories exist (CRITICAL FIX)
# -------------------------------------------------

foreach ($dir in @($PwshDir, $LegacyDir, $ConfigRoot)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# -------------------------------------------------
# Ensure user profile exists
# -------------------------------------------------

if (-not (Test-Path $UserProfile)) {
    New-Item -ItemType File -Path $UserProfile -Force | Out-Null
}

# -------------------------------------------------
# Backup existing files (safe)
# -------------------------------------------------

$BackupDir = New-BackupDirectory "powershell"

if (Test-Path $PwshProfile) {
    Backup-Item `
        -Source $PwshProfile `
        -Destination (Join-Path $BackupDir "Microsoft.PowerShell_profile.ps1")
}

if (Test-Path $LegacyProfile) {
    Backup-Item `
        -Source $LegacyProfile `
        -Destination (Join-Path $BackupDir "WindowsPowerShell_profile.ps1")
}

# -------------------------------------------------
# Deploy bootstrap loader (same for both shells)
# -------------------------------------------------

$Bootstrap = @'
$ConfigRoot = Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

if (Test-Path $UserProfile) {
    try {
        . $UserProfile
    }
    catch {
        Write-Host "[WARN] Failed to load user_profile.ps1: $_" -ForegroundColor Yellow
    }
}
'@

Set-Content -Path $PwshProfile -Value $Bootstrap -Force
Set-Content -Path $LegacyProfile -Value $Bootstrap -Force

# -------------------------------------------------
# Ensure user profile is deployed
# -------------------------------------------------

Copy-Item `
    -Path (Join-Path $Global:DotfilesRoot "configs\powershell\user_profile.ps1") `
    -Destination $UserProfile `
    -Force

# -------------------------------------------------
# Install / update modules
# -------------------------------------------------

$ModuleFile = Join-Path $Global:DotfilesRoot "configs\powershell\modules.txt"

$Modules = Get-Content $ModuleFile | Where-Object {
    $_.Trim() -and -not $_.StartsWith('#')
}

foreach ($Module in $Modules) {

    if (-not (Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue)) {

        Write-Host "[INSTALL] $Module" -ForegroundColor Yellow

Install-Module `
    -Name $Module `
    -Scope CurrentUser `
    -Force `
    -AllowClobber `
    -Confirm:$false `
    -SkipPublisherCheck `
    -ErrorAction Stop
    }
    else {

        Write-Host "[UPDATE] $Module" -ForegroundColor Cyan

        Update-Module `
            -Name $Module `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

Write-Host "[SUCCESS] PowerShell configured (pwsh + WindowsPowerShell)" -ForegroundColor Green
