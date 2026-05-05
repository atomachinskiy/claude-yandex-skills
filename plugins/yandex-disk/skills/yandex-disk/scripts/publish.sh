#!/bin/sh
# publish.sh — publish a Disk resource and get a public URL.
# Usage: publish.sh <remote-path>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

REMOTE="$1"
if [ -z "$REMOTE" ]; then
    echo "Usage: publish.sh <remote-path>" >&2
    exit 1
fi

case "$REMOTE" in /*) ;; *) REMOTE="/$REMOTE" ;; esac
ENC=$(printf '%s' "$REMOTE" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe='/'))")

call PUT "/resources/publish?path=${ENC}" >/dev/null
INFO=$(call GET "/resources?path=${ENC}")
PUBLIC_URL=$(echo "$INFO" | $JQ -r '.public_url // empty')
if [ -n "$PUBLIC_URL" ]; then
    echo "✅ published"
    echo "Public URL: $PUBLIC_URL"
else
    echo "❌ no public_url in response" >&2
    echo "$INFO" | $JQ . >&2
    exit 1
fi
