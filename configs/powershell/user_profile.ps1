# Import Module
Import-Module -Name Terminal-Icons
Import-Module -Name PSFzf
Import-Module -Name PSReadLine


Set-Alias -Name code -Value code-insiders
Set-Item -Path Function:chr -Value {code -r .}
Set-Alias -Name unzip -Value Expand-Archive
Set-Alias -Name grep -Value Select-String
Set-Item -Path Function:gs -Value {git status}
Set-Item -Path Function:ga -Value {git add .}
Set-Item -Path Function:gpush -Value {git push}
Set-Item -Path Function:gpull -Value {git pull}
Set-Item -Path Function:gcl -Value {git clone $args}
Set-Item -Path Function:Install-Dotfiles -Value {
    param(
        [string[]]$Modules = @(
            'prerequisites'
            'winget'
            'install-winget-package'
            'scoop'
            'install-scoop-package'
            'powershell'
            'starship'
            'terminal'
            'vscode'
            'neovim'
            'post-install'
        )
    )

    $workspace = Join-Path $HOME "workspace"
    $repoPath = Join-Path $workspace "dotfiles"

    if (Test-Path $repoPath) {
        git -C $repoPath pull
    }
    else {
        git clone https://github.com/AtomicTenebris/dotfiles.git $repoPath
    }

    & (Join-Path $repoPath "install.ps1") -Modules $Modules
}
  function touch($File) {
    if (test-Path $File) {
        (Get-Item $File).LastWriteTime = Get-Date
    }
    else {
        New-Item $File -ItemType File | Out-Null
    }
}

function mkcd ($Path) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
}

function head ($Path) {
    Get-Content $Path -Head 10
}

function sed ($File, $Find, $Replace) {
    (Get-Content $File).replace("$Find", $Replace) | Set-Content $file
}

function which ($Name) {
    (Get-Command $Name).Source
}

Set-PSReadLineOption -PredictionViewStyle ListView -Colors @{
    Command   = '#87CEEB'
    Parameter = '#98FB98'
    Operator  = '#FFB6C1'
    Variable  = '#DDA0DD'
    String    = '#FFDAB9'
    Number    = '#B0E0E6'
    Type      = '#F0E68C'
    Comment   = '#D3D3D3'
    Keyword   = '#8367c7'
    Error     = '#FF6347'
}

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo


function Show-Help {
    $title   = $PSStyle.Foreground.BrightMagenta
    $section = $PSStyle.Foreground.BrightBlue
    $command = $PSStyle.Foreground.BrightGreen
    $desc    = $PSStyle.Foreground.BrightWhite
    $accent  = $PSStyle.Foreground.BrightYellow
    $dim     = $PSStyle.Foreground.BrightBlack
    $reset   = $PSStyle.Reset

    Write-Host @"
${title}󰘳 PowerShell Profile Help${reset}
${dim}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}

${section}󰊢 Dotfiles${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}Install-Dotfiles${reset}   ${accent}→${reset} ${desc}Install or update dotfiles${reset}
  ${command}chr${reset}                ${accent}→${reset} ${desc}Open current directory in VS Code Insiders${reset}

${section}󰊢 Git Shortcuts${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}ga${reset}                 ${accent}→${reset} ${desc}git add .${reset}
  ${command}gs${reset}                 ${accent}→${reset} ${desc}git status${reset}
  ${command}gpull${reset}              ${accent}→${reset} ${desc}git pull${reset}
  ${command}gpush${reset}              ${accent}→${reset} ${desc}git push${reset}
  ${command}gcl <repo>${reset}         ${accent}→${reset} ${desc}git clone <repo>${reset}

${section}󰘴 File & Directory${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}touch <file>${reset}       ${accent}→${reset} ${desc}Create file or update timestamp${reset}
  ${command}mkcd <dir>${reset}         ${accent}→${reset} ${desc}Create directory and enter it${reset}
  ${command}head <file>${reset}        ${accent}→${reset} ${desc}Show first 10 lines${reset}
  ${command}sed <file> <find> <replace>${reset}
                           ${accent}→${reset} ${desc}Replace text in a file${reset}
  ${command}which <command>${reset}    ${accent}→${reset} ${desc}Show command location${reset}

${section}󰊢 Aliases${reset}
${dim}────────────────────────────────────────────────────${reset}
  ${command}code${reset}               ${accent}→${reset} ${desc}code-insiders${reset}
  ${command}unzip${reset}              ${accent}→${reset} ${desc}Expand-Archive${reset}
  ${command}grep${reset}               ${accent}→${reset} ${desc}Select-String${reset}

${dim}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}
"@
}

Invoke-Expression (&starship init powershell)
