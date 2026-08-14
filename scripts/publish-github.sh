#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

OWNER="${GITHUB_USER:-linux503}"
REPO="MacFan"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Creating repo $OWNER/$REPO…"
  gh repo create "$OWNER/$REPO" --public --source=. --remote=origin --push --description "Native macOS fan control for Intel & Apple Silicon"
else
  echo "Pushing to origin…"
  git push -u origin main
fi

echo "Configuring GitHub Pages (/docs)…"
gh api -X PUT "repos/$OWNER/$REPO/pages" \
  -H "Accept: application/vnd.github+json" \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/docs \
  || echo "请手动：Settings → Pages → Branch: main → /docs"

echo ""
echo "Repo: https://github.com/$OWNER/$REPO"
echo "Site: https://$OWNER.github.io/$REPO/"
