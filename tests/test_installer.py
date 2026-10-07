import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('installer', Path(__file__).resolve().parents[1] / 'firefox_privacy.py')
i = importlib.util.module_from_spec(spec)
spec.loader.exec_module(i)

class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'Firefox'
        self.root.mkdir()
        self.source = self.base / 'Files'
        for name, text in {'mozilla.cfg': 'new', 'distribution/policies.json': '{"policies":{}}',
                           'distribution/extensions/one.xpi': 'extension',
                           'browser/defaults/preferences/autoconfig.js': 'pref'}.items():
            target = self.source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
    def install(self, platform='linux', force=False):
        i.install(self.root, self.source, platform, force)
    def test_nested_payload_all_platforms(self):
        for platform in ('windows','linux','macos'):
            with self.subTest(platform=platform):
                self.install(platform)
                self.assertEqual((self.root/'distribution/extensions/one.xpi').read_text(), 'extension')
                preference = 'defaults/pref/autoconfig.js' if platform == 'macos' else 'browser/defaults/preferences/autoconfig.js'
                self.assertTrue((self.root/preference).exists())
                i.uninstall(self.root)
                self.assertFalse((self.root/'mozilla.cfg').exists())
    def test_restore_exact_original_and_unrelated(self):
        (self.root/'mozilla.cfg').write_bytes(b'original\r\n')
        unrelated = self.root/'distribution/extensions/unrelated.xpi'
        unrelated.parent.mkdir(parents=True)
        unrelated.write_bytes(b'keep')
        self.install(force=True)
        self.install(force=True)
        i.uninstall(self.root)
        self.assertEqual((self.root/'mozilla.cfg').read_bytes(), b'original\r\n')
        self.assertEqual(unrelated.read_bytes(), b'keep')
    def test_conflict_preflight_changes_nothing(self):
        (self.root/'mozilla.cfg').write_text('original')
        with self.assertRaises(ValueError): self.install()
        self.assertFalse((self.root/i.STATE).exists())
        self.assertEqual((self.root/'mozilla.cfg').read_text(), 'original')
    def test_edited_file_blocks_uninstall(self):
        self.install()
        (self.root/'mozilla.cfg').write_text('user edit')
        with self.assertRaises(ValueError): i.uninstall(self.root)
        self.assertTrue((self.root/'distribution/extensions/one.xpi').exists())
        self.assertEqual((self.root/'mozilla.cfg').read_text(), 'user edit')
    def test_upgrade_keeps_first_backup(self):
        (self.root/'mozilla.cfg').write_text('original')
        self.install(force=True)
        (self.source/'mozilla.cfg').write_text('updated')
        self.install()
        i.uninstall(self.root)
        self.assertEqual((self.root/'mozilla.cfg').read_text(), 'original')
    def test_interrupted_install_is_recoverable(self):
        real_copy = i.atomic_copy
        def fail(source,target):
            if target.name == 'mozilla.cfg': raise OSError('simulated write failure')
            return real_copy(source,target)
        with patch.object(i,'atomic_copy',side_effect=fail):
            with self.assertRaises(OSError): self.install()
        i.uninstall(self.root)
        self.assertFalse((self.root/'distribution/extensions/one.xpi').exists())
    def test_interrupted_update_is_recoverable(self):
        self.install()
        (self.source/'mozilla.cfg').write_text('updated')
        real_copy = i.atomic_copy
        def fail(source,target):
            if target.name == 'mozilla.cfg': raise OSError('simulated write failure')
            return real_copy(source,target)
        with patch.object(i,'atomic_copy',side_effect=fail):
            with self.assertRaises(OSError): self.install()
        i.uninstall(self.root)
        self.assertFalse((self.root/'mozilla.cfg').exists())
    def test_corrupt_backup_refused(self):
        (self.root/'mozilla.cfg').write_text('original')
        self.install(force=True)
        backup = next((self.root/i.STATE/'backups').iterdir())
        backup.write_text('damaged')
        with self.assertRaises(ValueError): i.uninstall(self.root)
    def test_legacy_uninstall_refused(self):
        (self.root/'mozilla.cfg').write_text('unknown owner')
        with self.assertRaises(ValueError): i.uninstall(self.root)
        self.assertTrue((self.root/'mozilla.cfg').exists())
    def test_symlink_destination_refused(self):
        outside = self.base/'outside'
        outside.mkdir()
        try: (self.root/'distribution').symlink_to(outside, target_is_directory=True)
        except OSError: self.skipTest('symlink privilege unavailable')
        with self.assertRaises(ValueError): self.install()
        self.assertEqual(list(outside.iterdir()), [])
    def test_traversal_manifest_refused(self):
        self.install()
        path=self.root/i.STATE/'manifest.json'
        data=json.loads(path.read_text())
        data['files']['../outside']=data['files'].pop('mozilla.cfg')
        path.write_text(json.dumps(data))
        with self.assertRaises(ValueError): i.uninstall(self.root)
    def test_concurrent_operation_refused(self):
        with i.operation_lock(self.root):
            with self.assertRaises(ValueError): self.install()
        self.assertFalse((self.root / '.sos-privacy.lock').exists())
    def test_plist_is_not_written(self):
        (self.source/'distribution/org.mozilla.firefox.plist').write_text('legacy')
        self.install('macos')
        self.assertFalse((self.root/'distribution/org.mozilla.firefox.plist').exists())

if __name__ == '__main__': unittest.main()
