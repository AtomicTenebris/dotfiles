param (
    [string[]]$Modules
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = [Security.Principal.WindowsPrincipal]::new(
        $Identity
    )

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# -----------------------------------------------------------------------------
# Elevation
# -----------------------------------------------------------------------------

if (-not (Test-IsAdmin)) {

    Write-Host "Requesting Administrator privileges..."

    $Shell = (Get-Process -Id $PID).Path

    $Arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        "`"$PSCommandPath`""
    )

    if ($Modules) {

        $Arguments += '-Modules'
        $Arguments += ($Modules -join ',')
    }

    Start-Process `
        -FilePath $Shell `
        -Verb RunAs `
        -WorkingDirectory (Get-Location) `
        -ArgumentList $Arguments

    exit
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

$CommonHelpers = Join-Path `
    $PSScriptRoot `
    "helpers\common.ps1"

if (-not (Test-Path $CommonHelpers)) {
    throw "helpers\common.ps1 not found."
}

. $CommonHelpers

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

$Global:DotfilesRoot = $PSScriptRoot

$ModulePath = Join-Path `
    $DotfilesRoot `
    "modules"

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------

Write-Host ""

Write-Host "========================================"

Write-Host `
    "Dotfiles Installer" `
    -ForegroundColor Yellow

Write-Host `
    "PowerShell $($PSVersionTable.PSVersion)" `
    -ForegroundColor Cyan

Write-Host `
    "Running as Administrator" `
    -ForegroundColor Green

Write-Host "========================================"

Write-Host ""

# -----------------------------------------------------------------------------
# Discover Modules
# -----------------------------------------------------------------------------

$ModuleFiles = Get-ChildItem `
    -Path $ModulePath `
    -Filter "*.ps1" `
    -File |
    Sort-Object Name

# -----------------------------------------------------------------------------
# Filter Requested Modules
# -----------------------------------------------------------------------------

if ($Modules) {

    $RequestedModules = $Modules |
        ForEach-Object {
            $_.ToLower().Trim()
        }

    $ModuleFiles = $ModuleFiles |
        Where-Object {

            $ModuleName = (
                $_.BaseName `
                    -replace '^\d+[-_]?',''
            ).ToLower()

            $ModuleName -in $RequestedModules
        }

    if (-not $ModuleFiles) {

        throw "No matching modules found."
    }
}

# -----------------------------------------------------------------------------
# Execute Modules
# -----------------------------------------------------------------------------

foreach ($Module in $ModuleFiles) {

    Write-ModuleHeader `
        "Running: $($Module.Name)"

    try {

        & $Module.FullName

        Write-Host `
            "[SUCCESS] $($Module.Name)" `
            -ForegroundColor Green
    }
    catch {

        Write-Host `
            "[FAILED] $($Module.Name)" `
            -ForegroundColor Red

        throw
    }
}

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-ModuleHeader `
    "Installation Complete"

Start-Sleep -Seconds 5

Restart-Computer -Force
