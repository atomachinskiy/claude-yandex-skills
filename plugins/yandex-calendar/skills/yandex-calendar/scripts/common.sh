#!/bin/sh
# Common functions for yandex-calendar (CalDAV).
# Auth: HTTP Basic with login:OAuth-token. Yandex CalDAV requires login@yandex.ru form.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"

CALDAV_BASE="https://caldav.yandex.ru"

# Bridge to yandex-auth
_AUTH_COMMON="$SCRIPT_DIR/../../../../yandex-auth/skills/yandex-auth/scripts/common.sh"
[ ! -f "$_AUTH_COMMON" ] && _AUTH_COMMON="$HOME/.claude/skills/yandex-auth/scripts/common.sh"
. "$_AUTH_COMMON"

load_config() {
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
    yandex_load_token
    # Calendar principal needs email-form login (login@yandex.ru)
    case "$YANDEX_LOGIN" in
        *@*) PRINCIPAL="$YANDEX_LOGIN" ;;
        *)   PRINCIPAL="${YANDEX_LOGIN}@yandex.ru" ;;
    esac
    export PRINCIPAL
    AUTH="${YANDEX_LOGIN}:${YANDEX_ACCESS_TOKEN}"
    export AUTH
}

# propfind <path> <depth> <prop_xml>
propfind() {
    _path="$1"; _depth="$2"; _props="$3"
    curl -s -X PROPFIND \
        -u "$AUTH" \
        -H "Depth: $_depth" \
        -H "Content-Type: application/xml; charset=utf-8" \
        --data "<?xml version=\"1.0\"?><propfind xmlns=\"DAV:\" xmlns:C=\"urn:ietf:params:xml:ns:caldav\"><prop>${_props}</prop></propfind>" \
        "$CALDAV_BASE$_path"
}

# report_calendar_query <calendar_path> <date_from> <date_to>
# Returns multistatus with VCALENDAR data for events in range.
report_calendar_query() {
    _path="$1"; _from="$2"; _to="$3"
    # CalDAV time format: 20260505T000000Z
    _f=$(echo "$_from" | sed 's/-//g')T000000Z
    _t=$(echo "$_to"   | sed 's/-//g')T235959Z
    curl -s -X REPORT \
        -u "$AUTH" \
        -H "Depth: 1" \
        -H "Content-Type: application/xml; charset=utf-8" \
        --data "<?xml version=\"1.0\"?>
<C:calendar-query xmlns:D=\"DAV:\" xmlns:C=\"urn:ietf:params:xml:ns:caldav\">
  <D:prop><D:getetag/><C:calendar-data/></D:prop>
  <C:filter><C:comp-filter name=\"VCALENDAR\"><C:comp-filter name=\"VEVENT\">
    <C:time-range start=\"$_f\" end=\"$_t\"/>
  </C:comp-filter></C:comp-filter></C:filter>
</C:calendar-query>" \
        "$CALDAV_BASE$_path"
}

limit_output() {
    if [ "${OUTPUT_FULL:-0}" -eq 1 ]; then cat; return; fi
    awk 'NR<=30; END { if (NR>30) printf "# ... truncated (%d more lines). Use --full to show all.\n", NR-30 }'
}
