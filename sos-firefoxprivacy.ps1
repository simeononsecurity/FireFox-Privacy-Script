#SimeonOnSecurity - https://simeononsecurity.ch
#https://github.com/simeononsecurity/FireFox-Privacy-Script/
#https://www.itsupportguides.com/knowledge-base/tech-tips-tricks/how-to-customise-firefox-installs-using-mozilla-cfg/

#Continue on error
$ErrorActionPreference = 'silentlycontinue'

#Require elivation for script run
#Requires -RunAsAdministrator

#Set Directory to PSScriptRoot
if ((Get-Location).Path -NE $PSScriptRoot) { Set-Location $PSScriptRoot }


$firefox64 = "C:\Program Files\Mozilla Firefox"
$firefox32 = "C:\Program Files (x86)\Mozilla Firefox"

Write-Output "Installing Firefox Configurations - Please Wait."
Write-Output "Window will close after install is complete"
If ((Test-Path -Path $firefox64) -eq $true){
    Copy-Item -Path .\Files\* -Destination $firefox64 -Force -Recurse
    Write-Host "Firefox 64-Bit Configurations Installed"
}Else {
    Write-Host "FireFox 64-Bit Is Not Installed"
}
If ((Test-Path -Path $firefox32) -eq $true){
    Copy-Item -Path .\Files\* -Destination $firefox32 -Force -Recurse
    Write-Host "Firefox 32-Bit Configurations Installed"
}Else {
    Write-Host "FireFox 32-Bit Is Not Installed"
}
