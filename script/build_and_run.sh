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
"$ROOT_DIR/script/build_bundle.sh" "$APP_BUNDLE" debug native
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
