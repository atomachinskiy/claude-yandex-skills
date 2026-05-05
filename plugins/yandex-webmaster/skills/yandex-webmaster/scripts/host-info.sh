#!/bin/sh
# host-info.sh — info about a specific host (SQI, indexing stats, search summary).
# Usage: host-info.sh <host-id>  (host-id from list-hosts.sh, e.g. https:dariabot.ru:443)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

HOST_ID="$1"
[ -z "$HOST_ID" ] && { echo "Usage: host-info.sh <host-id>" >&2; exit 1; }

USER_ID=$(call GET /user/ | $JQ -r '.user_id')
ENC=$(printf '%s' "$HOST_ID" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=''))")

INFO=$(call GET "/user/$USER_ID/hosts/$ENC")
SUMMARY=$(call GET "/user/$USER_ID/hosts/$ENC/summary")

if [ "$2" = "--json" ]; then
    echo "$INFO $SUMMARY" | $JQ -s '{info: .[0], summary: .[1]}'
    exit 0
fi

cat <<OUT
# Host: $(echo "$INFO" | $JQ -r '.unicode_host_url')

ID:            $(echo "$INFO" | $JQ -r '.host_id')
Verified:      $(echo "$INFO" | $JQ -r '.verified')
Main mirror:   $(echo "$INFO" | $JQ -r '.main_mirror.host_id // "—"')

== Summary ==
Pages in search:     $(echo "$SUMMARY" | $JQ -r '.searchable_pages_count // "?"')
SQI:                 $(echo "$SUMMARY" | $JQ -r '.sqi // "?"')
Indexing date:       $(echo "$SUMMARY" | $JQ -r '.indexing.last_index_date // "?"')
Downloaded pages:    $(echo "$SUMMARY" | $JQ -r '.indexing.downloaded_pages_count // "?"')
External links:      $(echo "$SUMMARY" | $JQ -r '.external_links.external_links_count // "?"')
OUT
