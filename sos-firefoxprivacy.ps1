# SimeonOnSecurity - https://simeononsecurity.ch
# https://github.com/simeononsecurity/FireFox-Privacy-Script/
# https://www.itsupportguides.com/knowledge-base/tech-tips-tricks/how-to-customise-firefox-installs-using-mozilla-cfg/

# Continue on error
$ErrorActionPreference = 'silentlycontinue'

# Require elevation for script run
# Requires -RunAsAdministrator

# Set Directory to PSScriptRoot
if ((Get-Location).Path -NE $PSScriptRoot) { Set-Location $PSScriptRoot }

$firefox64 = "C:\Program Files\Mozilla Firefox"
$firefox32 = "C:\Program Files (x86)\Mozilla Firefox"
$installLog = "$PSScriptRoot\install_log.txt"
$force = $false
$uninstall = $false

# Check if --force or --uninstall is applied
if ($args -contains '--force') {
    $force = $true
}
if ($args -contains '--uninstall') {
    $uninstall = $true
}

# Function to copy files with user confirmation
function Copy-FilesWithConfirmation {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    $files = Get-ChildItem -Path $sourcePath
    foreach ($file in $files) {
        $destinationFile = Join-Path $destinationPath $file.Name
        if (Test-Path $destinationFile) {
            if ($force -eq $false) {
                $userInput = Read-Host "File $($file.Name) already exists. Do you want to replace it? (y/n)"
                if ($userInput -eq 'y') {
                    Remove-Item $destinationFile -Force
                    Copy-Item -Path $file.FullName -Destination $destinationFile
                    Add-Content -Path $installLog -Value $destinationFile
                } else {
                    Write-Host "Skipped $($file.Name)"
                }
            } else {
                # If force is enabled, override without prompting
                Remove-Item $destinationFile -Force
                Copy-Item -Path $file.FullName -Destination $destinationFile
                Add-Content -Path $installLog -Value $destinationFile
            }
        } else {
            Copy-Item -Path $file.FullName -Destination $destinationFile
            Add-Content -Path $installLog -Value $destinationFile
        }
    }
}

# Function to uninstall files using the install log
function Uninstall-Files {
    if (Test-Path $installLog) {
        $filesToRemove = Get-Content -Path $installLog
        foreach ($file in $filesToRemove) {
            if (Test-Path $file) {
                Remove-Item $file -Force
                Write-Host "Removed $file"
            } else {
                Write-Host "File $file not found, skipping."
            }
        }
        Remove-Item $installLog -Force
        Write-Host "Uninstallation complete. Install log removed."
    } else {
        Write-Host "No installation log found. Nothing to uninstall."
    }
}

# Main logic
if ($uninstall) {
    Write-Output "Uninstalling Firefox Configurations - Please Wait."
    Uninstall-Files
} else {
    Write-Output "Installing Firefox Configurations - Please Wait."
    Write-Output "Window will close after install is complete"

    If ((Test-Path -Path $firefox64) -eq $true) {
        Copy-FilesWithConfirmation -sourcePath ".\Files" -destinationPath $firefox64
        Write-Host "Firefox 64-Bit Configurations Installed"
    } Else {
        Write-Host "FireFox 64-Bit Is Not Installed"
    }

    If ((Test-Path -Path $firefox32) -eq $true) {
        Copy-FilesWithConfirmation -sourcePath ".\Files" -destinationPath $firefox32
        Write-Host "Firefox 32-Bit Configurations Installed"
    } Else {
        Write-Host "FireFox 32-Bit Is Not Installed"
    }
}
