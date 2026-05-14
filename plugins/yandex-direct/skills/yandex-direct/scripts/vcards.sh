#!/bin/sh
# vcards.sh — virtual business cards (контактные данные для объявлений).
# Direct API: POST /vcards method=get
# Usage:
#   bash vcards.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

IDS=$(get_referenced_ids VCardId)
if [ -z "$IDS" ]; then
    echo "Виртуальных визиток в аккаунте не найдено (нет ссылок из объявлений)."
    exit 0
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { "Ids": [$IDS] },
    "FieldNames": ["Id","CampaignId","CompanyName","City","Street","House","Phone","Email","WorkTime","ExtraMessage"]
  }
}
EOF
)

RESP=$(direct_call vcards "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.VCards[]? // empty
  | "id=\(.Id) cmp=\(.CampaignId)\n  \(.CompanyName)\n  \(.City), \(.Street) \(.House)\n  тел: \(.Phone.CountryCode // "")\(.Phone.CityCode // "") \(.Phone.PhoneNumber // "")\n  email: \(.Email // "-")\n  часы: \(.WorkTime // "-")"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
