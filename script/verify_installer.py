#!/usr/bin/env python3
"""Inspect a DMG without installing it or changing power settings."""
# Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import hashlib
import plistlib
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent


def run(*args):
    return subprocess.run([str(a) for a in args], check=True, capture_output=True, text=True).stdout


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def verify(dmg):
    version = (ROOT / "VERSION").read_text().strip()
    checksum = Path(str(dmg) + ".sha256")
    require(checksum.exists(), "Missing checksum file")
    require(hashlib.sha256(dmg.read_bytes()).hexdigest() == checksum.read_text().split()[0], "Checksum mismatch")
    run("hdiutil", "verify", dmg)
    (ROOT / "work").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="verify-installer-", dir=ROOT / "work") as scratch:
        directory = Path(scratch)
        mount = directory / "volume"
        run("hdiutil", "attach", dmg, "-readonly", "-nobrowse", "-mountpoint", mount)
        try:
            pkg = mount / "Install Vibesomnia.pkg"
            require(pkg.is_file(), "Missing Installer package")
            expanded = directory / "expanded"
            run("pkgutil", "--expand-full", pkg, expanded)
            distribution = ET.parse(expanded / "Distribution").getroot()
            require(distribution.find("volume-check/allowed-os-versions/os-version").get("min") == "14.0", "Wrong OS requirement")
            require(distribution.find("domains").get("enable_localSystem") == "true", "Wrong installation domain")
            component = expanded / "component.pkg"
            package = ET.parse(component / "PackageInfo").getroot()
            require(package.get("relocatable") == "false", "Installer may relocate the app")
            require(package.get("install-location") == "/", "Unexpected package root")
            require(package.get("version") == version.replace("-alpha.", ".").replace("-beta.", "."), "Wrong package version")
            preinstall = component / "Scripts/preinstall"
            require(preinstall.read_bytes() == (ROOT / "script/installer/preinstall").read_bytes(), "Preinstall guard mismatch")
            app = component / "Payload/Applications/Vibesomnia.app"
            with (app / "Contents/Info.plist").open("rb") as handle:
                info = plistlib.load(handle)
            require(info["VibesomniaPrereleaseVersion"] == version, "Wrong app version")
            require(info["CFBundleShortVersionString"] == version.split("-")[0], "Wrong marketing version")
            revision = int(version.rsplit(".", 1)[1])
            expected_build = revision + (1000 if "-beta." in version else 0)
            require(info["CFBundleVersion"] == str(expected_build), "Wrong bundle build number")
            require(info["LSMinimumSystemVersion"] == "14.0", "Wrong minimum system version")
            run("codesign", "--verify", "--deep", "--strict", app)
            for relative in ["MacOS/Vibesomnia", "MacOS/vibesomnia-cli", "Helpers/VibesomniaPowerGuard"]:
                binary = app / "Contents" / relative
                require(set(run("lipo", "-archs", binary).split()) == {"arm64", "x86_64"}, f"Not universal: {relative}")
                build = run("xcrun", "vtool", "-show-build", binary)
                require(build.count("minos 14.0") == 2, f"Unexpected deployment target: {relative}")
            require(run(app / "Contents/MacOS/vibesomnia-cli", "--version").strip() == version, "CLI version mismatch")
            require((app / "Contents/Resources/LICENSE").read_bytes() == (ROOT / "LICENSE").read_bytes(), "License mismatch")
            for name in ["Welcome.html", "Conclusion.html", "License.txt"]:
                require((expanded / "Resources" / name).is_file(), f"Missing installer resource: {name}")
            run("/usr/sbin/installer", "-showChoicesXML", "-pkg", pkg, "-target", "/")
        finally:
            run("hdiutil", "detach", mount)
    print(f"Verified {dmg.name}: checksum, image, installer, universal binaries, signatures, versions and resources.")
    print("No system installation, notarization or physical lid/remote test performed.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: verify_installer.py path/to/Vibesomnia.dmg")
    verify(Path(sys.argv[1]).resolve())
