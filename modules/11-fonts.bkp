Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-ModuleHeader "Install Fonts"


# Paths


$FontsArchiveDir = Join-Path `
    $Global:DotfilesRoot `
    "fonts"

$TempDir = Join-Path `
    $env:TEMP `
    "dotfiles-fonts"


# Validate


if (-not (Test-Path $FontsArchiveDir)) {
    throw "Fonts directory not found."
}


# Cleanup Temporary Directory


if (Test-Path $TempDir) {

    Remove-Item `
        -Path $TempDir `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $TempDir `
    -Force | Out-Null


# Process Archives


$Archives = Get-ChildItem `
    -Path $FontsArchiveDir `
    -Filter "*.zip"

foreach ($Archive in $Archives) {

    Write-Host "[EXTRACT] $($Archive.Name)" `
        -ForegroundColor Yellow

    $ExtractPath = Join-Path `
        $TempDir `
        $Archive.BaseName

    Expand-Archive `
        -Path $Archive.FullName `
        -DestinationPath $ExtractPath `
        -Force

    $FontFiles = Get-ChildItem `
        -Path $ExtractPath `
        -Recurse `
        -Include *.ttf, *.otf

    foreach ($Font in $FontFiles) {

        try {

            $WindowsFont = Join-Path `
                $env:WINDIR `
                "Fonts\$($Font.Name)"

            if (Test-Path $WindowsFont) {

                Write-Host "[SKIP] $($Font.Name)" `
                    -ForegroundColor Cyan

                continue
            }

            Write-Host "[INSTALL] $($Font.Name)" `
                -ForegroundColor Yellow

            $Shell = New-Object `
                -ComObject Shell.Application

            $FontsFolder = $Shell.Namespace(0x14)

            # 16 = FOF_NOCONFIRMATION
            $FontsFolder.CopyHere(
                $Font.FullName,
                16
            )

            Write-Host "[SUCCESS] $($Font.Name)" `
                -ForegroundColor Green
        }
        catch {

            Write-Host "[FAILED] $($Font.Name)" `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor DarkRed
        }
    }
}


# Cleanup


Remove-Item `
    -Path $TempDir `
    -Recurse `
    -Force


# Complete


Write-Host ""
Write-Host "[SUCCESS] Fonts configured" `
    -ForegroundColor Green
