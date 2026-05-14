#!/bin/sh
# forecast.sh — keyword traffic forecast.
# Direct API: POST /keywordsresearch method=hasSearchVolume (квоты на день) или
# legacy /forecast. Здесь используем keywordsresearch как современный путь.
#
# Usage:
#   bash forecast.sh "купить ботинки" "ремонт ноутбука"        # фразы через аргументы
#   bash forecast.sh --region 213 "доставка цветов"            # с регионом (Москва=213)
#   bash forecast.sh --device DESKTOP "адвокат екатеринбург"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

REGION="225"   # Россия по умолчанию
DEVICE="ALL"
PHRASES=""

while [ $# -gt 0 ]; do
    case "$1" in
        --region) shift; REGION="$1" ;;
        --device) shift; DEVICE="$1" ;;
        *)
            ESCAPED=$(echo "$1" | sed 's/"/\\"/g')
            if [ -z "$PHRASES" ]; then
                PHRASES="\"$ESCAPED\""
            else
                PHRASES="$PHRASES,\"$ESCAPED\""
            fi
            ;;
    esac
    shift
done

if [ -z "$PHRASES" ]; then
    echo "Usage: bash forecast.sh [--region <region_id>] [--device DESKTOP|MOBILE|ALL] \"<phrase>\" [\"<phrase>\"...]" >&2
    exit 2
fi

BODY=$(cat <<EOF
{
  "method": "hasSearchVolume",
  "params": {
    "SelectionCriteria": {
      "Keywords": [$PHRASES],
      "RegionIds": [$REGION]
    },
    "FieldNames": ["Keyword","AllDevices","MobilePhones","Tablets","Desktops"]
  }
}
EOF
)

echo "→ Запрашиваю прогноз показов..."
RESP=$(direct_call keywordsresearch "$BODY")

if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo ""
echo "$RESP" | jq -r '
  .result.HasSearchVolumeResults[]? // empty
  | "  «\(.Keyword)»\n    все устройства: \(.AllDevices // "NO")  моб: \(.MobilePhones // "?")  десктоп: \(.Desktops // "?")  планшеты: \(.Tablets // "?")"
' 2>/dev/null || { echo "$RESP" | head -c 800; echo; }

echo ""
echo "ℹ️  Для полного прогноза цены и трафика — используй keywordsresearch с method=deductGoals или /forecast с CreateNewForecast (квота 10 прогнозов/день)."
