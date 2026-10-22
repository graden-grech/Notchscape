"""Branding checks are separate from, and never replace, signing identity gates."""
import plistlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class BrandingGateContractTests(unittest.TestCase):
    def test_signed_build_requires_both_branding_and_identity_gates(self):
        script = (ROOT / ".github/scripts/build_custom_signed_app.sh").read_text()
        self.assertIn("verify_custom_app_branding.sh", script)
        self.assertIn("verify_custom_app_identity.sh", script)
        self.assertLess(script.index("verify_custom_app_branding.sh"), script.index("verify_custom_app_identity.sh"))


@unittest.skipUnless(sys.platform == "darwin", "PlistBuddy gate runs on macOS")
class BrandingGateFixtureTests(unittest.TestCase):
    def run_fixture(self, built_name, display_name):
        with tempfile.TemporaryDirectory(prefix="notch-branding-test-") as temp:
            directory = Path(temp)
            source = directory / "source.plist"
            source.write_bytes(plistlib.dumps({"CFBundleName": "Notchscape", "CFBundleDisplayName": "Notchscape"}))
            app = directory / "fixture.app"
            (app / "Contents").mkdir(parents=True)
            (app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleName": built_name, "CFBundleDisplayName": display_name}))
            return subprocess.run(["bash", str(ROOT / ".github/scripts/verify_custom_app_branding.sh"), str(app), str(source)], capture_output=True).returncode

    def test_matching_names_pass(self):
        self.assertEqual(self.run_fixture("Notchscape", "Notchscape"), 0)

    def test_stale_bundle_name_fails_even_with_new_display_name(self):
        self.assertNotEqual(self.run_fixture("Boring Notch", "Notchscape"), 0)

    def test_stale_display_name_fails(self):
        self.assertNotEqual(self.run_fixture("Notchscape", "Boring Notch"), 0)
