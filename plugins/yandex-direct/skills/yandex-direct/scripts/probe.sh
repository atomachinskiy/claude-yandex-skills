#!/bin/sh
# probe.sh — check API availability for yandex-direct under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://api.direct.yandex.com/json/v5/clients"
echo "→ Probing Yandex Direct API v5"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-direct-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-direct-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: Yandex Direct требует ОТДЕЛЬНОЕ OAuth-приложение зарегистрированное в кабинете Директа: https://direct.yandex.ru/registered/main.pl?cmd=showApiSettings → 'Получить API'. Заявка рассматривается до 7 дней. После одобрения создать ещё одно OAuth-app именно с типом 'Direct', получить отдельный токен. ОБЩИЙ токен от Я-Клауд-Клиентс не подходит для Direct."
