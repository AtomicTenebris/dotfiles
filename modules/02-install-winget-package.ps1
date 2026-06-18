Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Winget Packages"

$PacakgeFile = Join-Path  `
  $Global:DotfilesRoot `
  'packages\winget.txt'

$Packages = Get-Content $PacakgeFile | 
Where-Object {
  $_.Trim() -and -not $_.StartsWith('#')
}

foreach ($Package in $Packages) {
  $Installed = winget list `
    --id $Package `
    --exact `
    --accept-source-agreements 2>$null


  if (-not $Installed) {
    Write-Host "[INSTALL] $Package"

    winget install `
      --id $Package `
      --source winget `
      --exact `
      --silent `
      --accept-source-agreements `
      --accept-package-agreements
    continue
  }
  Write-Host "[UPDATE] $Package" -ForegroundColor Cyan
  
  winget upgrade `
    --id $Package `
    --source winget `
    --exact `
    --silent `
    --accept-source-agreements `
    --accept-package-agreements

}
