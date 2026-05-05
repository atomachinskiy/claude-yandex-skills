#!/bin/sh
# list-queues.sh — list all queues in your Tracker org.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

DATA=$(tracker_call GET /queues)
if [ "$1" = "--json" ]; then echo "$DATA" | $JQ .; exit 0; fi

{
    N=$(echo "$DATA" | $JQ -r 'length')
    echo "# Tracker — $N queues"
    echo ""
    echo "$DATA" | $JQ -r '.[] | "\(.key)|\(.name)|\(.lead.display // .lead.id // "-")"' | \
        awk -F'|' '{ printf "%-15s %-50s lead=%s\n", $1, substr($2,1,50), $3 }'
} | limit_output
