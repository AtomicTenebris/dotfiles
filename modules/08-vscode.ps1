Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure VS Code Insiders"


# Paths


$VSCodeUserDir = Join-Path `
    $env:APPDATA `
    "Code - Insiders\User"

$ConfigRoot = Join-Path `
    $Global:DotfilesRoot `
    "configs\vscode"


# Create Directories


New-Item `
    -ItemType Directory `
    -Path $VSCodeUserDir `
    -Force | Out-Null


# Backup Existing Configuration


$BackupDir = New-BackupDirectory "vscode"

Backup-Item `
    -Source (Join-Path $VSCodeUserDir "settings.json") `
    -Destination (Join-Path $BackupDir "settings.json")

Backup-Item `
    -Source (Join-Path $VSCodeUserDir "keybindings.json") `
    -Destination (Join-Path $BackupDir "keybindings.json")


# Deploy Settings


Copy-Dotfile `
    -Source (Join-Path $ConfigRoot "settings.json") `
    -Destination (Join-Path $VSCodeUserDir "settings.json")


# Deploy Keybindings


$KeybindingsSource = Join-Path `
    $ConfigRoot `
    "keybindings.json"

if (Test-Path $KeybindingsSource) {

    Copy-Dotfile `
        -Source $KeybindingsSource `
        -Destination (Join-Path $VSCodeUserDir "keybindings.json")
}


# Install Extensions


$CodeInsiders = Get-Command `
    "code-insiders" `
    -ErrorAction SilentlyContinue

if (-not $CodeInsiders) {

    Write-Host "[WARN] code-insiders CLI not found." `
        -ForegroundColor Yellow

    Write-Host "[WARN] Skipping extension installation."

    return
}

$ExtensionsFile = Join-Path `
    $ConfigRoot `
    "extensions.txt"

if (Test-Path $ExtensionsFile) {

    $InstalledExtensions = & $CodeInsiders.Source `
        --list-extensions

    $Extensions = Get-PackageList `
        -File $ExtensionsFile

    foreach ($Extension in $Extensions) {

        if ($Extension -in $InstalledExtensions) {

            Write-Host "[SKIP] $Extension already installed" `
                -ForegroundColor Cyan

            continue
        }

        Write-Host "[INSTALL] $Extension" `
            -ForegroundColor Yellow

        & $CodeInsiders.Source `
            --install-extension $Extension `
            --force
    }
}
else {

    Write-Host "[INFO] No extensions.txt found."
}


# Complete


Write-Host ""
Write-Host "[SUCCESS] VS Code Insiders configured" -ForegroundColor Green