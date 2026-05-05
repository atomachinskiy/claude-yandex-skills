#!/bin/sh
# popular-queries.sh — top search queries for a host.
# Usage: popular-queries.sh <host-id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit N]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

HOST_ID=""; FROM=""; TO=""; LIMIT=20; OUTPUT_JSON=0
while [ $# -gt 0 ]; do
    case "$1" in
        --from) shift; FROM="$1" ;;
        --to) shift; TO="$1" ;;
        --limit) shift; LIMIT="$1" ;;
        --json) OUTPUT_JSON=1 ;;
        *) HOST_ID="$1" ;;
    esac
    shift
done

[ -z "$HOST_ID" ] && { echo "Usage: popular-queries.sh <host-id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--limit N]" >&2; exit 1; }
[ -z "$FROM" ] && FROM=$(date -u -v -30d +"%Y-%m-%d" 2>/dev/null || date -u -d "-30 days" +"%Y-%m-%d")
[ -z "$TO" ]   && TO=$(date -u +"%Y-%m-%d")

USER_ID=$(call GET /user/ | $JQ -r '.user_id')
ENC=$(printf '%s' "$HOST_ID" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=''))")

DATA=$(call GET "/user/$USER_ID/hosts/$ENC/search-queries/popular/?order_by=DEMAND&query_indicator=TOTAL_SHOWS&date_from=$FROM&date_to=$TO&limit=$LIMIT")

if [ "$OUTPUT_JSON" -eq 1 ]; then echo "$DATA" | $JQ .; exit 0; fi

{
    echo "# Top queries — host: $HOST_ID  ($FROM → $TO, limit $LIMIT)"
    echo ""
    echo "$DATA" | $JQ -r '.queries[]? | "\(.query_text)|\(.indicators.TOTAL_SHOWS // 0)|\(.indicators.TOTAL_CLICKS // 0)|\(.indicators.AVG_SHOW_POSITION // 0)|\(.indicators.AVG_CLICK_POSITION // 0)"' | \
    awk -F'|' '{ printf "%-50s shows=%-8s clicks=%-6s pos_show=%-5s pos_click=%s\n", substr($1,1,50), $2, $3, $4, $5 }'
} | limit_output
