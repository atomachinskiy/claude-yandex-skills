#!/bin/sh
# list-surveys.sh — list user's Yandex Forms surveys.
# ⚠️ Yandex Forms public API is currently limited / undocumented.
# This script tries multiple known endpoints and reports which (if any) responds.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

echo "→ Probing Yandex Forms API endpoints under your token..."

for url in \
    "https://forms.yandex.ru/api/v2/surveys/" \
    "https://forms.yandex.ru/api/v1/surveys/" \
    "https://api.forms.yandex.net/v1/surveys"
do
    HTTP=$(curl -s -o /tmp/forms-probe -w "%{http_code}" \
        -H "Authorization: OAuth $YANDEX_ACCESS_TOKEN" \
        -H "Accept: application/json" \
        "$url")
    SIZE=$(stat -f %z /tmp/forms-probe 2>/dev/null || stat -c %s /tmp/forms-probe)
    FIRST=$(head -c 60 /tmp/forms-probe | tr '\n' ' ')
    echo "  $url → HTTP $HTTP, ${SIZE}B"
    echo "     first 60: $FIRST"
done

echo ""
echo "ℹ️  Yandex Forms не имеет полностью публичного REST API на 2026."
echo "    Возможные пути работы с формами:"
echo "    1. Webhook: настроить в форме URL для пересылки ответов на сторонний сервер."
echo "    2. Интеграция с Yandex.Tracker: ответы автоматически создают тикеты."
echo "    3. Экспорт в Яндекс.Таблицы (через интеграцию формы) → читать через CalDAV/Sheets."
echo "    4. Yandex 360 для бизнеса — там может быть admin API (через api360.yandex.net)."
