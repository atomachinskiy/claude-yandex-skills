#!/bin/sh
# counter-info.sh — detailed info about one counter.
# Usage: counter-info.sh <counter-id> [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CID="$1"
[ -z "$CID" ] && { echo "Usage: counter-info.sh <counter-id>" >&2; exit 1; }

DATA=$(call GET "/management/v1/counter/$CID")
if [ "$2" = "--json" ]; then echo "$DATA" | $JQ .; exit 0; fi

echo "$DATA" | $JQ -r '.counter | "
ID:        \(.id)
Name:      \(.name)
Site:      \(.site)
Owner:     \(.owner_login)
Created:   \(.create_time)
Status:    \(.status)
Time zone: \(.time_zone_name)
Currency:  \(.currency)
"'
