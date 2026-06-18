Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Windows Terminal"

# -----------------------------------------------------------------------------
# Verify Windows Terminal
# -----------------------------------------------------------------------------

if (-not (Test-CommandExists "wt")) {
    throw "Windows Terminal is not installed."
}

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$TerminalSettings = Join-Path `
    $env:LOCALAPPDATA `
    "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$ConfigFile = Join-Path `
    $Global:DotfilesRoot `
    "configs\windows-terminal\settings.json"

# -----------------------------------------------------------------------------
# Verify Existing Configuration
# -----------------------------------------------------------------------------

if (-not (Test-Path $TerminalSettings)) {

    Write-Host "[INFO] Windows Terminal settings not found." `
        -ForegroundColor Yellow

    Write-Host "[INFO] Launch Windows Terminal once and rerun the installer."

    return
}

# -----------------------------------------------------------------------------
# Backup Existing Configuration
# -----------------------------------------------------------------------------

$BackupDir = New-BackupDirectory "terminal"

Backup-Item `
    -Source $TerminalSettings `
    -Destination (Join-Path $BackupDir "settings.json")

# -----------------------------------------------------------------------------
# Deploy Configuration
# -----------------------------------------------------------------------------

Copy-Dotfile `
    -Source $ConfigFile `
    -Destination $TerminalSettings

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "[SUCCESS] Windows Terminal configured" `
    -ForegroundColor Green