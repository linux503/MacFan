#!/bin/bash
# Build a drag-to-Applications UDZO disk image.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/.build/DerivedData/Build/Products/Release/MacFan.app}"
VERSION="$(/usr/bin/defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)"
STAGE="$ROOT/.build/dmg-root"
OUT="$ROOT/docs/assets/MacFan-${VERSION}-macos.dmg"

if [[ ! -d "$APP" ]]; then
  echo "Missing app: $APP" >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/MacFan.app"
ln -s /Applications "$STAGE/Applications"
xattr -cr "$STAGE/MacFan.app" || true

rm -f "$OUT"
hdiutil create \
  -volname "MacFan" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$OUT" >/dev/null

ls -lh "$OUT"
echo "$OUT"
