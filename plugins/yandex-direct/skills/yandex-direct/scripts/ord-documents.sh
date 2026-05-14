#!/bin/sh
# ord-documents.sh — ОРД РКН: erid-метки рекламы.
# Direct API: POST /adextensions OR /campaigns с PrescriptionForGetCampaignDocuments
# Actually Direct dedicated: POST /audit method=hasObjects + ORD-specific endpoints.
# Здесь использую /clients с расширением для просмотра текущих ОРД-настроек кампаний.
#
# Usage:
#   bash ord-documents.sh                         # ОРД-статус всех активных кампаний
#   bash ord-documents.sh --campaign 12345        # для одной кампании

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --campaign) shift; CAMPAIGN_IDS="\"Ids\":[\"$1\"]," ;;
    esac
    shift
done

# Direct stores ORD info in campaign settings: TextCampaign.Settings → SocialDemo + ORD blocks
BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${CAMPAIGN_IDS} },
    "FieldNames": ["Id","Name","Type","State","Status"],
    "TextCampaignFieldNames": ["Settings","CounterIds"]
  }
}
EOF
)

RESP=$(direct_call campaigns "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.Campaigns[]? // empty
  | "id=\(.Id) [\(.State)/\(.Status)]  \(.Name)\n  ORD-настройки: \(if .TextCampaign.Settings then ((.TextCampaign.Settings // []) | map(select(.Option == "ENABLE_AREA_OF_INTEREST_TARGETING" or .Option == "MAINTAIN_NETWORK_CPC")) | length | tostring + " опций") else "стандарт" end)"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }

echo ""
echo "ℹ️  Полная ОРД-маркировка erid + token (РКН) проходит через сторонний ОРД-оператор (например ВымпелКом OneCommerce), а не через сам Direct API."
echo "   В Direct хранятся только counter_ids счётчиков Метрики и настройки SocialDemo для разметки целевых аудиторий."
