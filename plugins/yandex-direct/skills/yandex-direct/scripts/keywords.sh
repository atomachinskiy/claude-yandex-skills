#!/bin/sh
# keywords.sh — list keywords with bids/statuses.
# Usage:
#   bash keywords.sh --adgroup 67890
#   bash keywords.sh --campaign 12345
#   bash keywords.sh --state ON --status ACCEPTED

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
    "FieldNames": ["Id","Keyword","AdGroupId","CampaignId","Status","State","Bid","ContextBid"]
  }
}
EOF
)

RESP=$(direct_call keywords "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.Keywords[]? // empty
  | "[\(.State)/\(.Status)] id=\(.Id) ag=\(.AdGroupId)  «\(.Keyword)»\n  search-bid=\(.Bid // 0)  rsya-bid=\(.ContextBid // 0)\(if .ProductivityInfo then "  productivity="+(.ProductivityInfo.Productivity|tostring) else "" end)"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
