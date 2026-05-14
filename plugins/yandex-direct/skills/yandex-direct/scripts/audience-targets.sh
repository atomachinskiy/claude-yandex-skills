#!/bin/sh
# audience-targets.sh — list retargeting / audience targets.
# Direct API: POST /audiencetargets method=get
# Usage:
#   bash audience-targets.sh
#   bash audience-targets.sh --adgroup 67890

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

ADGROUP_IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --adgroup) shift; ADGROUP_IDS="\"AdGroupIds\":[\"$1\"]," ;;
    esac
    shift
done

CAMPAIGN_IDS=""
if [ -z "$ADGROUP_IDS" ]; then
    ALL_IDS=$(get_all_campaign_ids)
    [ -z "$ALL_IDS" ] && { echo "В кабинете нет кампаний."; exit 0; }
    CAMPAIGN_IDS="\"CampaignIds\":[$ALL_IDS],"
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${CAMPAIGN_IDS}${ADGROUP_IDS} },
    "FieldNames": ["Id","RetargetingListId","InterestId","AdGroupId","CampaignId","State","ContextBid","StrategyPriority"]
  }
}
EOF
)

RESP=$(direct_call audiencetargets "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.AudienceTargets[]? // empty
  | "id=\(.Id) [\(.State)/\(.Status)] ag=\(.AdGroupId)\n  retargeting=\(.RetargetingListId // "-")  interest=\(.InterestId // "-")  rsya-bid=\(.ContextBid // 0)"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
