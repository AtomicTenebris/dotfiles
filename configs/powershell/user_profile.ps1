Set-Alias -Name code -Value code-insiders
Set-Item -Path Function:chr -Value {code -r .}

function Install-Dotfiles(){
    irm "https://raw.githubusercontent.com/AtomicTenebris/dotfiles/main/bootstrap.ps1" | iex
}
