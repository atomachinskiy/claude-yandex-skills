#!/bin/sh
# upload.sh — upload a local file to Yandex.Disk.
# Usage: upload.sh <local-file> <remote-path> [--overwrite]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

LOCAL="$1"
REMOTE="$2"
OVERWRITE=false
[ "$3" = "--overwrite" ] && OVERWRITE=true

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
    echo "Usage: upload.sh <local-file> <remote-path> [--overwrite]" >&2
    exit 1
fi

if [ ! -f "$LOCAL" ]; then
    echo "ERROR: local file not found: $LOCAL" >&2
    exit 1
fi

case "$REMOTE" in /*) ;; *) REMOTE="/$REMOTE" ;; esac
ENC=$(printf '%s' "$REMOTE" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe='/'))")

# Step 1: get upload URL
URL_RESP=$(call GET "/resources/upload?path=${ENC}&overwrite=${OVERWRITE}")
HREF=$(echo "$URL_RESP" | $JQ -r '.href // empty')
if [ -z "$HREF" ]; then
    echo "ERROR: failed to get upload URL" >&2
    echo "$URL_RESP" | $JQ . >&2
    exit 1
fi

# Step 2: PUT the file body
SIZE=$(stat -f %z "$LOCAL" 2>/dev/null || stat -c %s "$LOCAL")
echo "→ Uploading $LOCAL ($SIZE bytes) → $REMOTE"
HTTP=$(curl -s -o /tmp/disk-upload-resp -w "%{http_code}" --max-time 600 -T "$LOCAL" "$HREF")
if [ "$HTTP" = "201" ] || [ "$HTTP" = "202" ]; then
    echo "✅ uploaded ($HTTP)"
else
    echo "❌ upload failed: HTTP $HTTP" >&2
    cat /tmp/disk-upload-resp >&2
    exit 1
fi
