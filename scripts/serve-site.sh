#!/bin/bash
# 本地预览官网（避免 file:// 和 GitHub 网络问题）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS="$ROOT/docs"
PORT="${PORT:-8765}"

python3 "$ROOT/scripts/optimize-site-assets.py" 2>/dev/null || true

echo "MacFan 官网: http://127.0.0.1:$PORT"
echo "按 Ctrl+C 停止"

if command -v open >/dev/null; then
  (sleep 0.4 && open "http://127.0.0.1:$PORT") &
fi

cd "$DOCS"
exec python3 -m http.server "$PORT"
