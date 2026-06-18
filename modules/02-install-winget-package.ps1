Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Winget Packages"

$PackageFile = Join-Path `
  $Global:DotfilesRoot `
  'packages\winget.txt'

$Packages = Get-Content $PackageFile | Where-Object {
  $_.Trim() -and -not $_.StartsWith('#')
}

# Ensure Winget sources are fresh
winget source update --quiet

foreach ($Package in $Packages) {

    Write-Host "`n[PROCESS] $Package" -ForegroundColor Cyan

    # -----------------------------
    # Install (idempotent approach)
    # -----------------------------

    & winget install `
        --id $Package `
        -e `
        --silent `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Installed/Already present: $Package" -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] Install may have failed: $Package (exit $LASTEXITCODE)" -ForegroundColor Yellow
    }
}
