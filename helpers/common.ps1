Set-StrictMode -Version Latest

function Write-ModuleHeader {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "========================================"
    Write-Host ""
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    return [bool](Get-Command `
        $Command `
        -ErrorAction SilentlyContinue)
}

function New-BackupDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Category
    )

    $BackupRoot = Join-Path `
        $HOME `
        ".config\backups"

    $BackupDir = Join-Path `
        $BackupRoot `
        (Join-Path `
            (Get-Date -Format "yyyy-MM-dd") `
            $Category)

    New-Item `
        -ItemType Directory `
        -Path $BackupDir `
        -Force | Out-Null

    return $BackupDir
}

function Backup-Item {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        return
    }

    Copy-Item `
        -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force

    Write-Host "[SUCCESS] Backed up: $Source" `
        -ForegroundColor Green
}

function Copy-Dotfile {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "Source does not exist: $Source"
    }

    $Parent = Split-Path `
        $Destination `
        -Parent

    New-Item `
        -ItemType Directory `
        -Path $Parent `
        -Force | Out-Null

    Copy-Item `
        -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force

    Write-Host "[SUCCESS] Deployed: $Destination" `
        -ForegroundColor Green
}

function Get-PackageList {
    param(
        [Parameter(Mandatory)]
        [string]$File
    )

    if (-not (Test-Path $File)) {
        throw "Package file not found: $File"
    }

    return Get-Content $File |
        Where-Object {
            $_.Trim() -and
            -not $_.Trim().StartsWith('#')
        }
}