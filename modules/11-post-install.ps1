Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Post Install Configuration"

# -----------------------------------------------------------------------------
# WSL2
# -----------------------------------------------------------------------------

Write-Host "[INFO] Configuring WSL2..." `
    -ForegroundColor Yellow

$Features = @(
    "Microsoft-Windows-Subsystem-Linux"
    "VirtualMachinePlatform"
    "Microsoft-Hyper-V-All"
)

foreach ($Feature in $Features) {

    Write-Host "[ENABLE] $Feature"

    dism.exe `
        /Online `
        /Enable-Feature `
        "/FeatureName:$Feature" `
        /All `
        /NoRestart | Out-Null
}

try {

    wsl --install --no-distribution 2>$null

}
catch {
}

try {

    wsl --set-default-version 2 | Out-Null

}
catch {

    Write-Host "[WARN] Unable to set WSL default version." `
        -ForegroundColor Yellow
}

Write-Host "[SUCCESS] WSL2 configured" `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# OneDrive
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] OneDrive" `
    -ForegroundColor Yellow

Get-Process `
    OneDrive `
    -ErrorAction SilentlyContinue |
    Stop-Process `
        -Force `
        -ErrorAction SilentlyContinue

$OneDriveInstallers = @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    "$env:SystemRoot\System32\OneDriveSetup.exe"
)

foreach ($Installer in $OneDriveInstallers) {

    if (Test-Path $Installer) {

        Start-Process `
            -FilePath $Installer `
            -ArgumentList "/uninstall" `
            -Wait
    }
}

$OneDrivePaths = @(
    "$env:USERPROFILE\OneDrive"
    "$env:LOCALAPPDATA\Microsoft\OneDrive"
    "$env:PROGRAMDATA\Microsoft OneDrive"
    "$env:SystemDrive\OneDriveTemp"
)

foreach ($Path in $OneDrivePaths) {

    if (Test-Path $Path) {

        Remove-Item `
            -Path $Path `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

reg delete `
    "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" `
    /f 2>$null

reg delete `
    "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" `
    /f 2>$null

Write-Host "[SUCCESS] OneDrive removed" `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Consumer Applications
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Microsoft Consumer Apps" `
    -ForegroundColor Yellow

$Packages = @(
    "*Xbox*"
    "*Gaming*"
    "*Clipchamp*"
    "*MicrosoftTeams*"
    "*Skype*"
    "*Solitaire*"
    "*WindowsMaps*"
    "*GetHelp*"
    "*GetStarted*"
    "*OfficeHub*"
    "*DevHome*"
    "*BingNews*"
    "*WindowsFeedbackHub*"
    "*Microsoft.Todos*"
    "*People*"
    "*MixedReality*"
    "*MicrosoftStickyNotes*"
    "*Microsoft.BingWeather*"
    "*Microsoft.WindowsAlarms*"
    "*Microsoft.WindowsSoundRecorder*"
    "*Microsoft.PowerAutomateDesktop*"
    "*Microsoft.OutlookForWindows*"
    "*MicrosoftCorporationII.MicrosoftFamily*"
    "*Microsoft.549981C3F5F10*"
)

foreach ($Package in $Packages) {

    Write-Host "[REMOVE] $Package"

    $InstalledPackages = Get-AppxPackage `
        -AllUsers |
        Where-Object {
            $_.Name -like $Package
        }

    foreach ($App in $InstalledPackages) {

        try {

            Remove-AppxPackage `
                -Package $App.PackageFullName `
                -ErrorAction Stop

            Write-Host "  [SUCCESS] $($App.Name)" `
                -ForegroundColor Green
        }
        catch {

            Write-Host "  [SKIP] $($App.Name)" `
                -ForegroundColor Yellow
        }
    }

    $ProvisionedPackages = Get-AppxProvisionedPackage `
        -Online |
        Where-Object {
            $_.DisplayName -like $Package
        }

    foreach ($Provisioned in $ProvisionedPackages) {

        try {

            Remove-AppxProvisionedPackage `
                -Online `
                -PackageName $Provisioned.PackageName `
                -ErrorAction Stop | Out-Null

            Write-Host "  [SUCCESS] $($Provisioned.DisplayName)" `
                -ForegroundColor Green
        }
        catch {

            Write-Host "  [SKIP] $($Provisioned.DisplayName)" `
                -ForegroundColor Yellow
        }
    }
}

Write-Host "[SUCCESS] Consumer applications removed" `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Copilot
# -----------------------------------------------------------------------------

Write-Host "[DISABLE] Copilot" `
    -ForegroundColor Yellow

reg add `
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
    /v TurnOffWindowsCopilot `
    /t REG_DWORD `
    /d 1 `
    /f | Out-Null

# -----------------------------------------------------------------------------
# Widgets
# -----------------------------------------------------------------------------

Write-Host "[DISABLE] Widgets" `
    -ForegroundColor Yellow

reg add `
    "HKLM\SOFTWARE\Policies\Microsoft\Dsh" `
    /v AllowNewsAndInterests `
    /t REG_DWORD `
    /d 0 `
    /f | Out-Null

# -----------------------------------------------------------------------------
# Edge
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Microsoft Edge" `
    -ForegroundColor Yellow

$EdgeInstaller = Get-ChildItem `
    "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" `
    -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if ($EdgeInstaller) {

    & $EdgeInstaller.FullName `
        --uninstall `
        --system-level `
        --force-uninstall `
        --verbose-logging

    Write-Host "[SUCCESS] Edge uninstall executed" `
        -ForegroundColor Green
}
else {

    Write-Host "[SKIP] Edge installer not found" `
        -ForegroundColor Cyan
}

# -----------------------------------------------------------------------------
# Edge Services
# -----------------------------------------------------------------------------

$EdgeServices = @(
    "edgeupdate"
    "edgeupdatem"
)

foreach ($Service in $EdgeServices) {

    Stop-Service `
        $Service `
        -ErrorAction SilentlyContinue

    sc.exe delete $Service | Out-Null
}

# -----------------------------------------------------------------------------
# Edge Scheduled Tasks
# -----------------------------------------------------------------------------

Get-ScheduledTask `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.TaskName -match "Edge"
    } |
    Unregister-ScheduledTask `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Edge Directories
# -----------------------------------------------------------------------------

$EdgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge"
    "C:\Program Files (x86)\Microsoft\EdgeUpdate"
)

foreach ($Path in $EdgePaths) {

    if (Test-Path $Path) {

        Remove-Item `
            -Path $Path `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

Write-Host "[SUCCESS] Edge cleanup completed" `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "Post Install Complete" `
    -ForegroundColor Green
Write-Host "========================================"
Write-Host ""

Write-Host "[INFO] Reboot required." `
    -ForegroundColor Yellow
