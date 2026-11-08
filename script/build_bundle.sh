#!/usr/bin/env bash
# Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
APP_BUNDLE="${1:?Usage: build_bundle.sh /absolute/output/Vibesomnia.app [debug|release] [native|universal]}"
CONFIGURATION="${2:-debug}"
ARCHITECTURE="${3:-native}"
[[ "$APP_BUNDLE" == /* && "$APP_BUNDLE" == *.app ]] || { echo "Output must be an absolute .app path" >&2; exit 2; }
[[ "$CONFIGURATION" == debug || "$CONFIGURATION" == release ]] || exit 2
[[ "$ARCHITECTURE" == native || "$ARCHITECTURE" == universal ]] || exit 2
# Never replace files inside a running bundle (including a live power guard).
if /bin/ps -axo command= | /usr/bin/grep -F "$APP_BUNDLE/Contents/" | /usr/bin/grep -v grep >/dev/null; then
    echo "Output app is running. End its session and quit before replacing it." >&2
    exit 1
fi
export MACOSX_DEPLOYMENT_TARGET=14.0
BUILD_ARGS=(-c "$CONFIGURATION")
if [[ "$ARCHITECTURE" == universal ]]; then BUILD_ARGS+=(--arch arm64 --arch x86_64); fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/Vibesomnia"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$APP_BUNDLE/Contents/Helpers"
cp "$BIN_DIR/Vibesomnia" "$APP_BINARY"
cp "$BIN_DIR/vibesomnia-cli" "$APP_BUNDLE/Contents/MacOS/vibesomnia-cli"
cp "$BIN_DIR/VibesomniaPowerGuard" "$APP_BUNDLE/Contents/Helpers/VibesomniaPowerGuard"
cp LICENSE "$APP_BUNDLE/Contents/Resources/LICENSE"
if [ -d Resources/AddOnExamples ]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources/AddOnExamples"
    cp -R Resources/AddOnExamples/. "$APP_BUNDLE/Contents/Resources/AddOnExamples/"
fi
cp NOTICE "$APP_BUNDLE/Contents/Resources/NOTICE"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
APP_VERSION="$(cat VERSION)"
BASE_VERSION="${APP_VERSION%%-*}"
BUILD_NUMBER="${APP_VERSION##*.}"
# Beta revisions advance beyond earlier alpha bundle build numbers.
if [[ "$APP_VERSION" == *-beta.* ]]; then BUILD_NUMBER="$((1000 + BUILD_NUMBER))"; fi
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Vibesomnia</string>
<key>CFBundleIdentifier</key><string>com.angelodeleon.Vibesomnia</string>
<key>CFBundleName</key><string>Vibesomnia</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$BASE_VERSION</string>
<key>VibesomniaPrereleaseVersion</key><string>$APP_VERSION</string>
<key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Vibesomnia uses automation to request administrator approval for its temporary closed-lid power guard and launch AI tools in Terminal.</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Angelo De Leon. AGPL-3.0-only.</string>
</dict></plist>
PLIST
SIGNING_IDENTITY="${VIBESOMNIA_SIGNING_IDENTITY:--}"
SIGN_ARGS=(--force --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    SIGN_ARGS+=(--options runtime --timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE/Contents/Helpers/VibesomniaPowerGuard"
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE/Contents/MacOS/vibesomnia-cli"
codesign "${SIGN_ARGS[@]}" --entitlements Resources/Vibesomnia.entitlements "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"
echo "Built $APP_BUNDLE"
