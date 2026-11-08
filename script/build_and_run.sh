#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
APP_BUNDLE="$ROOT_DIR/dist/Vibesomnia.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/Vibesomnia"

case "$MODE" in run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--build-only) ;; *) echo "Usage: $0 [--build-only|--verify|--debug|--logs|--telemetry]" >&2; exit 2;; esac
# Request a graceful quit first; don't kill an app that may own a closed-lid session.
if pgrep -x Vibesomnia >/dev/null; then
    "$APP_BUNDLE/Contents/MacOS/vibesomnia-cli" quit
    for _ in {1..50}; do
        if ! pgrep -x Vibesomnia >/dev/null; then break; fi
        sleep 0.1
    done
    if pgrep -x Vibesomnia >/dev/null; then echo "Vibesomnia is still running. End/recover its session before rebuilding." >&2; exit 1; fi
fi
swift build
BIN_DIR="$(swift build --show-bin-path)"
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
codesign --force --sign - "$APP_BUNDLE/Contents/Helpers/VibesomniaPowerGuard"
codesign --force --sign - "$APP_BUNDLE/Contents/MacOS/vibesomnia-cli"
codesign --force --sign - "$APP_BUNDLE"
case "$MODE" in
    --build-only) echo "Built $APP_BUNDLE" ;;
    --debug|debug) lldb -- "$APP_BINARY" ;;
    --logs|logs) open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "Vibesomnia"' ;;
    --telemetry|telemetry) open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.angelodeleon.Vibesomnia"' ;;
    --verify|verify)
        open -n "$APP_BUNDLE"
        for _ in {1..50}; do
            if "$APP_BUNDLE/Contents/MacOS/vibesomnia-cli" status >/dev/null 2>&1; then echo "Vibesomnia launched and CLI is responding."; exit 0; fi
            sleep 0.2
        done
        echo "Launch verification failed." >&2; exit 1 ;;
    *) open -n "$APP_BUNDLE" ;;
esac
