#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$Branch = 'main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoOwner = 'AtomicTenebris'
$RepoName  = 'dotfiles'

$TempRoot = Join-Path `
    $env:TEMP `
    ("$RepoName-" + [guid]::NewGuid())

$ZipFile = "$TempRoot.zip"

try {
    Write-Host "Downloading dotfiles..." -ForegroundColor Cyan

    $ArchiveUrl = @(
        'https://github.com'
        $RepoOwner
        $RepoName
        'archive/refs/heads'
        "$Branch.zip"
    ) -join '/'

    Invoke-WebRequest `
        -Uri $ArchiveUrl `
        -OutFile $ZipFile

    Write-Host "Extracting archive..." -ForegroundColor Cyan

    Expand-Archive `
        -Path $ZipFile `
        -DestinationPath $TempRoot `
        -Force

    $RepoRoot = Get-ChildItem `
        -Path $TempRoot `
        -Directory |
        Select-Object -First 1

    if (-not $RepoRoot) {
        throw "Failed to locate extracted repository."
    }

    $InstallScript = Join-Path `
        $RepoRoot.FullName `
        'install.ps1'

    if (-not (Test-Path $InstallScript)) {
        throw "install.ps1 not found."
    }

    Write-Host "Launching installer..." -ForegroundColor Green

    Push-Location $RepoRoot.FullName

    try {
        & $InstallScript
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item `
        $ZipFile `
        -Force `
        -ErrorAction SilentlyContinue

    Remove-Item `
        $TempRoot `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}
