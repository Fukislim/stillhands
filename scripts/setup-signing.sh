#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Stillhands Local Signing"
KEYCHAIN="$HOME/Library/Keychains/stillhands-signing.keychain-db"

[[ -f .env ]] && source .env
if [[ -z "${STILLHANDS_KEYCHAIN_PASSWORD:-}" ]]; then
    STILLHANDS_KEYCHAIN_PASSWORD=$(openssl rand -hex 32)
    (umask 077; echo "STILLHANDS_KEYCHAIN_PASSWORD=$STILLHANDS_KEYCHAIN_PASSWORD" >> .env)
fi
PASSWORD=$STILLHANDS_KEYCHAIN_PASSWORD

if [[ -f "$KEYCHAIN" ]]; then
    echo "Signing keychain already exists: $KEYCHAIN"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$tmp/key.pem" -out "$tmp/cert.pem" -subj "/CN=$NAME" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

legacy=""
openssl version | grep -q "^OpenSSL 3" && legacy="-legacy"
openssl pkcs12 -export $legacy -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
    -name "$NAME" -out "$tmp/identity.p12" -passout "pass:$PASSWORD"

security create-keychain -p "$PASSWORD" "$KEYCHAIN"
security set-keychain-settings "$KEYCHAIN"
security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
security import "$tmp/identity.p12" -k "$KEYCHAIN" -P "$PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$PASSWORD" "$KEYCHAIN" >/dev/null

echo "Created \"$NAME\" in $KEYCHAIN"
