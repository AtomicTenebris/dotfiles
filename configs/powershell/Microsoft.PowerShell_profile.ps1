$ConfigRoot =  Join-Path $HOME ".config\powershell"
$UserProfile = Join-Path $ConfigRoot "user_profile.ps1"

if (Test-Path $UserProfile){
  . $UserProfile
}