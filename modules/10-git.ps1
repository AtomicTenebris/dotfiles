Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Git"


# Verify Git


if (-not (Test-CommandExists "git")) {
    throw "Git is not installed."
}


# Paths


$GitConfig = Join-Path `
    $HOME `
    ".gitconfig"

$SourceConfig = Join-Path `
    $Global:DotfilesRoot `
    "configs\git\.gitconfig"


# Backup Existing Configuration


$BackupDir = New-BackupDirectory "git"

Backup-Item `
    -Source $GitConfig `
    -Destination (Join-Path $BackupDir ".gitconfig")


# Deploy Configuration


Copy-Dotfile `
    -Source $SourceConfig `
    -Destination $GitConfig


# Complete


Write-Host ""
Write-Host "[SUCCESS] Git configured" -ForegroundColor Green