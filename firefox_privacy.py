#!/usr/bin/env python3
"""Install and restore only files recorded in a durable ownership manifest."""
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

STATE = '.sos-privacy-state'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def safe_path(root, relative):
    relative = Path(relative)
    if relative.is_absolute() or '..' in relative.parts or not relative.parts:
        raise ValueError('Unsafe manifest path')
    result = root / relative
    for part in (result, *result.parents):
        if part.is_symlink():
            raise ValueError('Symbolic links are not supported: ' + str(part))
        if part == root:
            break
    return result

def atomic_copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.sos-', dir=target.parent)
    os.close(fd)
    try:
        shutil.copy2(source, name)
        os.replace(name, target)
    finally:
        if os.path.exists(name):
            os.unlink(name)

def save_manifest(state, manifest):
    fd, name = tempfile.mkstemp(prefix='manifest-', dir=state)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            json.dump(manifest, stream, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, state / 'manifest.json')
    finally:
        if os.path.exists(name):
            os.unlink(name)

def load_manifest(root, state):
    path = safe_path(state, 'manifest.json')
    data = json.loads(path.read_text(encoding='utf-8'))
    if data.get('version') != 1 or data.get('root') != str(root):
        raise ValueError('Unsupported or relocated manifest')
    if not isinstance(data.get('files'), dict):
        raise ValueError('Invalid manifest entries')
    for relative, entry in data['files'].items():
        safe_path(root, relative)
        if STATE in Path(relative).parts:
            raise ValueError('Manifest references its own state')
        if entry['backup']:
            backup = safe_path(state, entry['backup'])
            if not backup.is_file() or digest(backup) != entry['original_hash']:
                raise ValueError('Missing or damaged backup: ' + relative)
    return data

def payload(source, platform):
    files = {}
    for path in sorted(source.rglob('*')):
        if path.is_symlink():
            raise ValueError('Payload contains a symbolic link')
        if not path.is_file():
            continue
        relative = path.relative_to(source)
        # Use Firefox enterprise policies on every platform. Do not alter global macOS plists.
        if relative.suffix == '.plist':
            continue
        if relative.parts[:3] == ('browser', 'defaults', 'preferences'):
            relative = Path('defaults/pref') / relative.name
        files[relative.as_posix()] = path
    if 'mozilla.cfg' not in files or 'distribution/policies.json' not in files:
        raise ValueError('Required Firefox configuration files are missing')
    json.loads(files['distribution/policies.json'].read_text(encoding='utf-8'))
    return files

def _install(root, source, platform, force=False):
    root = Path(os.path.abspath(root))
    if not root.is_dir():
        raise ValueError('Firefox directory does not exist')
    state = safe_path(root, STATE)
    incoming = payload(source, platform)
    manifest = load_manifest(root, state) if (state / 'manifest.json').exists() else {
        'version': 1, 'root': str(root), 'files': {}}
    # Preflight the whole operation before making changes.
    for relative in incoming:
        target = safe_path(root, relative)
        if target.exists() and not target.is_file():
            raise ValueError('Destination is not a regular file: ' + relative)
        entry = manifest['files'].get(relative)
        if entry and digest(target) not in (entry['installed_hash'], entry['original_hash'], entry.get('previous_hash')):
            raise ValueError('Managed file changed after installation: ' + relative)
        if not entry and target.exists() and not force:
            raise ValueError('Existing file needs --force and will be backed up: ' + relative)
    if state.exists() and not (state / 'manifest.json').exists():
        raise ValueError('State directory has no manifest. Inspect before continuing.')
    state.mkdir(mode=0o700, exist_ok=True)
    save_manifest(state, manifest)
    for relative, source_file in incoming.items():
        target = safe_path(root, relative)
        if relative not in manifest['files']:
            original_hash = digest(target)
            backup = 'backups/' + hashlib.sha256(relative.encode()).hexdigest() if target.exists() else None
            if backup:
                atomic_copy(target, safe_path(state, backup))
            manifest['files'][relative] = {'backup': backup, 'original_hash': original_hash,
                                           'installed_hash': digest(source_file)}
        else:
            # Preserve original backup across updates, and journal the old payload hash.
            manifest['files'][relative]['previous_hash'] = manifest['files'][relative]['installed_hash']
            manifest['files'][relative]['installed_hash'] = digest(source_file)
        save_manifest(state, manifest)
        atomic_copy(source_file, target)
    print('Installed configuration. Recovery manifest: ' + str(state / 'manifest.json'))

def _uninstall(root):
    root = Path(os.path.abspath(root))
    state = safe_path(root, STATE)
    if not (state / 'manifest.json').is_file():
        raise ValueError('No ownership manifest. Legacy installations require manual recovery.')
    manifest = load_manifest(root, state)
    for relative, entry in manifest['files'].items():
        current = digest(safe_path(root, relative))
        if current not in (entry['installed_hash'], entry['original_hash'], entry.get('previous_hash')):
            raise ValueError('File changed since install. Preserve edits before recovery: ' + relative)
    for relative in list(manifest['files']):
        entry = manifest['files'][relative]
        target = safe_path(root, relative)
        if entry['backup']:
            atomic_copy(safe_path(state, entry['backup']), target)
        elif target.exists():
            target.unlink()
        del manifest['files'][relative]
        save_manifest(state, manifest)
    shutil.rmtree(state)
    print('Restored original files. Unrelated files and directories were preserved.')

@contextmanager
def operation_lock(root):
    root = Path(os.path.abspath(root))
    lock = safe_path(root, '.sos-privacy.lock')
    try:
        descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        raise ValueError('Another operation or an interrupted process owns the lock. Inspect .sos-privacy.lock before retrying.')
    try:
        os.write(descriptor, str(os.getpid()).encode('ascii'))
        os.close(descriptor)
        yield
    finally:
        lock.unlink()

def install(root, source, platform, force=False):
    with operation_lock(root):
        _install(root, source, platform, force)

def uninstall(root):
    with operation_lock(root):
        _uninstall(root)

def discover(platform):
    if platform == 'windows':
        candidates = [Path(os.environ.get(key, 'C:/Program Files')) / 'Mozilla Firefox'
                      for key in ('ProgramFiles', 'ProgramFiles(x86)')]
    elif platform == 'macos':
        candidates = [Path('/Applications/Firefox.app/Contents/Resources'),
                      Path('/Applications/Firefox ESR.app/Contents/Resources')]
    else:
        candidates = [Path(base) / name for base in ('/usr/lib64','/usr/lib','/lib64','/lib','/usr/share')
                      for name in ('firefox','firefox-esr')]
    found = list(dict.fromkeys(p for p in candidates if p.is_dir()))
    if len(found) != 1:
        raise ValueError('Select one installation with --firefox-dir. Found: ' + ', '.join(map(str, found)))
    return found[0]

def main():
    platform = 'windows' if sys.platform == 'win32' else 'macos' if sys.platform == 'darwin' else 'linux'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--firefox-dir', type=Path)
    parser.add_argument('--force', action='store_true', help='Back up and replace existing configuration')
    parser.add_argument('--uninstall', action='store_true')
    args = parser.parse_args()
    try:
        root = args.firefox_dir or discover(platform)
        if args.uninstall:
            uninstall(root)
        else:
            install(root, Path(__file__).parent / 'Files', platform, args.force)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
