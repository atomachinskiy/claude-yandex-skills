#!/bin/sh
# change-states.sh — history of changes (что менялось в кабинете когда).
# Direct API: POST /changes method=checkDictionaries / checkCampaigns / check
# Usage:
#   bash change-states.sh --since 2024-05-01T00:00:00Z
#   bash change-states.sh --campaign 12345 --since 2024-05-01T00:00:00Z

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

SINCE="2024-01-01T00:00:00Z"
CAMPAIGN_IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --since)    shift; SINCE="$1" ;;
        --campaign) shift; CAMPAIGN_IDS="$1" ;;
    esac
    shift
done

if [ -z "$CAMPAIGN_IDS" ]; then
    CAMPAIGN_IDS_LIST=$(get_all_campaign_ids)
    [ -z "$CAMPAIGN_IDS_LIST" ] && { echo "В кабинете нет кампаний."; exit 0; }
else
    CAMPAIGN_IDS_LIST="\"$CAMPAIGN_IDS\""
fi

BODY=$(cat <<EOF
{
  "method": "check",
  "params": {
    "CampaignIds": [$CAMPAIGN_IDS_LIST],
    "Timestamp": "$SINCE",
    "FieldNames": ["CampaignIds","AdGroupIds","AdIds"]
  }
}
EOF
)

RESP=$(direct_call changes "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result |
  "Timestamp:        \(.Timestamp // "-")\nИзменённые кампании: \(.Campaigns // [] | length)\nИзменённые группы:  \(.AdGroups // [] | length)\nИзменённые объявления: \(.Ads // [] | length)\nИзменённые ключевики: \(.Keywords // [] | length)\n\nIDs кампаний с изменениями: \((.Campaigns // [])[:20] | map(tostring) | join(", "))"
' 2>/dev/null || { echo "$RESP" | head -c 800; echo; }
