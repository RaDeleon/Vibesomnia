#!/usr/bin/env bash
# Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
MODE="${1:---local}"
[[ "$MODE" == --local || "$MODE" == --signed ]] || { echo 'Usage: package_dmg.sh [--local|--signed]' >&2; exit 2; }
VERSION="$(cat VERSION)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+$ ]] || { echo 'Expected an alpha version' >&2; exit 2; }
if [[ "$MODE" == --signed ]]; then
    : "${VIBESOMNIA_SIGNING_IDENTITY:?Set Developer ID Application identity}"
    : "${VIBESOMNIA_INSTALLER_IDENTITY:?Set Developer ID Installer identity}"
    : "${VIBESOMNIA_NOTARY_PROFILE:?Set a notarytool keychain profile}"
    [[ "$VIBESOMNIA_SIGNING_IDENTITY" != '-' ]] || exit 2
else
    export VIBESOMNIA_SIGNING_IDENTITY=-
fi
OUTPUT="$ROOT_DIR/dist/installers"
mkdir -p "$OUTPUT"
STAGE="$(mktemp -d "$OUTPUT/.stage.XXXXXX")"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT
APP="$STAGE/payload/Applications/Vibesomnia.app"
"$ROOT_DIR/script/build_bundle.sh" "$APP" release universal
# Use a monotonically increasing numeric package version across alpha releases.
PACKAGE_VERSION="${VERSION/-alpha./.}"
PKG_ARGS=(--root "$STAGE/payload" --identifier com.angelodeleon.Vibesomnia.installer
          --version "$PACKAGE_VERSION" --install-location / --scripts "$ROOT_DIR/script/installer")
# Avoid Installer relocating this component to a developer's existing dist bundle.
pkgbuild --analyze --root "$STAGE/payload" "$STAGE/components.plist"
/usr/libexec/PlistBuddy -c 'Add :0:BundleIsRelocatable bool false' "$STAGE/components.plist"
/usr/libexec/PlistBuddy -c 'Set :0:BundleOverwriteAction upgrade' "$STAGE/components.plist"
pkgbuild "${PKG_ARGS[@]}" --component-plist "$STAGE/components.plist" "$STAGE/component.pkg"
cp -R Resources/Installer "$STAGE/resources"
cp LICENSE "$STAGE/resources/License.txt"
cat > "$STAGE/Distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>Vibesomnia $VERSION</title>
  <organization>com.angelodeleon</organization>
  <welcome file="Welcome.html" mime-type="text/html"/>
  <license file="License.txt" mime-type="text/plain"/>
  <conclusion file="Conclusion.html" mime-type="text/html"/>
  <options customize="never" require-scripts="true" hostArchitectures="arm64,x86_64"/>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
  <volume-check><allowed-os-versions><os-version min="14.0"/></allowed-os-versions></volume-check>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" visible="false"><pkg-ref id="com.angelodeleon.Vibesomnia.installer"/></choice>
  <pkg-ref id="com.angelodeleon.Vibesomnia.installer" version="$PACKAGE_VERSION" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
XML
mkdir -p "$STAGE/image"
PRODUCT_ARGS=(--distribution "$STAGE/Distribution.xml" --resources "$STAGE/resources" --package-path "$STAGE")
if [[ "$MODE" == --signed ]]; then PRODUCT_ARGS+=(--sign "$VIBESOMNIA_INSTALLER_IDENTITY" --timestamp); fi
PKG="$STAGE/image/Install Vibesomnia.pkg"
productbuild "${PRODUCT_ARGS[@]}" "$PKG"
if [[ "$MODE" == --signed ]]; then
    xcrun notarytool submit "$PKG" --keychain-profile "$VIBESOMNIA_NOTARY_PROFILE" --wait
    xcrun stapler staple "$PKG"
    xcrun stapler validate "$PKG"
fi
cat > "$STAGE/image/READ ME.txt" <<TXT
VIBESOMNIA $VERSION
You can sleep. Your AI doesn't have to.

1. End any Vibesomnia session and quit the app before installing.
2. Open Install Vibesomnia.pkg and follow the installer.
3. Open Vibesomnia from Applications to begin first-run setup.

macOS 14+. Universal app for Apple silicon and Intel.
This installer never enables SSH, changes sleep settings, or adds a background service.
Closed-lid mode requests administrator approval when you start a session.
Source and license: https://github.com/RaDeleon/Vibesomnia (private during testing).
TXT
SUFFIX=''
if [[ "$MODE" == --local ]]; then
    SUFFIX='-local-unsigned'
    printf '\nLOCAL ALPHA TEST BUILD: installer is unsigned; app is ad-hoc signed.\nNot notarized. Not ready for general distribution.\n' >> "$STAGE/image/READ ME.txt"
fi
cp Resources/AppIcon.icns "$STAGE/image/.VolumeIcon.icns"
xcrun SetFile -a C "$STAGE/image"
NAME="Vibesomnia-$VERSION-universal$SUFFIX.dmg"
hdiutil create -volname "Vibesomnia $VERSION" -srcfolder "$STAGE/image" -format UDZO -ov "$STAGE/$NAME"
if [[ "$MODE" == --signed ]]; then
    codesign --sign "$VIBESOMNIA_SIGNING_IDENTITY" --timestamp "$STAGE/$NAME"
    xcrun notarytool submit "$STAGE/$NAME" --keychain-profile "$VIBESOMNIA_NOTARY_PROFILE" --wait
    xcrun stapler staple "$STAGE/$NAME"
    xcrun stapler validate "$STAGE/$NAME"
fi
hdiutil verify "$STAGE/$NAME"
mv "$STAGE/$NAME" "$OUTPUT/$NAME"
(cd "$OUTPUT" && shasum -a 256 "$NAME" > "$NAME.sha256")
echo "Created $OUTPUT/$NAME"
