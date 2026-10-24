#!/usr/bin/env python3
"""Check the app a customer actually extracts, not merely the ZIP's filename."""

import argparse
import json
import plistlib
from pathlib import Path, PurePosixPath
import zipfile


APP_NAME = "Notchscape"


def validate_archive(path):
    with zipfile.ZipFile(path) as archive:
        paths = set()
        roots = set()
        for item in archive.infolist():
            parts = PurePosixPath(item.filename).parts
            if not parts or parts[0] == "/" or ".." in parts or "\\" in item.filename:
                raise ValueError("Unsafe archive entry")
            if item.filename in paths:
                raise ValueError("Duplicate archive entry")
            paths.add(item.filename)
            if parts[0] != "__MACOSX":
                roots.add(parts[0])
            if "BoringNotchXPCHelper.xpc" in parts:
                raise ValueError("Old helper product name in customer archive")
        if roots != {APP_NAME + ".app"}:
            raise ValueError("The download must extract exactly one Notchscape.app")
        info_path = APP_NAME + ".app/Contents/Info.plist"
        if archive.getinfo(info_path).file_size > 1024 * 1024:
            raise ValueError("Unexpectedly large app metadata")
        info = plistlib.loads(archive.read(info_path))
        for key in ("CFBundleName", "CFBundleDisplayName", "CFBundleExecutable"):
            if info.get(key) != APP_NAME:
                raise ValueError("Customer-facing {} must be Notchscape".format(key))
        if APP_NAME + ".app/Contents/MacOS/" + APP_NAME not in paths:
            raise ValueError("Branded executable is missing")
        if info.get("NotchAccountsEnabled") is not False:
            raise ValueError("Unfinished account features must remain disabled")
        if info.get("SUFeedURL") != "https://raw.githubusercontent.com/graden-grech/Notchscape/main/appcast.xml":
            raise ValueError("Download does not use the Notchscape update feed")
        return {
            "app": APP_NAME + ".app",
            "version": info.get("CFBundleShortVersionString"),
            "build": info.get("CFBundleVersion"),
            "accountsEnabled": False,
            "note": "Branding/archive check only; signing, notarization and live update tests are separate.",
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    try:
        print(json.dumps(validate_archive(args.archive), indent=2))
    except (ValueError, KeyError, zipfile.BadZipFile, plistlib.InvalidFileException) as error:
        parser.exit(1, "FAIL: {}\n".format(error))


if __name__ == "__main__":
    main()
