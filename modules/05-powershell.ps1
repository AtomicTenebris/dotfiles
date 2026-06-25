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
# Backup existing files
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
# Deploy bootstrap loader
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
# Deploy user profile
# -------------------------------------------------

Copy-Item `
    -Path (Join-Path $Global:DotfilesRoot "configs\powershell\user_profile.ps1") `
    -Destination $UserProfile `
    -Force

# -------------------------------------------------
# Install PowerShell modules using pwsh
# -------------------------------------------------

$ModuleFile = Join-Path $Global:DotfilesRoot "configs\powershell\modules.txt"

if (-not (Test-Path $ModuleFile)) {
    throw "Module list not found: $ModuleFile"
}

$Modules = Get-Content $ModuleFile | Where-Object {
    $_.Trim() -and -not $_.StartsWith('#')
}

$Pwsh = Get-Command pwsh -ErrorAction SilentlyContinue

if (-not $Pwsh) {
    throw "PowerShell 7 (pwsh) is not installed."
}

foreach ($Module in $Modules) {

    Write-Host "[CHECK] $Module" -ForegroundColor Cyan

    $CheckScript = @"
if (Get-Module -ListAvailable -Name '$Module') {
    'true'
}
"@

    $CheckEncoded = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes($CheckScript)
    )

    $Installed = & $Pwsh.Source `
        -NoProfile `
        -NonInteractive `
        -EncodedCommand $CheckEncoded

    if ($Installed -eq 'true') {
        Write-Host "[SKIP] $Module already installed" -ForegroundColor DarkGray
        continue
    }

    Write-Host "[INSTALL] $Module" -ForegroundColor Yellow

    $InstallScript = @"
`$ErrorActionPreference = 'Stop'

Install-Module `
    -Name '$Module' `
    -Scope CurrentUser `
    -Repository PSGallery `
    -Force `
    -AllowClobber `
    -SkipPublisherCheck `
    -Confirm:`$false
"@

    $InstallEncoded = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes($InstallScript)
    )

    & $Pwsh.Source `
        -NoProfile `
        -NonInteractive `
        -EncodedCommand $InstallEncoded

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install module: $Module"
    }

    Write-Host "[DONE] $Module" -ForegroundColor Green
}

Write-Host "[SUCCESS] PowerShell configured (pwsh + WindowsPowerShell)" -ForegroundColor Green