#!/bin/sh
# bid-modifiers.sh — bid corrections (gender/age, devices, regions, retargeting).
# Direct API: POST /bidmodifiers method=get
# Usage:
#   bash bid-modifiers.sh --campaign 12345
#   bash bid-modifiers.sh --adgroup 67890

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_IDS=""
ADGROUP_IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --campaign) shift; CAMPAIGN_IDS="\"CampaignIds\":[\"$1\"]," ;;
        --adgroup)  shift; ADGROUP_IDS="\"AdGroupIds\":[\"$1\"]," ;;
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
    "SelectionCriteria": { ${CAMPAIGN_IDS}${ADGROUP_IDS} "Levels": ["CAMPAIGN","AD_GROUP"] },
    "FieldNames": ["Id","CampaignId","AdGroupId","Level","Type"],
    "MobileAdjustmentFieldNames": ["BidModifier"],
    "DesktopAdjustmentFieldNames": ["BidModifier"],
    "DemographicsAdjustmentFieldNames": ["Age","Gender","BidModifier"],
    "RegionalAdjustmentFieldNames": ["RegionId","BidModifier"],
    "RetargetingAdjustmentFieldNames": ["RetargetingConditionId","BidModifier"]
  }
}
EOF
)

RESP=$(direct_call bidmodifiers "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.BidModifiers[]? // empty
  | "id=\(.Id) cmp=\(.CampaignId) ag=\(.AdGroupId // "-") [\(.Level)/\(.Type)]\n  mobile=\(.MobileAdjustment.BidModifier // "-")  desktop=\(.DesktopAdjustment.BidModifier // "-")"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
