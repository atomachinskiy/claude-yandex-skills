#!/bin/sh
# Common functions for yandex-360-admin skill. POSIX sh compatible — no bashisms.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"

# API base for yandex-360-admin
API_BASE="https://api360.yandex.net"

# Tools
JQ="$(command -v jq || echo /usr/local/bin/jq)"

# ── Bridge to yandex-auth (shared OAuth token) ──────────────────
# Resolve yandex-auth/common.sh by climbing 3 levels up from scripts/ dir,
# then descending into plugins/yandex-auth/skills/yandex-auth/scripts/common.sh.
_AUTH_COMMON="$SCRIPT_DIR/../../../../yandex-auth/skills/yandex-auth/scripts/common.sh"
if [ ! -f "$_AUTH_COMMON" ]; then
    # Fallback when installed as plugins under ~/.claude/skills/
    _AUTH_COMMON="$HOME/.claude/skills/yandex-auth/scripts/common.sh"
fi
# shellcheck disable=SC1090
. "$_AUTH_COMMON"

# load_config — reads optional .env (skill-specific params), then ensures token.
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        . "$CONFIG_FILE"
    fi
    yandex_load_token   # sets YANDEX_ACCESS_TOKEN, YANDEX_LOGIN, YANDEX_USER_ID
}

# ── Cache helpers ──────────────────────────────────────────────
# cache_path TYPE KEY → echoes file path under cache/<type>/<key>
cache_path() {
    echo "$CACHE_DIR/$1/$2"
}

# cache_get FILE [TTL_SECONDS] → echoes content, returns 0 on hit, 1 on miss
cache_get() {
    _f="$1"; _ttl="${2:-86400}"
    [ -f "$_f" ] && [ -s "$_f" ] || return 1
    _age=$(( $(date +%s) - $(stat -f %m "$_f" 2>/dev/null || stat -c %Y "$_f") ))
    [ "$_age" -gt "$_ttl" ] && return 1
    cat "$_f"
}

# cache_put FILE — reads stdin, writes to file
cache_put() {
    mkdir -p "$(dirname "$1")"
    cat > "$1"
}

# ── Output limiter ─────────────────────────────────────────────
# Pipe through limit_output to keep stdout context-friendly.
limit_output() {
    if [ "${OUTPUT_FULL:-0}" -eq 1 ]; then cat; return; fi
    awk 'NR<=30; END { if (NR>30) printf "# ... truncated (%d more lines). Use --full to show all.\n", NR-30 }'
}

# ── Auth header helper ─────────────────────────────────────────
auth_header() {
    printf 'Authorization: OAuth %s' "$YANDEX_ACCESS_TOKEN"
}

# ── Generic call wrapper ───────────────────────────────────────
# call <method> <path> [extra curl args...]
# Echoes raw response body. Method examples: GET, POST.
call() {
    _method="$1"; _path="$2"; shift 2
    curl -s --max-time 30 -X "$_method" \
        -H "$(auth_header)" \
        -H "Content-Type: application/json" \
        "$@" \
        "$API_BASE$_path"
}
