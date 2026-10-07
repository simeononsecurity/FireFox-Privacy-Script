#Requires -Version 5.1
#Requires -RunAsAdministrator
# Pass --force, --uninstall and --firefox-dir directly to the shared installer.
$ErrorActionPreference = 'Stop'
try {
    $python = $null
    $prefix = @()
    foreach ($name in @('py', 'python', 'python3')) {
        $candidate = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $candidate -or $candidate.Source -like '*\WindowsApps\*') { continue }
        $probe = @()
        if ($name -eq 'py') { $probe = @('-3') }
        & $candidate.Source @probe -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'
        if ($LASTEXITCODE -eq 0) { $python = $candidate; $prefix = $probe; break }
    }
    if (-not $python) { throw 'Install Python 3.9 or newer and add Python or the py launcher to PATH.' }
    & $python.Source @prefix (Join-Path $PSScriptRoot 'firefox_privacy.py') @args
    exit $LASTEXITCODE
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
