#!/bin/sh
# goals.sh — list goals (conversions) configured for a counter.
# Usage: goals.sh <counter-id> [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CID="$1"
[ -z "$CID" ] && { echo "Usage: goals.sh <counter-id>" >&2; exit 1; }

DATA=$(call GET "/management/v1/counter/$CID/goals")
if [ "$2" = "--json" ]; then echo "$DATA" | $JQ .; exit 0; fi

GOALS=$(echo "$DATA" | $JQ -r '.goals | length')
echo "# Goals: $GOALS configured for counter $CID"
echo ""
echo "$DATA" | $JQ -r '.goals[] | "\(.id)|\(.name)|\(.type)|\(.is_retargeting // false)"' | \
    awk -F'|' '{ printf "%-12s %-50s %-12s retargeting=%s\n", $1, substr($2,1,50), $3, $4 }'
