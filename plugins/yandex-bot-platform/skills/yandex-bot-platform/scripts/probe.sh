#!/bin/sh
# probe.sh — check API availability for yandex-bot-platform under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://dialogs.yandex.ru/api/v1/skills"
echo "→ Probing Yandex Dialogs (Алиса) API"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-bot-platform-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-bot-platform-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: Dialogs API доступен через Developer Console (https://dialogs.yandex.ru/developer/), требует scope 'dialogs:bot'. У бота должен быть свой dev-аккаунт. Под общим OAuth-токеном базовые endpoints работают, но для управления конкретными навыками нужно их предварительно создать в консоли разработчика."
