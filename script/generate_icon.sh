#!/usr/bin/env bash
# Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT_DIR/work/AppIcon.iconset"
SOURCE="$ROOT_DIR/Resources/AppIcon-source.png"
mkdir -p "$ICONSET"
/usr/bin/sips -z 1024 1024 "$SOURCE" --out "$ROOT_DIR/Resources/AppIcon.png" >/dev/null
for size in 16 32 128 256 512; do
    /usr/bin/sips -z "$size" "$size" "$SOURCE" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    retina=$((size * 2))
    /usr/bin/sips -z "$retina" "$retina" "$SOURCE" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
/usr/bin/iconutil -c icns "$ICONSET" -o "$ROOT_DIR/Resources/AppIcon.icns"
echo "Generated Resources/AppIcon.png and Resources/AppIcon.icns"
