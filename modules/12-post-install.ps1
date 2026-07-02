Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Post Install Configuration"

# -----------------------------------------------------------------------------
# WSL2
# -----------------------------------------------------------------------------

Write-Host "[INFO] Configuring WSL2..." -ForegroundColor Yellow

$Features = @(
    "Microsoft-Windows-Subsystem-Linux"
    "VirtualMachinePlatform"
)

foreach ($Feature in $Features) {
    $State = (Get-WindowsOptionalFeature -Online -FeatureName $Feature).State
    if ($State -ne "Enabled") {
        Write-Host "[ENABLE] $Feature"
        dism.exe /Online /Enable-Feature "/FeatureName:$Feature" /All /NoRestart | Out-Null
    } else {
        Write-Host "[SKIP] $Feature already enabled"
    }
}

try { wsl --status *> $null } catch { wsl --install --no-distribution *> $null }
try { wsl --set-default-version 2 | Out-Null } catch {}

Write-Host "[SUCCESS] WSL2 configured" -ForegroundColor Green

# -----------------------------------------------------------------------------
# OneDrive
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] OneDrive" -ForegroundColor Yellow

Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

foreach ($Installer in @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:SystemRoot\System32\OneDriveSetup.exe"
)) {
    if (Test-Path $Installer) {
        Start-Process $Installer -ArgumentList "/uninstall" -Wait
    }
}

@(
"$env:USERPROFILE\OneDrive",
"$env:LOCALAPPDATA\Microsoft\OneDrive",
"$env:PROGRAMDATA\Microsoft OneDrive",
"$env:SystemDrive\OneDriveTemp"
) | ForEach-Object {
    if(Test-Path $_){ Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
}

reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>$null
reg delete "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>$null
reg delete "HKCU\Software\Microsoft\OneDrive" /f 2>$null
reg delete "HKLM\Software\Microsoft\OneDrive" /f 2>$null

# -----------------------------------------------------------------------------
# Consumer Apps
# -----------------------------------------------------------------------------

$Packages = @(
"*Xbox*","*Gaming*","*Clipchamp*","*MicrosoftTeams*","*Skype*","*Solitaire*",
"*WindowsMaps*","*GetHelp*","*GetStarted*","*OfficeHub*","*DevHome*",
"*BingNews*","*WindowsFeedbackHub*","*Microsoft.Todos*","*People*",
"*MixedReality*","*MicrosoftStickyNotes*","*Microsoft.BingWeather*",
"*Microsoft.WindowsAlarms*","*Microsoft.WindowsSoundRecorder*",
"*Microsoft.PowerAutomateDesktop*","*Microsoft.OutlookForWindows*",
"*MicrosoftCorporationII.MicrosoftFamily*","*Microsoft.549981C3F5F10*"
)

foreach($Pattern in $Packages){
    Get-AppxPackage -AllUsers | Where-Object Name -like $Pattern | ForEach-Object{
        try{ Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop }catch{}
    }
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Pattern | ForEach-Object{
        try{ Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName | Out-Null }catch{}
    }
}

# -----------------------------------------------------------------------------
# Copilot / Widgets
# -----------------------------------------------------------------------------

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f | Out-Null

# -----------------------------------------------------------------------------
# Edge
# -----------------------------------------------------------------------------

Get-Process msedge,msedgewebview2,MicrosoftEdgeUpdate -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$EdgeInstaller = Get-ChildItem "$Env:ProgramFiles(x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue |
Sort-Object VersionInfo.ProductVersion -Descending |
Select-Object -First 1

if($EdgeInstaller){
    Start-Process -FilePath $EdgeInstaller.FullName -ArgumentList @(
        "--uninstall","--system-level","--force-uninstall","--delete-profile"
    ) -Wait
}

foreach($svc in "edgeupdate","edgeupdatem","MicrosoftEdgeElevationService"){
    Stop-Service $svc -Force -ErrorAction SilentlyContinue
    sc.exe delete $svc | Out-Null
}

Get-ScheduledTask -ErrorAction SilentlyContinue |
Where-Object { $_.TaskName -match "Edge|MicrosoftEdgeUpdate" } |
Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

foreach($k in @(
"HKLM:\SOFTWARE\Microsoft\EdgeUpdate",
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate"
)){
    if(Test-Path $k){ Remove-Item $k -Recurse -Force -ErrorAction SilentlyContinue }
}

foreach($p in @(
"$Env:ProgramFiles(x86)\Microsoft\Edge",
"$Env:ProgramFiles(x86)\Microsoft\EdgeUpdate",
"$Env:ProgramData\Microsoft\EdgeUpdate",
"$Env:LOCALAPPDATA\Microsoft\Edge",
"$Env:LOCALAPPDATA\Microsoft\EdgeUpdate"
)){
    if(Test-Path $p){ Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "[SUCCESS] Post install complete." -ForegroundColor Green
Write-Host "[INFO] Reboot required." -ForegroundColor Yellow
