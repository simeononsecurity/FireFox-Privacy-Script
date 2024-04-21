# FireFox Privacy Script

Organizations like [PrivacyTools.io](https://www.privacytools.io/browsers/#about_config) and [ffprofile](https://ffprofile.com/) have suggested changes to make FireFox more secure and private.
These changes cover suggested browser extentions, blocking telemetry, disabling 3rd-party cookies, disabling trackers, etc.

This script will take the pregenerated FireFox configuration files and install them in the proper directories on either Windows or Linux systems.

## Download the required files

Download the required files from the [GitHub Repository](https://github.com/simeononsecurity/FireFox-Privacy-Script)

## How to run the script

**The script may be lauched from the extracted [GitHub download](https://github.com/simeononsecurity/FireFox-Privacy-Script/archive/master.zip) like this:**

Windows PowerShell:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
powershell -ExecutionPolicy Bypass -File "C:\Path\To\Your\sos-firefoxprivacy.ps1"
```

Linux and MacOS:
```bash
sudo chmod +x ./sos-firefoxprivacy.sh
sudo bash ./sos-firefoxprivacy.sh
```
