#!/bin/sh
# ads.sh — list ads in the account.
# Usage:
#   bash ads.sh                                  # все
#   bash ads.sh --campaign 12345                 # объявления конкретной кампании
#   bash ads.sh --adgroup 67890                  # объявления конкретной группы
#   bash ads.sh --state ON --status ACCEPTED

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_IDS=""
ADGROUP_IDS=""
STATES=""
STATUSES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --campaign) shift; CAMPAIGN_IDS="\"CampaignIds\":[\"$1\"]," ;;
        --adgroup)  shift; ADGROUP_IDS="\"AdGroupIds\":[\"$1\"]," ;;
        --state)    shift; STATES="\"States\":[\"$1\"]," ;;
        --status)   shift; STATUSES="\"Statuses\":[\"$1\"]," ;;
    esac
    shift
done

# Direct требует хотя бы один из Ids/AdGroupIds/CampaignIds. Если ничего не задано — берём все кампании.
if [ -z "$CAMPAIGN_IDS" ] && [ -z "$ADGROUP_IDS" ]; then
    ALL_IDS=$(get_all_campaign_ids)
    [ -z "$ALL_IDS" ] && { echo "В кабинете нет кампаний."; exit 0; }
    CAMPAIGN_IDS="\"CampaignIds\":[$ALL_IDS],"
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${CAMPAIGN_IDS}${ADGROUP_IDS}${STATES}${STATUSES} },
    "FieldNames": ["Id","CampaignId","AdGroupId","Status","State","Type","Subtype"],
    "TextAdFieldNames": ["Title","Title2","Text","Href","DisplayDomain","VCardId","Mobile","SitelinkSetId"]
  }
}
EOF
)

RESP=$(direct_call ads "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.Ads[]? // empty
  | "[\(.State)/\(.Status)] id=\(.Id) cmp=\(.CampaignId) ag=\(.AdGroupId) \(.Type)\n  → \(.TextAd.Title // .Type)\(if .TextAd.Title2 then " | "+.TextAd.Title2 else "" end)\n    \(.TextAd.Text // "")\n    \(.TextAd.DisplayDomain // "")  →  \(.TextAd.Href // "")"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
