#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v python3 >/dev/null || { echo "Python 3.9 or newer is required." >&2; exit 1; }
exec python3 "$script_dir/firefox_privacy.py" "$@"
