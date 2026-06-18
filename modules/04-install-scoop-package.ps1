Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Scoop Packages"

$PackageFile = Join-Path `
    $Global:DotfilesRoot `
    "packages\scoop.txt"

$Packages = Get-PackageList `
    -File $PackageFile

foreach ($Package in $Packages) {

    try {

        if (-not (scoop list | Select-String "^$Package\s")) {

            Write-Host "[INSTALL] $Package" `
                -ForegroundColor Yellow

            scoop install $Package
        }
    }
    catch {

        Write-Host "[FAILED] $Package" `
            -ForegroundColor Red
    }
}

Write-Host "[INFO] Updating installed Scoop packages..." `
    -ForegroundColor Cyan

scoop update *
