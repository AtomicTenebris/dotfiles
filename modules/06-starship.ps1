Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Starship"

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$StarshipConfigDir = Join-Path `
    $HOME `
    ".config"

$StarshipConfig = Join-Path `
    $StarshipConfigDir `
    "starship.toml"

$SourceConfig = Join-Path `
    $Global:DotfilesRoot `
    "configs\starship\starship.toml"

# -----------------------------------------------------------------------------
# Create Directory
# -----------------------------------------------------------------------------

New-Item `
    -ItemType Directory `
    -Path $StarshipConfigDir `
    -Force | Out-Null

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

$BackupDir = New-BackupDirectory "starship"

Backup-Item `
    -Source $StarshipConfig `
    -Destination (Join-Path $BackupDir "starship.toml")

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

Copy-Dotfile `
    -Source $SourceConfig `
    -Destination $StarshipConfig

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] Starship configured" -ForegroundColor Green