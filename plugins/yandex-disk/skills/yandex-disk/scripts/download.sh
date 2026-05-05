#!/bin/sh
# download.sh — download a file from Yandex.Disk.
# Usage: download.sh <remote-path> [local-file]
#   If local-file omitted — uses remote basename.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

REMOTE="$1"
LOCAL="$2"

if [ -z "$REMOTE" ]; then
    echo "Usage: download.sh <remote-path> [local-file]" >&2
    exit 1
fi

case "$REMOTE" in /*) ;; *) REMOTE="/$REMOTE" ;; esac
[ -z "$LOCAL" ] && LOCAL=$(basename "$REMOTE")

ENC=$(printf '%s' "$REMOTE" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe='/'))")
URL_RESP=$(call GET "/resources/download?path=${ENC}")
HREF=$(echo "$URL_RESP" | $JQ -r '.href // empty')
if [ -z "$HREF" ]; then
    echo "ERROR: failed to get download URL" >&2
    echo "$URL_RESP" | $JQ . >&2
    exit 1
fi

echo "→ $REMOTE  →  $LOCAL"
HTTP=$(curl -s -o "$LOCAL" -w "%{http_code}" -L --max-time 600 "$HREF")
if [ "$HTTP" = "200" ]; then
    SIZE=$(stat -f %z "$LOCAL" 2>/dev/null || stat -c %s "$LOCAL")
    echo "✅ downloaded ${SIZE}B"
else
    echo "❌ download failed: HTTP $HTTP" >&2
    rm -f "$LOCAL"
    exit 1
fi
