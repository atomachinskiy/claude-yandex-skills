#!/bin/sh
# list.sh — list contents of a Yandex.Disk directory.
# Usage: list.sh [PATH] [--limit N] [--json] [--full]
#   PATH defaults to "/" (root). Can be "disk:/folder" or just "/folder".

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config
eval "$(parse_simple_flags "$@")"

PATHARG="${POSITIONAL_ARGS:-/}"
LIMIT="${LIMIT:-100}"

# Strip "disk:" prefix if present
PATHARG=$(printf '%s' "$PATHARG" | sed 's|^disk:||')
# Ensure leading /
case "$PATHARG" in /*) ;; *) PATHARG="/$PATHARG" ;; esac

# URL-encode the path (basic — handles spaces and most non-ASCII via printf %02X)
ENC=$(printf '%s' "$PATHARG" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe='/'))")

DATA=$(call GET "/resources?path=${ENC}&limit=${LIMIT}")
ERR=$(echo "$DATA" | $JQ -r '.error // empty')
if [ -n "$ERR" ]; then
    echo "ERROR: $(echo "$DATA" | $JQ -r '.message // .error')" >&2
    exit 1
fi

if [ "$OUTPUT_JSON" -eq 1 ]; then
    echo "$DATA" | $JQ .
    exit 0
fi

NAME=$(echo "$DATA" | $JQ -r '.name')
TYPE=$(echo "$DATA" | $JQ -r '.type')
TOTAL=$(echo "$DATA" | $JQ -r '._embedded.total // "?"')

{
    echo "# $TYPE: $PATHARG  (showing up to $LIMIT of $TOTAL)"
    echo ""
    echo "$DATA" | $JQ -r '
        ._embedded.items[]? |
        [
            (if .type == "dir" then "📁" else "📄" end),
            .name,
            (.size // 0 | tostring),
            (.modified // "" | .[0:10])
        ] | @tsv
    ' | awk -F'\t' '{
        icon = $1; name = $2; size = $3 + 0; date = $4
        if (icon == "📁") { sz = "    —" }
        else if (size < 1024) { sz = sprintf("%4dB", size) }
        else if (size < 1048576) { sz = sprintf("%5.1fKB", size/1024) }
        else if (size < 1073741824) { sz = sprintf("%5.1fMB", size/1048576) }
        else { sz = sprintf("%5.2fGB", size/1073741824) }
        printf "%s  %-45s  %8s  %s\n", icon, substr(name, 1, 45), sz, date
    }'
} | limit_output
