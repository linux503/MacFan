#!/bin/bash
# Generate high-quality website images from HTML mockups (Chrome headless).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$ROOT/docs/_gen"
ASSETS="$ROOT/docs/assets"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
APPICON="$ROOT/MacFan/Resources/AppIcon-1024.png"

if [[ ! -x "$CHROME" ]]; then
  echo "Google Chrome not found at $CHROME" >&2
  exit 1
fi

refresh_logos() {
  if [[ -f "$APPICON" ]]; then
    sips -z 512 512 "$APPICON" --out "$ASSETS/logo-512.png" >/dev/null
    sips -z 1024 1024 "$APPICON" --out "$ASSETS/logo.png" >/dev/null
    echo "Refreshed logos from AppIcon-1024.png"
  fi
}

shot() {
  local html="$1" out="$2" w="$3" h="$4"
  local tmp="$ASSETS/.tmp-$out"
  "$CHROME" \
    --headless=new \
    --disable-gpu \
    --hide-scrollbars \
    --window-size="$w,$h" \
    --force-device-scale-factor=2 \
    --screenshot="$tmp" \
    "file://$GEN/$html" 2>/dev/null
  sips -z "$((h * 2))" "$((w * 2))" "$tmp" --out "$ASSETS/$out" >/dev/null
  rm -f "$tmp"
  local kb
  kb=$(du -k "$ASSETS/$out" | awk '{print $1}')
  echo "Wrote $out (${kb} KB, $((w * 2))x$((h * 2)))"
}

refresh_logos
shot hero.html hero-home.png 1600 1000
shot dashboard.html poster-dashboard.png 1600 1000
shot modes.html poster-modes.png 1400 900
shot scenes.html poster-scenes.png 1400 900
shot og.html poster-og.png 1200 630
shot start.html poster-start.png 1400 720

echo "Done."
python3 "$ROOT/scripts/optimize-site-assets.py"
