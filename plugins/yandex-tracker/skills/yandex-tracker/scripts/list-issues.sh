#!/bin/sh
# list-issues.sh — list issues by query (all open assigned to me by default).
# Usage: list-issues.sh [--query "Queue: BK"] [--limit N] [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

QUERY='Assignee: me() AND Resolution: empty()'
LIMIT=30
while [ $# -gt 0 ]; do
    case "$1" in
        --query) shift; QUERY="$1" ;;
        --limit) shift; LIMIT="$1" ;;
        --json) OUTPUT_JSON=1 ;;
    esac
    shift
done

BODY=$(printf '{"query":%s}' "$($JQ -n --arg q "$QUERY" '$q')")
DATA=$(tracker_call POST "/issues/_search?perPage=$LIMIT" "$BODY")
if [ "${OUTPUT_JSON:-0}" -eq 1 ]; then echo "$DATA" | $JQ .; exit 0; fi

{
    N=$(echo "$DATA" | $JQ -r 'length')
    echo "# Issues: $N (query: $QUERY)"
    echo ""
    echo "$DATA" | $JQ -r '.[] | "\(.key)|\(.summary)|\(.status.display)|\(.assignee.display // "-")"' | \
        awk -F'|' '{ printf "%-12s %-50s [%-15s] @ %s\n", $1, substr($2,1,50), substr($3,1,15), $4 }'
} | limit_output
