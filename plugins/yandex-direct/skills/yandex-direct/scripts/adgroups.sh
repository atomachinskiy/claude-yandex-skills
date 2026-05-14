#!/bin/sh
# adgroups.sh — list ad groups.
# Usage:
#   bash adgroups.sh                          # все группы
#   bash adgroups.sh --campaign 12345         # группы кампании
#   bash adgroups.sh --state ON

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_IDS=""
STATES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --campaign) shift; CAMPAIGN_IDS="\"CampaignIds\":[\"$1\"]," ;;
        --state)    shift; STATES="\"States\":[\"$1\"]," ;;
    esac
    shift
done

if [ -z "$CAMPAIGN_IDS" ]; then
    ALL_IDS=$(get_all_campaign_ids)
    [ -z "$ALL_IDS" ] && { echo "В кабинете нет кампаний."; exit 0; }
    CAMPAIGN_IDS="\"CampaignIds\":[$ALL_IDS],"
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${CAMPAIGN_IDS}${STATES} },
    "FieldNames": ["Id","Name","CampaignId","Status","Type","RegionIds","TrackingParams"]
  }
}
EOF
)

RESP=$(direct_call adgroups "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.AdGroups[]? // empty
  | "id=\(.Id) cmp=\(.CampaignId) [\(.Status)/\(.Type)]  \(.Name)\n  regions: \(.RegionIds | join(","))"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
