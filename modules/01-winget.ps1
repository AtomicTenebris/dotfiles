Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Winget"

Write-Host "[INFO] Winget Verion: " $(winget --version)
Write-Host "[INFO] Resetting Sources: " $(winget source reset --force)
Write-Host "[INFO] Updating sources: " $(winget source update)
Write-Host "[INFO] Current sources: " $(winget source list)


Write-Host "[SUCCESS] Winget configured" -ForegroundColor Green