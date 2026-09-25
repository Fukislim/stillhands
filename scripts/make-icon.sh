#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift scripts/draw-icon.swift assets

iconset="$(mktemp -d)/Stillhands.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z $size $size assets/logo.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) assets/logo.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns -o Resources/AppIcon.icns "$iconset"
rm -rf "$(dirname "$iconset")"
echo "wrote Resources/AppIcon.icns"
