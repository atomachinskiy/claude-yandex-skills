#!/bin/sh
# probe.sh — check API availability for yandex-telemost under shared yandex-auth token.
# Reports HTTP status and shows activation steps if access is denied.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

URL="https://cloud-api.yandex.net/v1/telemost-api/conferences"
echo "→ Probing Yandex Telemost API"
echo "  URL: $URL"
echo ""

HTTP=$(curl -s -o /tmp/yandex-telemost-probe -w "%{http_code}" --max-time 10 \
    -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
    -H "Accept: application/json" \
    "$URL")

SAMPLE=$(head -c 200 /tmp/yandex-telemost-probe | tr '\n' ' ')

case "$HTTP" in
    200|2*) echo "✅ HTTP $HTTP — endpoint доступен"; echo "   sample: $SAMPLE" ;;
    401|403) echo "❌ HTTP $HTTP — access denied"; echo "   reply: $SAMPLE" ;;
    *)      echo "⚠️  HTTP $HTTP — endpoint вернул нестандартный код"; echo "   reply: $SAMPLE" ;;
esac

echo ""
echo "ℹ️  Активация: Telemost API доступен только пользователям Yandex 360 для бизнеса. У личного аккаунта будет 403 ApiRestrictedToOrganizations. Подписка: https://360.yandex.ru/business/. После — endpoints POST/GET /conferences заработают под общим токеном."
