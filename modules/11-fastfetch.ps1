Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Fastfetch"

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$FastfetchConfigDir = Join-Path `
    $HOME `
    ".config\fastfetch"

$SourceConfigDir = Join-Path `
    $Global:DotfilesRoot `
    "configs\fastfetch"

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

$BackupDir = New-BackupDirectory "fastfetch"

Backup-Item `
    -Source $FastfetchConfigDir `
    -Destination (Join-Path $BackupDir "fastfetch")

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

New-Item `
    -ItemType Directory `
    -Path $FastfetchConfigDir `
    -Force | Out-Null

Copy-Dotfile `
    -Source $SourceConfigDir `
    -Destination $FastfetchConfigDir

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] Fastfetch configured" -ForegroundColor Green
