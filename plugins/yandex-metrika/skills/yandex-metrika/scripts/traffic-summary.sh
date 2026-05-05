#!/bin/sh
# traffic-summary.sh — basic traffic stats for a counter and date range.
# Usage: traffic-summary.sh <counter-id> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CID=""
FROM=""
TO=""
OUTPUT_JSON=0
while [ $# -gt 0 ]; do
    case "$1" in
        --from) shift; FROM="$1" ;;
        --to)   shift; TO="$1" ;;
        --json) OUTPUT_JSON=1 ;;
        *) CID="$1" ;;
    esac
    shift
done

[ -z "$CID" ] && { echo "Usage: traffic-summary.sh <counter-id> [--from YYYY-MM-DD] [--to YYYY-MM-DD]" >&2; exit 1; }
[ -z "$FROM" ] && FROM=$(date -u -v -30d +"%Y-%m-%d" 2>/dev/null || date -u -d "-30 days" +"%Y-%m-%d")
[ -z "$TO" ]   && TO=$(date -u +"%Y-%m-%d")

DATA=$(call GET "/stat/v1/data?ids=${CID}&date1=${FROM}&date2=${TO}&metrics=ym:s:visits,ym:s:users,ym:s:pageviews,ym:s:bounceRate,ym:s:avgVisitDurationSeconds,ym:s:percentNewVisitors&accuracy=1")

if [ "$OUTPUT_JSON" -eq 1 ]; then echo "$DATA" | $JQ .; exit 0; fi

# Surface API errors
ERR=$(echo "$DATA" | $JQ -r '.errors // empty' 2>/dev/null)
if [ -n "$ERR" ] && [ "$ERR" != "null" ]; then
    echo "ERROR: $DATA" >&2
    exit 1
fi

VISITS=$(echo "$DATA" | $JQ -r '.data[0].metrics[0]')
USERS=$(echo "$DATA" | $JQ -r '.data[0].metrics[1]')
PAGEVIEWS=$(echo "$DATA" | $JQ -r '.data[0].metrics[2]')
BOUNCE=$(echo "$DATA" | $JQ -r '.data[0].metrics[3]')
DUR=$(echo "$DATA" | $JQ -r '.data[0].metrics[4]')
NEW=$(echo "$DATA" | $JQ -r '.data[0].metrics[5]')

cat <<OUT
# Traffic summary — counter $CID
Period:        $FROM → $TO

Visits:        $VISITS
Users:         $USERS
Pageviews:     $PAGEVIEWS
Bounce rate:   $(echo "$BOUNCE" | awk '{printf "%.1f%%", $1}')
Avg duration:  $(echo "$DUR" | awk '{printf "%d sec", $1}')
New visitors:  $(echo "$NEW" | awk '{printf "%.1f%%", $1}')
OUT
