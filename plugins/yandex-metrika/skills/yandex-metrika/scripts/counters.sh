#!/bin/sh
# counters.sh — list all Yandex.Metrika counters available to the authorised user.
# Usage: counters.sh [--search QUERY] [--json] [--full]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

QUERY=""
OUTPUT_JSON=0
OUTPUT_FULL=0
while [ $# -gt 0 ]; do
    case "$1" in
        --search) shift; QUERY="$1" ;;
        --json) OUTPUT_JSON=1 ;;
        --full) OUTPUT_FULL=1 ;;
    esac
    shift
done

DATA=$(call GET /management/v1/counters)
ROWS=$(echo "$DATA" | $JQ -r '.rows // 0')

if [ "$OUTPUT_JSON" -eq 1 ]; then echo "$DATA" | $JQ .; exit 0; fi

{
    echo "# Yandex.Metrika counters: $ROWS available"
    echo ""
    if [ -n "$QUERY" ]; then
        echo "$DATA" | $JQ -r --arg q "$QUERY" '.counters[] | select(((.name // "") | test($q; "i")) or ((.site // "") | test($q; "i"))) | "\(.id)|\(.name // "-")|\(.site // "-")|\(.status // "?")"'
    else
        echo "$DATA" | $JQ -r '.counters[] | "\(.id)|\(.name // "-")|\(.site // "-")|\(.status // "?")"'
    fi | awk -F'|' '{ printf "%-12s %-40s %-30s %s\n", $1, substr($2,1,40), substr($3,1,30), $4 }'
} | limit_output
