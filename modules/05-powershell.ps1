Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure PowerShell"

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
$ConfigRoot  = Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

# -------------------------------------------------
# Ensure directories exist
# -------------------------------------------------

foreach ($Dir in @($PwshDir, $LegacyDir, $ConfigRoot)) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
}

# -------------------------------------------------
# Ensure user profile exists
# -------------------------------------------------

if (-not (Test-Path $UserProfile)) {
    New-Item -ItemType File -Path $UserProfile -Force | Out-Null
}

# -------------------------------------------------
# Backup existing profiles
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
# Bootstrap loader
# -------------------------------------------------

$Bootstrap = @'
$ConfigRoot = Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

if (Test-Path $UserProfile) {
    try {
        . $UserProfile
    }
    catch {
        Write-Host "[WARN] Failed to load user_profile.ps1" -ForegroundColor Yellow
        Write-Host $_ -ForegroundColor DarkYellow
    }
}
'@

Set-Content -Path $PwshProfile -Value $Bootstrap -Encoding UTF8 -Force
Set-Content -Path $LegacyProfile -Value $Bootstrap -Encoding UTF8 -Force

# -------------------------------------------------
# Deploy user profile
# -------------------------------------------------

$SourceProfile = Join-Path $Global:DotfilesRoot "configs\powershell\user_profile.ps1"

if (-not (Test-Path $SourceProfile)) {
    throw "PowerShell profile not found: $SourceProfile"
}

Copy-Item `
    -Path $SourceProfile `
    -Destination $UserProfile `
    -Force

Write-Host "[SUCCESS] PowerShell configured successfully." -ForegroundColor Green
Write-Host "Bootstrap profiles created:" -ForegroundColor DarkGray
Write-Host "  • $PwshProfile" -ForegroundColor DarkGray
Write-Host "  • $LegacyProfile" -ForegroundColor DarkGray
Write-Host "User profile deployed to:" -ForegroundColor DarkGray
Write-Host "  • $UserProfile" -ForegroundColor DarkGray
