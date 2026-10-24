import importlib.util
import plistlib
from pathlib import Path
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "verify_distribution_archive.py"
SPEC = importlib.util.spec_from_file_location("distribution_archive", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class DistributionArchiveTests(unittest.TestCase):
    def fixture(self, root="Notchscape.app", extra=None, **overrides):
        directory = tempfile.TemporaryDirectory(prefix="notchscape-archive-test-")
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "Notchscape.zip"
        info = dict(CFBundleName="Notchscape", CFBundleDisplayName="Notchscape",
                    CFBundleExecutable="Notchscape", NotchAccountsEnabled=False,
                    SUFeedURL="https://raw.githubusercontent.com/graden-grech/Notchscape/main/appcast.xml")
        info.update(overrides)
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr(root + "/Contents/Info.plist", plistlib.dumps(info))
            archive.writestr(root + "/Contents/MacOS/Notchscape", b"fixture only")
            if extra:
                archive.writestr(extra, b"fixture only")
        return path

    def test_branded_download_passes(self):
        self.assertEqual(MODULE.validate_archive(self.fixture())["app"], "Notchscape.app")

    def test_branded_zip_with_old_app_inside_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(root="Boring Notch.app"))

    def test_old_executable_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(CFBundleExecutable="Boring Notch"))

    def test_old_display_name_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(CFBundleDisplayName="Boring Notch"))

    def test_second_app_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(extra="Old.app/Contents/Info.plist"))

    def test_path_traversal_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(extra="Notchscape.app/../outside"))

    def test_accounts_cannot_slip_back_in(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(NotchAccountsEnabled=True))

    def test_other_update_server_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(SUFeedURL="https://example.com/feed.xml"))

    def test_old_helper_filename_fails(self):
        with self.assertRaises(ValueError):
            MODULE.validate_archive(self.fixture(extra="Notchscape.app/Contents/XPCServices/BoringNotchXPCHelper.xpc/Contents/Info.plist"))
