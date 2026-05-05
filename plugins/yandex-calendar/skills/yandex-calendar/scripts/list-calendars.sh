#!/bin/sh
# list-calendars.sh — list all calendars under the user's CalDAV principal.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

XML=$(propfind "/calendars/$(printf '%s' "$PRINCIPAL" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=""))')/" 1 \
    "<displayname/><resourcetype/>")

python3 - "$XML" <<'PY' | limit_output
import sys, re
xml = sys.argv[1]
# Match each <D:response> block
responses = re.findall(r'<D:response>(.*?)</D:response>', xml, re.S)
print(f"# Yandex.Calendar — {len(responses)} entries under your principal\n")
for r in responses:
    href = re.search(r'<href[^>]*>([^<]+)</href>', r)
    name = re.search(r'<D:displayname[^>]*>([^<]+)</D:displayname>', r)
    is_cal = '<C:calendar' in r and 'urn:ietf:params:xml:ns:caldav' in r.split('<C:calendar')[0] + r.split('<C:calendar')[1] if '<C:calendar' in r else False
    icon = "📅" if "<C:calendar" in r else ("📥" if "schedule-inbox" in r else ("📤" if "schedule-outbox" in r else "📁"))
    h = (href.group(1) if href else "")
    n = (name.group(1) if name else "—")
    print(f"{icon}  {n:<30}  {h}")
PY
