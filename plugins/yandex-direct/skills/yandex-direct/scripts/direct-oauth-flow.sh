#!/bin/sh
# direct-oauth-flow.sh — OAuth flow for the Yandex Direct dedicated app.
# Yandex Direct requires its OWN OAuth-app (separate from the shared "Я-Клауд-Клиентс"),
# because the API access application is bound to a specific client_id.
#
# This script captures access_token via implicit flow and writes it to
# ~/.claude/secrets/yandex-direct-app.json (chmod 600).
#
# Usage:
#   bash direct-oauth-flow.sh                  # interactive
#   bash direct-oauth-flow.sh --browser yandex # auto-pick browser
#   bash direct-oauth-flow.sh --status         # show current Direct token

set -e

# Dedicated Direct OAuth-app: "Claud direct"
CLIENT_ID="040b84bb83e74fa6abe6619c7ea0f688"
APP_NAME="Claud direct"

SECRETS_DIR="$HOME/.claude/secrets"
TOKEN_FILE="$SECRETS_DIR/yandex-direct-app.json"
AUTHORIZE_URL="https://oauth.yandex.ru/authorize?response_type=token&force_confirm=yes&client_id=${CLIENT_ID}"

mkdir -p "$SECRETS_DIR"

# ── Status check ─────────────────────────────────────────────────
if [ "$1" = "--status" ]; then
    if [ ! -f "$TOKEN_FILE" ]; then
        echo "❌ Direct token не найден: $TOKEN_FILE"
        echo "   Запусти: bash direct-oauth-flow.sh"
        exit 1
    fi
    TOK=$(sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TOKEN_FILE")
    LGN=$(sed -n 's/.*"yandex_login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TOKEN_FILE")
    echo "Direct token: ${TOK:0:18}…  login: $LGN"
    echo "→ Live-check Direct API:"
    RESP=$(curl -s -X POST \
        -H "Authorization: Bearer $TOK" \
        -H "Accept-Language: ru" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d '{"method":"get","params":{"FieldNames":["ClientId","Login"]}}' \
        "https://api.direct.yandex.com/json/v5/clients")
    echo "$RESP" | head -c 400
    echo ""
    exit 0
fi

# ── Argument parsing ─────────────────────────────────────────────
BROWSER_CHOICE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --browser) shift; BROWSER_CHOICE="$1" ;;
        --browser=*) BROWSER_CHOICE="${1#--browser=}" ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

# ── Platform detection ───────────────────────────────────────────
case "$(uname -s 2>/dev/null || echo Unknown)" in
    Darwin*)  PLATFORM="macos" ;;
    Linux*)   PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)        PLATFORM="unknown" ;;
esac

open_in_browser() {
    _ob_choice="$1"; _ob_url="$2"
    case "$_ob_choice" in
        none) return 1 ;;
        yandex)
            case "$PLATFORM" in
                macos)
                    open -a "Yandex" "$_ob_url" 2>/dev/null && return 0
                    open -a "Yandex Browser" "$_ob_url" 2>/dev/null && return 0 ;;
                linux)
                    for cmd in yandex-browser yandex-browser-stable yandex-browser-beta; do
                        command -v "$cmd" >/dev/null 2>&1 && { "$cmd" "$_ob_url" >/dev/null 2>&1 & return 0; }
                    done ;;
                windows)
                    _yb="$LOCALAPPDATA/Yandex/YandexBrowser/Application/browser.exe"
                    [ -f "$_yb" ] && cmd.exe /c start "" "$_yb" "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1 ;;
        chrome)
            case "$PLATFORM" in
                macos)   open -a "Google Chrome" "$_ob_url" 2>/dev/null && return 0 ;;
                linux)   command -v google-chrome >/dev/null 2>&1 && { google-chrome "$_ob_url" >/dev/null 2>&1 & return 0; } ;;
                windows) cmd.exe /c start chrome "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1 ;;
        default|*)
            case "$PLATFORM" in
                macos)   open "$_ob_url" 2>/dev/null && return 0 ;;
                linux)   xdg-open "$_ob_url" >/dev/null 2>&1 && return 0 ;;
                windows) cmd.exe /c start "" "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1 ;;
    esac
}

cat <<EOF
╭──────────────────────────────────────────────────────────────╮
│  Yandex Direct OAuth — отдельное приложение "$APP_NAME"
│  client_id: $CLIENT_ID
│  Токен будет сохранён в: $TOKEN_FILE
╰──────────────────────────────────────────────────────────────╯

Открой в браузере (или будет открыто автоматически):
$AUTHORIZE_URL

После входа в Яндекс и подтверждения доступа URL станет вида:
  https://oauth.yandex.ru/verification_code#access_token=AQAAA...&...

→ Скопируй значение access_token (без префикса access_token=).

EOF

if [ -z "$BROWSER_CHOICE" ]; then
    printf "Открыть в: [1]Yandex [2]Chrome [3]System [4]Не открывать (Enter=1): "
    read -r _c
    case "${_c:-1}" in
        1) BROWSER_CHOICE=yandex ;;
        2) BROWSER_CHOICE=chrome ;;
        3) BROWSER_CHOICE=default ;;
        4) BROWSER_CHOICE=none ;;
        *) BROWSER_CHOICE=yandex ;;
    esac
fi

if [ "$BROWSER_CHOICE" != "none" ]; then
    open_in_browser "$BROWSER_CHOICE" "$AUTHORIZE_URL" && echo "→ Открыл authorize-URL в '$BROWSER_CHOICE'." \
        || echo "→ Не удалось открыть. Скопируй URL сверху вручную."
fi

printf "\nВставь access_token: "
read -r ACCESS_TOKEN
ACCESS_TOKEN=$(echo "$ACCESS_TOKEN" | tr -d ' \n\r\t')

if [ -z "$ACCESS_TOKEN" ] || [ "${#ACCESS_TOKEN}" -lt 30 ]; then
    echo "ERROR: токен пустой или слишком короткий." >&2
    exit 1
fi

# Validate by login.yandex.ru/info
USER_INFO=$(curl -s -H "Authorization: OAuth $ACCESS_TOKEN" "https://login.yandex.ru/info?format=json" 2>/dev/null || echo "{}")
if ! echo "$USER_INFO" | grep -q '"login"'; then
    echo "ERROR: токен не прошёл валидацию." >&2
    echo "Ответ: $USER_INFO" >&2
    exit 1
fi
LOGIN=$(echo "$USER_INFO" | sed -n 's/.*"login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
USER_ID=$(echo "$USER_INFO" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

ISSUED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EXPIRES_AT=$(date -u -v +365d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+365 days" +"%Y-%m-%dT%H:%M:%SZ")

cat > "$TOKEN_FILE" <<EOF
{
  "access_token": "$ACCESS_TOKEN",
  "client_id": "$CLIENT_ID",
  "app_name": "$APP_NAME",
  "issued_at": "$ISSUED_AT",
  "expires_at_estimate": "$EXPIRES_AT",
  "yandex_login": "$LOGIN",
  "yandex_user_id": "$USER_ID",
  "note": "Direct API token. Use with Authorization: Bearer ..."
}
EOF
chmod 600 "$TOKEN_FILE"

cat <<EOF

✅ Direct OAuth готов.
   Аккаунт:  $LOGIN  (id=$USER_ID)
   Токен:    $TOKEN_FILE
   Права:    600

Проверь работу Direct API:
  bash direct-oauth-flow.sh --status
  bash probe.sh
EOF
