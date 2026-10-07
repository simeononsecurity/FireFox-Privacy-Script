# Firefox Privacy Script

Install the supplied Firefox preferences, policies, and extensions with per-file ownership tracking and restoration of overwritten files.

## Requirements

- Python 3.9 or newer, using only its standard library.
- Firefox or Firefox ESR with a writable native installation directory.
- Close Firefox before installation or restoration. Browser updates should also be idle.
- Use an elevated terminal for installations under protected system directories.

Python is a new runtime prerequisite for the shared installer. The PowerShell and Bash entry points call the same implementation, keeping file ownership and recovery behavior consistent across platforms.

Native Windows, Linux, and macOS layouts are supported by the path resolver. Snap, Flatpak, Microsoft Store, and externally managed browser packages need separate packaging-specific deployment. Select an explicit installation directory when several Firefox installations exist.

## Install

Windows, from an elevated PowerShell window:

```powershell
.\sos-firefoxprivacy.ps1 --firefox-dir 'C:\Program Files\Mozilla Firefox'
```

Linux, including ESR:

```bash
sudo bash ./sos-firefoxprivacy.sh --firefox-dir /usr/lib/firefox-esr
```

macOS:

```bash
sudo bash ./sos-firefoxprivacy.sh --firefox-dir /Applications/Firefox.app/Contents/Resources
```

Omit `--firefox-dir` for automatic discovery when exactly one supported installation is present. Add `--force` to back up and replace conflicting existing configuration files. Every option works through either wrapper or directly through `python3 firefox_privacy.py`.

The installer recursively copies the payload. Existing files are backed up before replacement. Unrelated files stay in place. A manifest and original copies live in `.sos-privacy-state` inside the selected installation. Updates retain the first original backup. Keep this directory until restoration is complete.

The macOS layout uses `distribution/policies.json` and `defaults/pref`. This version does not import a global `org.mozilla.firefox.plist` or copy extensions into Firefox's built-in features directory.

## Restore

Use the same installation directory:

```bash
sudo bash ./sos-firefoxprivacy.sh --uninstall --firefox-dir /usr/lib/firefox-esr
```

```powershell
.\sos-firefoxprivacy.ps1 --uninstall --firefox-dir 'C:\Program Files\Mozilla Firefox'
```

Uninstall restores backed-up files and removes only files recorded as newly installed. It leaves unrelated files and directories alone. Modified installed files or damaged backups stop recovery before file changes. Preserve or reconcile those edits before retrying. There is no force-delete recovery option.

An interrupted operation retains its journal. Inspect the reported failure, preserve the state directory, then retry or uninstall. A lock prevents concurrent operations. After an abrupt process termination, confirm no installer is running before removing the stale `.sos-privacy.lock` file.

## Migration from earlier versions

Earlier installations lack the ownership manifest required for safe automatic recovery. This version refuses to guess which pre-existing files belong to an older installer. Restore an older backup or review those files manually first. Installing over a legacy configuration backs up the legacy state, not factory defaults.

On macOS, review any global Firefox plist created by an older version separately. This installer does not remove unknown global preferences.

## Verify browser behavior

After installation, inspect `about:policies` and `about:support`, test required websites, and check installed extensions. The bundled preference and extension versions remain unchanged in this repair. File-level tests do not establish current browser compatibility or extension maintenance status.

```bash
python3 -m unittest discover -s tests -v
```

CI exercises Windows, Linux, and macOS file fixtures. Tests cover recursive payloads, original-byte restoration, unrelated extensions, update recovery, malformed manifests, symlinks, damaged backups, and modified files. Use a disposable native Firefox installation for browser-level acceptance before release.
