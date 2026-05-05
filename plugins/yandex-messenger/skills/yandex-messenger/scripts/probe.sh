#!/bin/sh
# probe.sh — check API availability for yandex-messenger under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://botapi.messenger.yandex.net/bot/v1/me"
echo "→ Probing Yandex Messenger Bot API"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-messenger-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-messenger-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: Messenger Bot API использует ОТДЕЛЬНЫЙ bot-токен (НЕ OAuth). Создание бота: https://yandex.ru/support/messenger/services/bots.html → создать бота через @MetaBot → получить bot_token. Сохранить в config/.env как YANDEX_MESSENGER_BOT_TOKEN, скилл будет использовать его вместо общего токена."
