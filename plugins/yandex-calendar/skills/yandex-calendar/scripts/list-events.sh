#!/bin/sh
# list-events.sh — list events from a calendar in a date range.
# Usage: list-events.sh <calendar-path> [--from YYYY-MM-DD] [--to YYYY-MM-DD]
#   calendar-path is from list-calendars.sh, e.g. /calendars/foo@yandex.ru/events-853016/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAL_PATH=""
FROM=""
TO=""
while [ $# -gt 0 ]; do
    case "$1" in
        --from) shift; FROM="$1" ;;
        --to)   shift; TO="$1" ;;
        -h|--help) echo "Usage: list-events.sh <calendar-path> [--from YYYY-MM-DD] [--to YYYY-MM-DD]"; exit 0 ;;
        *)      CAL_PATH="$1" ;;
    esac
    shift
done

if [ -z "$CAL_PATH" ]; then
    echo "Usage: list-events.sh <calendar-path> [--from YYYY-MM-DD] [--to YYYY-MM-DD]" >&2
    echo "Get calendar paths via: list-calendars.sh" >&2
    exit 1
fi

# Default: today → today + 30 days
[ -z "$FROM" ] && FROM=$(date -u +"%Y-%m-%d")
[ -z "$TO" ]   && TO=$(date -u -v +30d +"%Y-%m-%d" 2>/dev/null || date -u -d "+30 days" +"%Y-%m-%d")

XML=$(report_calendar_query "$CAL_PATH" "$FROM" "$TO")

python3 - "$XML" "$FROM" "$TO" <<'PY' | limit_output
import sys, re
xml = sys.argv[1]; fr = sys.argv[2]; to = sys.argv[3]

# Extract calendar-data blocks
items = re.findall(r'<C:calendar-data[^>]*>(.*?)</C:calendar-data>', xml, re.S)
events = []
for ical in items:
    # Unescape entities
    ical = ical.replace("&#13;", "").replace("&#10;", "\n")
    summary = re.search(r'\nSUMMARY:([^\r\n]+)', ical)
    dtstart = re.search(r'\nDTSTART[^:]*:([0-9TZ]+)', ical)
    location = re.search(r'\nLOCATION:([^\r\n]+)', ical)
    events.append((dtstart.group(1) if dtstart else "?",
                   summary.group(1) if summary else "(без названия)",
                   location.group(1) if location else ""))

events.sort(key=lambda x: x[0])
print(f"# Events in range {fr} → {to}: {len(events)} found\n")
for dt, name, loc in events:
    # Format dt: 20260520T100000Z → 2026-05-20 10:00
    pretty = dt
    if len(dt) == 8:
        pretty = f"{dt[0:4]}-{dt[4:6]}-{dt[6:8]} (all day)"
    elif len(dt) >= 13 and dt[8] == 'T':
        pretty = f"{dt[0:4]}-{dt[4:6]}-{dt[6:8]} {dt[9:11]}:{dt[11:13]}"
    print(f"  {pretty}  {name[:60]}{'  @ ' + loc if loc else ''}")
PY
