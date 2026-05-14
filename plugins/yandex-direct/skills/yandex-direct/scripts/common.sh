#!/bin/sh
# Common functions for yandex-direct skill. POSIX sh compatible — no bashisms.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"

# API base for yandex-direct
API_BASE="https://api.direct.yandex.com/json/v5"

# Tools
JQ="$(command -v jq || echo /usr/local/bin/jq)"

# ── Direct uses its own OAuth-app (separate token) ──────────────
# Yandex Direct API requires a dedicated OAuth-app registered in Direct cabinet,
# not the shared "Я-Клауд-Клиентс" app. Token is stored separately.
DIRECT_TOKEN_FILE="${YANDEX_DIRECT_TOKEN_FILE:-$HOME/.claude/secrets/yandex-direct-app.json}"

# load_config — reads optional .env, then loads Direct-specific OAuth token.
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        . "$CONFIG_FILE"
    fi
    if [ ! -f "$DIRECT_TOKEN_FILE" ]; then
        echo "ERROR: Direct OAuth token not found: $DIRECT_TOKEN_FILE" >&2
        echo "Run: bash $SCRIPT_DIR/direct-oauth-flow.sh" >&2
        exit 1
    fi
    YANDEX_DIRECT_ACCESS_TOKEN=$(sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$DIRECT_TOKEN_FILE")
    YANDEX_DIRECT_LOGIN=$(sed -n 's/.*"yandex_login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$DIRECT_TOKEN_FILE")
    if [ -z "$YANDEX_DIRECT_ACCESS_TOKEN" ] || [ "${#YANDEX_DIRECT_ACCESS_TOKEN}" -lt 30 ]; then
        echo "ERROR: Direct access_token in $DIRECT_TOKEN_FILE looks invalid." >&2
        echo "Re-run: bash $SCRIPT_DIR/direct-oauth-flow.sh" >&2
        exit 1
    fi
    export YANDEX_DIRECT_ACCESS_TOKEN YANDEX_DIRECT_LOGIN
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

# ── Auth header helper (Direct uses Bearer, NOT OAuth) ─────────
auth_header() {
    printf 'Authorization: Bearer %s' "$YANDEX_DIRECT_ACCESS_TOKEN"
}

# ── Helper: get all campaign IDs ───────────────────────────────
# Returns comma-separated quoted IDs of ALL campaigns (any state).
# Useful when an API endpoint requires at least one CampaignIds filter
# but the user wants "everything".
get_all_campaign_ids() {
    direct_call campaigns '{"method":"get","params":{"SelectionCriteria":{},"FieldNames":["Id"]}}' \
        | jq -r '.result.Campaigns[]? | "\"" + (.Id|tostring) + "\""' \
        | paste -sd, -
}

# ── Helper: collect unique IDs from ads filtered by a jq selector ──
# Used to discover VCardId / SitelinkSetId / etc. when API requires explicit Ids.
get_referenced_ids() {
    _jq_field="$1"
    ALL_CMP=$(get_all_campaign_ids)
    [ -z "$ALL_CMP" ] && return 0
    direct_call ads "{\"method\":\"get\",\"params\":{\"SelectionCriteria\":{\"CampaignIds\":[$ALL_CMP]},\"FieldNames\":[\"Id\"],\"TextAdFieldNames\":[\"$_jq_field\"]}}" \
        | jq -r ".result.Ads[]?.TextAd.$_jq_field // empty" \
        | sort -u \
        | awk 'NF' \
        | sed 's/.*/"&"/' \
        | paste -sd, -
}

# ── Direct API call wrapper ────────────────────────────────────
# direct_call <resource> <json-body>
# Direct API v5: POST to /json/v5/<resource> with JSON body.
# Example: direct_call clients '{"method":"get","params":{"FieldNames":["ClientId","Login"]}}'
direct_call() {
    _resource="$1"; _body="$2"
    # Drop trailing commas before } / ] that can leak in when scripts concatenate
    # optional filter fragments (e.g. "${CAMPAIGN_IDS}${STATES}"). Direct's parser is strict.
    _body=$(printf '%s' "$_body" | sed -E 's/,([[:space:]]*[]}])/\1/g')
    curl -s --max-time 30 -X POST \
        -H "$(auth_header)" \
        -H "Accept-Language: ru" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "$_body" \
        "$API_BASE/$_resource"
}
