#!/bin/sh
# common.sh — shared helpers for yandex-* skills.
# Sourced by every other yandex-pack skill via:
#   . "$(dirname "$0")/../../yandex-auth/skills/yandex-auth/scripts/common.sh"
# OR (when installed as a plugin) the path is resolved through the plugin manifest.
# POSIX sh, no bashisms.

YANDEX_TOKEN_FILE="${YANDEX_TOKEN_FILE:-$HOME/.claude/secrets/yandex-app.json}"

# yandex_load_token — exports YANDEX_ACCESS_TOKEN, YANDEX_LOGIN, YANDEX_USER_ID.
# Exits 1 with a friendly message if the file is missing or unparseable.
yandex_load_token() {
    if [ ! -f "$YANDEX_TOKEN_FILE" ]; then
        echo "ERROR: $YANDEX_TOKEN_FILE not found." >&2
        echo "Run: bash <yandex-auth>/scripts/oauth-flow.sh" >&2
        exit 1
    fi

    YANDEX_ACCESS_TOKEN=$(sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    YANDEX_LOGIN=$(sed -n 's/.*"yandex_login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    YANDEX_USER_ID=$(sed -n 's/.*"yandex_user_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")

    if [ -z "$YANDEX_ACCESS_TOKEN" ] || [ "${#YANDEX_ACCESS_TOKEN}" -lt 30 ]; then
        echo "ERROR: access_token in $YANDEX_TOKEN_FILE looks invalid." >&2
        echo "Re-run: bash <yandex-auth>/scripts/oauth-flow.sh" >&2
        exit 1
    fi

    export YANDEX_ACCESS_TOKEN YANDEX_LOGIN YANDEX_USER_ID
}

# yandex_auth_header — echoes the Authorization header value (no trailing newline).
yandex_auth_header() {
    yandex_load_token
    printf 'Authorization: OAuth %s' "$YANDEX_ACCESS_TOKEN"
}

# yandex_auth_status — print a brief status of the current token.
yandex_auth_status() {
    if [ ! -f "$YANDEX_TOKEN_FILE" ]; then
        echo "❌ No token. Run: bash oauth-flow.sh"
        return 1
    fi
    LOGIN=$(sed -n 's/.*"yandex_login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    _ya_uid=$(sed -n 's/.*"yandex_user_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    ISSUED=$(sed -n 's/.*"issued_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    EXPIRES=$(sed -n 's/.*"expires_at_estimate"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")
    echo "✅ Token present"
    echo "   Account:    $LOGIN  (id=$_ya_uid)"
    echo "   Issued:     $ISSUED"
    echo "   Estimated:  $EXPIRES"
    echo "   File:       $YANDEX_TOKEN_FILE"

    # Live-check the token
    PROBE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: OAuth $(sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$YANDEX_TOKEN_FILE")" \
        "https://login.yandex.ru/info?format=json")
    if [ "$PROBE" = "200" ]; then
        echo "   Live check: 200 OK"
    else
        echo "   Live check: HTTP $PROBE — токен похоже отозван, re-run oauth-flow.sh"
    fi
}
