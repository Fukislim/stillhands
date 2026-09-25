#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
APP=dist/Stillhands.app

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Stillhands"

rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Stillhands"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

[[ -f .env ]] && source .env
KEYCHAIN="$HOME/Library/Keychains/stillhands-signing.keychain-db"
IDENTITY=$(security find-identity -p codesigning "$KEYCHAIN" 2>/dev/null | awk '/Stillhands Local Signing/ {print $2; exit}' || true)
if [[ -n "$IDENTITY" && -n "${STILLHANDS_KEYCHAIN_PASSWORD:-}" ]]; then
    security unlock-keychain -p "$STILLHANDS_KEYCHAIN_PASSWORD" "$KEYCHAIN"
    ORIGINAL=$(security list-keychains -d user | tr -d '"' | xargs)
    trap 'security list-keychains -d user -s $ORIGINAL' EXIT
    security list-keychains -d user -s $ORIGINAL "$KEYCHAIN"
    codesign --force --sign "$IDENTITY" "$APP"
else
    echo "note: ad-hoc signing; run scripts/setup-signing.sh to keep Accessibility access across rebuilds"
    codesign --force --sign - "$APP"
fi
ditto -c -k --keepParent "$APP" "dist/Stillhands-$VERSION.zip"
echo "built $APP and dist/Stillhands-$VERSION.zip"
