Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Configure Scoop"

# =========================
# FORCE NON-INTERACTIVE MODE
# =========================
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'

# =========================
# ENSURE USER CONTEXT ONLY
# =========================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($IsAdmin) {
    Write-Host "[INFO] Scoop must run in USER context. Re-launching..." -ForegroundColor Yellow

    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAsUser

    exit
}

# =========================
# INSTALL SCOOP (USER ONLY)
# =========================
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Installing Scoop (silent user install)..."

    # IMPORTANT: NO -RunAsAdmin (this breaks everything)
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

# =========================
# UPDATE PATH (SAFE MERGE)
# =========================
$env:Path =
    [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
    [System.Environment]::GetEnvironmentVariable('Path','User')

# =========================
# UPDATE SCOOP (NO PROMPTS)
# =========================
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Updating Scoop..." -ForegroundColor Cyan
    scoop update 2>$null
}

# =========================
# BUCKET SETUP (IDEMPOTENT)
# =========================
$Buckets = @(
    'main',
    'extras',
    'versions',
    'nerd-fonts',
    'sysinternals'
)

foreach ($Bucket in $Buckets) {
    $exists = scoop bucket list 2>$null | Select-String "^$Bucket\s"

    if (-not $exists) {
        Write-Host "[INFO] Adding bucket: $Bucket"
        scoop bucket add $Bucket 2>$null
    }
}

Write-Host "[SUCCESS] Scoop configured (USER MODE, NO PROMPTS)" -ForegroundColor Green
