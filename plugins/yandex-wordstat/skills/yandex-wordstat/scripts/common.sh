#!/bin/sh
# Common functions for yandex-wordstat skill — DUAL BACKEND.
# Backend selection (auto-first):
#   1. If $YANDEX_WORDSTAT_BACKEND is set explicitly → use it.
#   2. Else if cloud SA key present → cloud.
#   3. Else if dedicated YANDEX_WORDSTAT_TOKEN present → legacy.
#   4. Else fall back to shared yandex-auth token + cross fingers (legacy API).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/.env"
CACHE_DIR="$SCRIPT_DIR/../cache"

JQ="$(command -v jq || echo /usr/local/bin/jq)"

# API bases
LEGACY_API="https://api.wordstat.yandex.net/v1"
CLOUD_API="https://searchapi.api.cloud.yandex.net/v2"

# Bridge to yandex-auth (for fallback)
_AUTH_COMMON="$SCRIPT_DIR/../../../../yandex-auth/skills/yandex-auth/scripts/common.sh"
[ ! -f "$_AUTH_COMMON" ] && _AUTH_COMMON="$HOME/.claude/skills/yandex-auth/scripts/common.sh"
# shellcheck disable=SC1090
. "$_AUTH_COMMON"

load_config() {
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

    # Backend resolution
    if [ -n "$YANDEX_WORDSTAT_BACKEND" ]; then
        BACKEND="$YANDEX_WORDSTAT_BACKEND"
    elif [ -n "$YANDEX_CLOUD_SA_KEY_FILE" ] && [ -f "$YANDEX_CLOUD_SA_KEY_FILE" ]; then
        BACKEND="cloud"
    elif [ -n "$YANDEX_WORDSTAT_TOKEN" ]; then
        BACKEND="legacy"
    else
        # Fall back to shared yandex-auth token, treated as legacy bearer
        BACKEND="legacy"
    fi

    case "$BACKEND" in
        legacy)
            if [ -n "$YANDEX_WORDSTAT_TOKEN" ]; then
                WS_TOKEN="$YANDEX_WORDSTAT_TOKEN"
            else
                yandex_load_token
                WS_TOKEN="$YANDEX_ACCESS_TOKEN"
            fi
            ;;
        cloud)
            [ -z "$YANDEX_CLOUD_FOLDER_ID" ] && { echo "ERROR: YANDEX_CLOUD_FOLDER_ID not set in config/.env" >&2; exit 1; }
            [ -z "$YANDEX_CLOUD_SA_KEY_FILE" ] && { echo "ERROR: YANDEX_CLOUD_SA_KEY_FILE not set" >&2; exit 1; }
            [ ! -f "$YANDEX_CLOUD_SA_KEY_FILE" ] && { echo "ERROR: SA key file missing: $YANDEX_CLOUD_SA_KEY_FILE" >&2; exit 1; }
            WS_TOKEN=$(get_iam_token)
            ;;
        *)
            echo "ERROR: unknown backend '$BACKEND' (use legacy|cloud|auto)" >&2
            exit 1
            ;;
    esac
    export BACKEND WS_TOKEN
}

# get_iam_token — generates JWT, exchanges for IAM token, caches for 1h.
# Requires openssl and python3. Result printed on stdout.
get_iam_token() {
    _cache="$CACHE_DIR/iam_token.txt"
    if [ -f "$_cache" ]; then
        _age=$(( $(date +%s) - $(stat -f %m "$_cache" 2>/dev/null || stat -c %Y "$_cache") ))
        if [ "$_age" -lt 3600 ]; then
            cat "$_cache"
            return 0
        fi
    fi

    python3 - <<PY
import json, time, base64, subprocess, sys, urllib.request

with open("$YANDEX_CLOUD_SA_KEY_FILE") as f:
    sa = json.load(f)

now = int(time.time())
header = {"typ":"JWT","alg":"PS256","kid":sa["id"]}
payload = {"iss": sa["service_account_id"], "aud": "https://iam.api.cloud.yandex.net/iam/v1/tokens", "iat": now, "exp": now + 3600}
def b64(x): return base64.urlsafe_b64encode(json.dumps(x, separators=(',',':')).encode()).rstrip(b"=").decode()
unsigned = (b64(header) + "." + b64(payload)).encode()

# Sign with openssl using SA private_key
import tempfile, os
with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".pem") as kf:
    kf.write(sa["private_key"])
    keyfile = kf.name
try:
    sig = subprocess.check_output(
        ["openssl","dgst","-sha256","-sigopt","rsa_padding_mode:pss","-sigopt","rsa_pss_saltlen:-1","-sign",keyfile],
        input=unsigned)
finally:
    os.unlink(keyfile)
sig_b64 = base64.urlsafe_b64encode(sig).rstrip(b"=").decode()
jwt = unsigned.decode() + "." + sig_b64

req = urllib.request.Request("https://iam.api.cloud.yandex.net/iam/v1/tokens",
    data=json.dumps({"jwt": jwt}).encode(),
    headers={"Content-Type":"application/json"})
with urllib.request.urlopen(req, timeout=15) as r:
    iam = json.load(r)["iamToken"]
print(iam)
PY
}

# call_legacy <path> [json_body]
call_legacy() {
    _path="$1"; _body="${2:-}"
    if [ -n "$_body" ]; then
        curl -s --max-time 30 -X POST \
            -H "Authorization: Bearer $WS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$_body" \
            "$LEGACY_API$_path"
    else
        curl -s --max-time 30 -X GET \
            -H "Authorization: Bearer $WS_TOKEN" \
            "$LEGACY_API$_path"
    fi
}

# call_cloud <path> [json_body]
# Cloud Wordstat (preview): /v2/wordstat/{topRequests|dynamics|regionsStats}
call_cloud() {
    _path="$1"; _body="${2:-}"
    # Inject folderId to body (cloud requirement)
    if [ -n "$_body" ]; then
        _body=$(echo "$_body" | $JQ --arg f "$YANDEX_CLOUD_FOLDER_ID" '. + {folderId: $f}')
        curl -s --max-time 30 -X POST \
            -H "Authorization: Bearer $WS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$_body" \
            "$CLOUD_API$_path"
    else
        curl -s --max-time 30 -X GET \
            -H "Authorization: Bearer $WS_TOKEN" \
            "$CLOUD_API$_path"
    fi
}

# Unified call dispatcher
call() {
    case "$BACKEND" in
        legacy) call_legacy "$@" ;;
        cloud)  call_cloud  "$@" ;;
    esac
}

# Output limiter
limit_output() {
    if [ "${OUTPUT_FULL:-0}" -eq 1 ]; then cat; return; fi
    awk 'NR<=30; END { if (NR>30) printf "# ... truncated (%d more lines). Use --full to show all.\n", NR-30 }'
}
