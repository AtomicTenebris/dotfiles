Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Scoop"

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Write-Host "[INFO] Installing Scoop..."
  Set-ExecutionPolicy-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  Invoke-RestMethod get.scoop.sh | Invoke-Expression

} 
Write-Host "Updating Scoop: $(scoop update)" 
$Buckets = @(
  'main'
  'sysinternals'  
  'extras'
  'versions'
  'nerd-fonts'
)

foreach ($Bucket in $Buckets) {
  if (-not (scoop bucket list | Select-String "^$Bucket\s")) {
    Write-Host "[INFO] Adding Buckets: $Bucket"
    scoop bucket add $Bucket
  }
}

Write-Host "[SUCCESS] Scoop configured" -ForegroundColor Green