#!/bin/sh
# Common functions for yandex-metrika skill. POSIX sh compatible — no bashisms.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"

API_BASE="https://api-metrika.yandex.net"
JQ="$(command -v jq || echo /usr/local/bin/jq)"

_AUTH_COMMON="$SCRIPT_DIR/../../../../yandex-auth/skills/yandex-auth/scripts/common.sh"
[ ! -f "$_AUTH_COMMON" ] && _AUTH_COMMON="$HOME/.claude/skills/yandex-auth/scripts/common.sh"
. "$_AUTH_COMMON"

load_config() {
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
    yandex_load_token
}

cache_path() { echo "$CACHE_DIR/$1/$2"; }
cache_get() {
    _f="$1"; _ttl="${2:-86400}"
    [ -f "$_f" ] && [ -s "$_f" ] || return 1
    _age=$(( $(date +%s) - $(stat -f %m "$_f" 2>/dev/null || stat -c %Y "$_f") ))
    [ "$_age" -gt "$_ttl" ] && return 1
    cat "$_f"
}
cache_put() { mkdir -p "$(dirname "$1")"; cat > "$1"; }

limit_output() {
    if [ "${OUTPUT_FULL:-0}" -eq 1 ]; then cat; return; fi
    awk 'NR<=30; END { if (NR>30) printf "# ... truncated (%d more lines). Use --full to show all.\n", NR-30 }'
}

auth_header() { printf 'Authorization: OAuth %s' "$YANDEX_ACCESS_TOKEN"; }

call() {
    _method="$1"; _path="$2"; shift 2
    curl -s --max-time 30 -X "$_method" \
        -H "$(auth_header)" \
        -H "Content-Type: application/json" \
        "$@" \
        "$API_BASE$_path"
}
