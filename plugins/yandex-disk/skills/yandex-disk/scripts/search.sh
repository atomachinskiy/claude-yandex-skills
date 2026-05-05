#!/bin/sh
# search.sh — search files in Yandex.Disk by name.
# Usage: search.sh <query> [--limit N]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

QUERY="$1"
LIMIT="${2:-50}"

if [ -z "$QUERY" ]; then
    echo "Usage: search.sh <query> [--limit N]" >&2
    exit 1
fi

ENC=$(printf '%s' "$QUERY" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=''))")

# Note: as of 2026, Yandex.Disk public REST API doesn't have a dedicated /search endpoint.
# We use /resources/last-uploaded as a starting filter, then grep client-side.
DATA=$(call GET "/resources/last-uploaded?limit=${LIMIT}&media_type=document,image,spreadsheet,text,audio,video,archive,backup,book,compressed,data,development,diskimage,executable,settings,source,unknown,web")
echo "$DATA" | $JQ -r --arg Q "$QUERY" '
    .items[]? |
    select((.name | test($Q; "i")) or (.path | test($Q; "i"))) |
    "\(.path)\t\(.size // 0)\t\(.created)"
' | head -n "$LIMIT" | limit_output
