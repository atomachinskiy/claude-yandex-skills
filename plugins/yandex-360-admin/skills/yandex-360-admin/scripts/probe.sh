#!/bin/sh
# probe.sh — check API availability for yandex-360-admin under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://api360.yandex.net/directory/v1/org/-/users"
echo "→ Probing Yandex 360 Admin API"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-360-admin-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-360-admin-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: 360 Admin требует scope 'directory:read' (или 'directory:full'). В OAuth-app 'Я-Клауд-Клиентс' добавить разрешение в кабинете oauth.yandex.ru. Также нужно знать org_id (получить через https://admin.yandex.ru или GET /directory/v1/org)."
