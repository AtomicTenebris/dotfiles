Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Neovim"

# -----------------------------------------------------------------------------
# Verify Neovim
# -----------------------------------------------------------------------------

if (-not (Test-CommandExists "nvim")) {
    throw "Neovim is not installed or not available in PATH."
}

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$Source = Join-Path `
    $Global:DotfilesRoot `
    "configs\nvim"

$Destination = Join-Path `
    $env:LOCALAPPDATA `
    "nvim"

# -----------------------------------------------------------------------------
# Validate Source
# -----------------------------------------------------------------------------

if (-not (Test-Path $Source)) {
    throw "Neovim configuration directory not found: $Source"
}

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

$BackupDir = New-BackupDirectory "nvim"

Backup-Item `
    -Source $Destination `
    -Destination (Join-Path $BackupDir "nvim")

# -----------------------------------------------------------------------------
# Create Configuration Directory
# -----------------------------------------------------------------------------

New-Item `
    -ItemType Directory `
    -Path $Destination `
    -Force | Out-Null

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

Copy-Item `
    -Path "$Source\*" `
    -Destination $Destination `
    -Recurse `
    -Force

Write-Host "[SUCCESS] Neovim configuration deployed" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] Neovim configured" `
    -ForegroundColor Green

Write-Host "[INFO] Launch Neovim to bootstrap plugins." -ForegroundColor Yellow
