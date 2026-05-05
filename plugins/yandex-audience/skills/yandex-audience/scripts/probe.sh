#!/bin/sh
# probe.sh — check API availability for yandex-audience under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://api-audience.yandex.ru/v1/management/client/segments"
echo "→ Probing Yandex Audience"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-audience-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-audience-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: Audience использует scope 'audience:use'. Если 403 — в OAuth-app кабинете 'Я-Клауд-Клиентс' добавить разрешение на Аудитории, перевыпустить токен через yandex-auth/oauth-flow.sh."
