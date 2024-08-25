# FireFox Privacy Script

[![Sponsor](https://img.shields.io/badge/Sponsor-Click%20Here-ff69b4)](https://github.com/sponsors/simeononsecurity) 

Organizations like [PrivacyTools.io](https://www.privacytools.io/browsers/#about_config) and [ffprofile](https://ffprofile.com/) have suggested changes to make FireFox more secure and private.
These changes cover suggested browser extensions, blocking telemetry, disabling 3rd-party cookies, disabling trackers, etc.

This script will take the pregenerated FireFox configuration files and install them in the proper directories on either Windows or Linux systems.

## Download the required files

Download the required files from the [GitHub Repository](https://github.com/simeononsecurity/FireFox-Privacy-Script)

## How to run the script

**The script may be launched from the extracted [GitHub download](https://github.com/simeononsecurity/FireFox-Privacy-Script/archive/master.zip) like this:**

### Windows PowerShell:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
powershell -ExecutionPolicy Bypass -File "C:\Path\To\Your\sos-firefoxprivacy.ps1"
```

#### Additional Flags for Windows:

- **Force Install:** To overwrite existing configuration files without prompting, use the `--force` flag:
    ```powershell
    powershell -ExecutionPolicy Bypass -File "C:\Path\To\Your\sos-firefoxprivacy.ps1" --force
    ```

- **Uninstall:** To remove all changes made by the script, use the `--uninstall` flag:
    ```powershell
    powershell -ExecutionPolicy Bypass -File "C:\Path\To\Your\sos-firefoxprivacy.ps1" --uninstall
    ```

### Linux and MacOS:
```bash
sudo chmod +x ./sos-firefoxprivacy.sh
sudo bash ./sos-firefoxprivacy.sh
```

#### Additional Flags for Linux and MacOS:

- **Force Install:** To overwrite existing configuration files without prompting, use the `--force` flag:
    ```bash
    sudo bash ./sos-firefoxprivacy.sh --force
    ```

- **Uninstall:** To remove all changes made by the script, use the `--uninstall` flag:
    ```bash
    sudo bash ./sos-firefoxprivacy.sh --uninstall
    ```
