#!/bin/bash
cd "$(dirname "$0")"
chmod +x scripts/serve-site.sh 2>/dev/null
exec ./scripts/serve-site.sh
