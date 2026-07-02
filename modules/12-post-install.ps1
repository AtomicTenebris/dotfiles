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

$RestartRequired = $false

foreach ($Feature in $Features) {
    try {
        $State = (Get-WindowsOptionalFeature -Online -FeatureName $Feature -ErrorAction Stop).State
    }
    catch {
        Write-Warning "Could not query feature $Feature - $($_.Exception.Message)"
        continue
    }

    if ($State -eq "Enabled") {
        Write-Host "[SKIP] $Feature already enabled"
        continue
    }

    Write-Host "[ENABLE] $Feature"

    try {
        Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName $Feature `
            -All `
            -NoRestart `
            -ErrorAction Stop | Out-Null

        $RestartRequired = $true
    }
    catch {
        Write-Warning "Failed to enable $Feature - $($_.Exception.Message)"
    }
}

if (-not $RestartRequired) {
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
        try {
            Write-Host "[CONFIG] Setting WSL2 as the default version"
            wsl --set-default-version 2 | Out-Null
        }
        catch {
            Write-Warning "Failed to set the default WSL version to 2."
        }
    }
    else {
        Write-Warning "wsl.exe is not available. A reboot may be required before WSL can be configured."
    }

    Write-Host "[SUCCESS] WSL2 configured" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "[INFO] Windows features have been enabled." -ForegroundColor Yellow
    Write-Host "[INFO] Restart Windows and rerun the installer to complete WSL2 configuration." -ForegroundColor Yellow
}

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
        try {
            Start-Process `
                -FilePath $Installer `
                -ArgumentList "/uninstall" `
                -Wait `
                -NoNewWindow `
                -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to run OneDrive uninstaller $Installer - $($_.Exception.Message)"
        }
    }
}

# Remove leftover OneDrive scheduled tasks
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match "OneDrive" } |
    ForEach-Object {
        try {
            Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to remove scheduled task $($_.TaskName) - $($_.Exception.Message)"
        }
    }

@(
    "$env:USERPROFILE\OneDrive",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    "$env:SystemDrive\OneDriveTemp",
    "$env:ALLUSERSPROFILE\Microsoft OneDrive"
) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$RegistryKeys = @(
    "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\OneDrive"
    "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\OneDrive"
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
)

foreach ($Key in $RegistryKeys) {
    if (Test-Path $Key) {
        try {
            Remove-Item -Path $Key -Recurse -Force -ErrorAction Stop
            Write-Host "[REMOVE] $Key"
        }
        catch {
            Write-Warning "Failed to remove $Key - $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "[SKIP] $Key not found"
    }
}

# Prevent OneDrive from being reinstalled/relaunched on next login
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to set OneDrive policy - $($_.Exception.Message)"
}

Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue |
    Out-Null
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
}

Write-Host "[SUCCESS] OneDrive removed" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Consumer Apps
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Consumer apps" -ForegroundColor Yellow

$Packages = @(
    "*Xbox*","*Gaming*","*Clipchamp*","*MicrosoftTeams*","*Skype*","*Solitaire*",
    "*WindowsMaps*","*GetHelp*","*GetStarted*","*OfficeHub*","*DevHome*",
    "*BingNews*","*WindowsFeedbackHub*","*Microsoft.Todos*","*People*",
    "*MixedReality*","*MicrosoftStickyNotes*","*Microsoft.BingWeather*",
    "*Microsoft.WindowsAlarms*","*Microsoft.WindowsSoundRecorder*",
    "*Microsoft.PowerAutomateDesktop*","*Microsoft.OutlookForWindows*",
    "*MicrosoftCorporationII.MicrosoftFamily*","*Microsoft.549981C3F5F10*"
)

foreach ($Pattern in $Packages) {
    Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
        Where-Object Name -like $Pattern |
        ForEach-Object {
            $PName = $_.Name
            $PFullName = $_.PackageFullName
            try {
                Remove-AppxPackage -Package $PFullName -AllUsers -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to remove package $PName - $($_.Exception.Message)"
            }
        }

    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like $Pattern |
        ForEach-Object {
            $PName = $_.DisplayName
            $PPackageName = $_.PackageName
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $PPackageName -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Warning "Failed to remove provisioned package $PName - $($_.Exception.Message)"
            }
        }
}

# -----------------------------------------------------------------------------
# Copilot - disable AND remove completely
# -----------------------------------------------------------------------------

Write-Host "[REMOVE] Windows Copilot completely" -ForegroundColor Yellow

# 1. System-wide Policy Blocks
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to disable Windows Copilot policy - $($_.Exception.Message)"
}

# 2. User-specific Policy Blocks
try {
    $PolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $PolicyPath)) {
        New-Item -Path $PolicyPath -Force | Out-Null
    }
    New-ItemProperty -Path $PolicyPath -Name TurnOffWindowsCopilot -PropertyType DWord -Value 1 -Force | Out-Null
}
catch {
    Write-Warning "Failed to set user-level Copilot policy - $($_.Exception.Message)"
}

# 3. Completely Uninstall the Copilot App Package
$CopilotPattern = "*Copilot*"

Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
    Where-Object Name -like $CopilotPattern |
    ForEach-Object {
        $PName = $_.Name
        $PFullName = $_.PackageFullName
        try {
            Remove-AppxPackage -Package $PFullName -AllUsers -ErrorAction Stop
            Write-Host "[REMOVE] Removed Appx Package: $PName"
        }
        catch {
            Write-Warning "Failed to remove Copilot package $PName - $($_.Exception.Message)"
        }
    }

# 4. Remove Provisioned Package
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object DisplayName -like $CopilotPattern |
    ForEach-Object {
        $PName = $_.DisplayName
        $PPackageName = $_.PackageName
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $PPackageName -ErrorAction Stop | Out-Null
            Write-Host "[REMOVE] Removed Provisioned Package: $PName"
        }
        catch {
            Write-Warning "Failed to remove provisioned Copilot package $PName - $($_.Exception.Message)"
        }
    }

Write-Host "[SUCCESS] Windows Copilot has been completely removed and disabled" -ForegroundColor Green
