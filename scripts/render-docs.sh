#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

dist/Stillhands.app/Contents/MacOS/Stillhands --render-docs docs/images
sips -g pixelWidth -g pixelHeight docs/images/*.png
