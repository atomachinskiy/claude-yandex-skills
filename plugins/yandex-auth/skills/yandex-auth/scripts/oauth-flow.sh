#!/bin/sh
# oauth-flow.sh — guide the user through one Yandex OAuth flow,
# capture access_token, persist to ~/.claude/secrets/yandex-app.json.
# Re-running is safe: overwrites the file.
#
# Usage:
#   bash oauth-flow.sh                      # interactive: choose browser
#   bash oauth-flow.sh --browser <name>     # auto-pick browser, no prompt
#   bash oauth-flow.sh --browser none       # don't auto-open, just print URL
#   bash oauth-flow.sh --status             # show current token + live-check
#
# Supported --browser values:
#   yandex   — Yandex Browser  (recommended; usually already logged into Yandex)
#   chrome   — Google Chrome
#   firefox  — Firefox
#   safari   — Safari (macOS only)
#   edge     — Microsoft Edge
#   default  — system default browser
#   none     — print URL only, user opens manually

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

CLIENT_ID="${YANDEX_CLIENT_ID:-2f69a4396d684385a5f6578dd5eb7863}"
SECRETS_DIR="$HOME/.claude/secrets"
TOKEN_FILE="$SECRETS_DIR/yandex-app.json"
AUTHORIZE_URL="https://oauth.yandex.ru/authorize?response_type=token&force_confirm=yes&client_id=${CLIENT_ID}"

# ── Argument parsing ─────────────────────────────────────────────
BROWSER_CHOICE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --status) yandex_auth_status; exit 0 ;;
        --browser)
            shift
            BROWSER_CHOICE="$1"
            ;;
        --browser=*) BROWSER_CHOICE="${1#--browser=}" ;;
        -h|--help)
            sed -n 's/^# \{0,1\}//;s/^#//p;/^$/q' "$0" | head -25
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

# ── Detect platform once ─────────────────────────────────────────
case "$(uname -s 2>/dev/null || echo Unknown)" in
    Darwin*)  PLATFORM="macos" ;;
    Linux*)   PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)        PLATFORM="unknown" ;;
esac

# ── open_in_browser <choice> <url> ───────────────────────────────
# Returns 0 on success, 1 if browser is unavailable or unsupported.
open_in_browser() {
    _ob_choice="$1"
    _ob_url="$2"
    case "$_ob_choice" in
        none) return 1 ;;
        default)
            case "$PLATFORM" in
                macos)   open "$_ob_url" 2>/dev/null && return 0 ;;
                linux)   xdg-open "$_ob_url" >/dev/null 2>&1 && return 0 ;;
                windows) cmd.exe /c start "" "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1
            ;;
        yandex)
            case "$PLATFORM" in
                macos)
                    # In macOS the app is registered as "Yandex"
                    open -a "Yandex" "$_ob_url" 2>/dev/null && return 0
                    open -a "Yandex Browser" "$_ob_url" 2>/dev/null && return 0
                    ;;
                linux)
                    for cmd in yandex-browser yandex-browser-stable yandex-browser-beta browser; do
                        command -v "$cmd" >/dev/null 2>&1 && { "$cmd" "$_ob_url" >/dev/null 2>&1 & return 0; }
                    done
                    ;;
                windows)
                    # Windows-Yandex installs to %LocalAppData%\Yandex\YandexBrowser\Application\browser.exe
                    _yb="$LOCALAPPDATA/Yandex/YandexBrowser/Application/browser.exe"
                    [ -f "$_yb" ] && cmd.exe /c start "" "$_yb" "$_ob_url" >/dev/null 2>&1 && return 0
                    ;;
            esac
            return 1
            ;;
        chrome)
            case "$PLATFORM" in
                macos)   open -a "Google Chrome" "$_ob_url" 2>/dev/null && return 0 ;;
                linux)
                    for cmd in google-chrome google-chrome-stable chromium chromium-browser; do
                        command -v "$cmd" >/dev/null 2>&1 && { "$cmd" "$_ob_url" >/dev/null 2>&1 & return 0; }
                    done
                    ;;
                windows)
                    cmd.exe /c start chrome "$_ob_url" >/dev/null 2>&1 && return 0
                    ;;
            esac
            return 1
            ;;
        firefox)
            case "$PLATFORM" in
                macos)   open -a "Firefox" "$_ob_url" 2>/dev/null && return 0 ;;
                linux)   command -v firefox >/dev/null 2>&1 && { firefox "$_ob_url" >/dev/null 2>&1 & return 0; } ;;
                windows) cmd.exe /c start firefox "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1
            ;;
        safari)
            [ "$PLATFORM" = "macos" ] && open -a "Safari" "$_ob_url" 2>/dev/null && return 0
            return 1
            ;;
        edge)
            case "$PLATFORM" in
                macos)   open -a "Microsoft Edge" "$_ob_url" 2>/dev/null && return 0 ;;
                linux)   command -v microsoft-edge >/dev/null 2>&1 && { microsoft-edge "$_ob_url" >/dev/null 2>&1 & return 0; } ;;
                windows) cmd.exe /c start msedge "$_ob_url" >/dev/null 2>&1 && return 0 ;;
            esac
            return 1
            ;;
        *) return 1 ;;
    esac
}

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

cat <<EOF
══════════════════════════════════════════════════════════
  Yandex OAuth — выпуск единого токена для всех скиллов
══════════════════════════════════════════════════════════

Платформа: $PLATFORM

Что нужно сделать:
  1. Залогиниться под нужным Яндекс-аккаунтом (тот, под которым
     должен работать твой Claude — личный или рабочий).
  2. Нажать «Разрешить».
  3. Тебя перекинет на oauth.yandex.ru/verification_code (пустая
     страница), токен будет в адресной строке.
  4. Скопировать ВСЁ что между "access_token=" и "&token_type".
  5. Вставить сюда и нажать Enter.

Authorize URL:
$AUTHORIZE_URL

EOF

# ── Browser selection ────────────────────────────────────────────
if [ -z "$BROWSER_CHOICE" ]; then
    cat <<EOF
В каком браузере открыть? Подсказка: Yandex Browser обычно уже залогинен
в твоём Яндекс-аккаунте — там быстрее всего пройти OAuth.

  [1] Yandex Browser   (рекомендую, если стоит)
  [2] Google Chrome
  [3] Firefox
  [4] Системный по умолчанию
  [5] Не открывать — я скопирую URL сам

EOF
    printf "Выбор [1-5, Enter = 1]: "
    read -r _choice
    case "${_choice:-1}" in
        1) BROWSER_CHOICE=yandex ;;
        2) BROWSER_CHOICE=chrome ;;
        3) BROWSER_CHOICE=firefox ;;
        4) BROWSER_CHOICE=default ;;
        5) BROWSER_CHOICE=none ;;
        *) BROWSER_CHOICE=yandex ;;
    esac
fi

if [ "$BROWSER_CHOICE" = "none" ]; then
    echo "→ Не открываю браузер. Скопируй authorize URL сверху и открой сам."
elif open_in_browser "$BROWSER_CHOICE" "$AUTHORIZE_URL"; then
    echo "→ Открыл authorize-URL в '$BROWSER_CHOICE'."
else
    echo "→ Не получилось открыть в '$BROWSER_CHOICE' (не найден или платформа не поддерживается)."
    echo "  Открой URL вручную из текста выше."
fi

printf "\nВставь access_token: "
read -r ACCESS_TOKEN

ACCESS_TOKEN=$(echo "$ACCESS_TOKEN" | tr -d ' \n\r\t')
if [ -z "$ACCESS_TOKEN" ] || [ "${#ACCESS_TOKEN}" -lt 30 ]; then
    echo "ERROR: токен слишком короткий или пустой. Прерываю." >&2
    exit 1
fi

# Verify the token by calling login.yandex.ru
USER_INFO=$(curl -s -H "Authorization: OAuth $ACCESS_TOKEN" \
    "https://login.yandex.ru/info?format=json" 2>/dev/null || echo "{}")

if echo "$USER_INFO" | grep -q '"login"'; then
    LOGIN=$(echo "$USER_INFO" | sed -n 's/.*"login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    USER_ID=$(echo "$USER_INFO" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
else
    echo "ERROR: токен не прошёл валидацию через login.yandex.ru/info." >&2
    echo "Ответ: $USER_INFO" >&2
    exit 1
fi

ISSUED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Yandex implicit-flow tokens live ~1 year by default; we don't get expires_in here.
# Mark expires_at conservatively as 365 days from now.
EXPIRES_AT=$(date -u -v +365d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+365 days" +"%Y-%m-%dT%H:%M:%SZ")

cat > "$TOKEN_FILE" <<EOF
{
  "access_token": "$ACCESS_TOKEN",
  "client_id": "$CLIENT_ID",
  "issued_at": "$ISSUED_AT",
  "expires_at_estimate": "$EXPIRES_AT",
  "yandex_login": "$LOGIN",
  "yandex_user_id": "$USER_ID",
  "note": "Issued via implicit-flow. Real expiry not returned by Yandex; estimate is +365d. If a request returns 401 — re-run oauth-flow.sh."
}
EOF
chmod 600 "$TOKEN_FILE"

cat <<EOF

✅ Готово.
   Аккаунт:     $LOGIN  (id=$USER_ID)
   Токен:       $TOKEN_FILE
   Файл создан, права 600.

Все плагины yandex-* теперь читают токен отсюда автоматически.
Проверка: bash oauth-flow.sh --status
EOF
