#!/bin/sh
# top-requests.sh — get top related queries for a phrase via Wordstat.
# Usage:
#   top-requests.sh <phrase> [--region 225] [--limit 30] [--json] [--full]
#
# Returns top phrases similar to the input, sorted by monthly volume.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

PHRASE=""
REGIONS="225"
LIMIT=30
OUTPUT_JSON=0
OUTPUT_FULL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --region) shift; REGIONS="$1" ;;
        --regions) shift; REGIONS="$1" ;;
        --limit) shift; LIMIT="$1" ;;
        --json) OUTPUT_JSON=1 ;;
        --full) OUTPUT_FULL=1 ;;
        -h|--help) echo "Usage: top-requests.sh <phrase> [--region 225] [--limit 30] [--json] [--full]"; exit 0 ;;
        *) PHRASE="$1" ;;
    esac
    shift
done

if [ -z "$PHRASE" ]; then
    echo "Usage: top-requests.sh <phrase> [--region 225] [--limit 30] [--json] [--full]" >&2
    exit 1
fi

# Build regions array
REGIONS_JSON=$(echo "[$REGIONS]" | sed 's/[[:space:]]//g')

if [ "$BACKEND" = "legacy" ]; then
    BODY=$(printf '{"phrase":%s,"regions":%s}' \
        "$($JQ -n --arg p "$PHRASE" '$p')" \
        "$REGIONS_JSON")
    DATA=$(call_legacy "/topRequests" "$BODY")
else
    # Cloud schema (preview, may change)
    BODY=$(printf '{"phrase":%s,"regions":%s,"limit":%d}' \
        "$($JQ -n --arg p "$PHRASE" '$p')" \
        "$REGIONS_JSON" "$LIMIT")
    DATA=$(call_cloud "/wordstat/topRequests" "$BODY")
fi

# Surface API errors
ERR=$(echo "$DATA" | $JQ -r 'if type == "object" then (.error // .code // empty) else empty end' 2>/dev/null)
if [ -n "$ERR" ] && [ "$ERR" != "null" ]; then
    echo "ERROR ($BACKEND backend): $DATA" >&2
    exit 1
fi
# Plain-text errors (legacy returns "Forbidden")
if echo "$DATA" | grep -qE '^(Forbidden|Unauthorized|Bad Request)'; then
    echo "ERROR ($BACKEND backend): $DATA" >&2
    echo "Hint: backend=$BACKEND. Check token scope or switch backend via YANDEX_WORDSTAT_BACKEND in config/.env." >&2
    exit 1
fi

if [ "$OUTPUT_JSON" -eq 1 ]; then
    echo "$DATA" | $JQ .
    exit 0
fi

TOTAL=$(echo "$DATA" | $JQ -r '.totalCount // 0')
{
    echo "# Wordstat top requests — phrase: \"$PHRASE\"  region: $REGIONS  backend: $BACKEND"
    echo "Total monthly volume: $TOTAL"
    echo ""
    echo "$DATA" | $JQ -r --argjson lim "$LIMIT" '
        .topRequests // .items // [] |
        .[0:$lim] | to_entries[] |
        "\(.key + 1)|\(.value.phrase // .value.query)|\(.value.count // .value.shows // 0)"
    ' | awk -F'|' '{ printf "%3s. %-50s %10s\n", $1, $2, $3 }'
} | limit_output
