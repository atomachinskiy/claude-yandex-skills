#!/bin/sh
# bids.sh — view current bids per keyword and recommended values.
# Direct API: POST /bids method=get.
# Usage:
#   bash bids.sh --adgroup 67890
#   bash bids.sh --campaign 12345
#   bash bids.sh --keyword 999111

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_IDS=""
ADGROUP_IDS=""
KEYWORD_IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --campaign) shift; CAMPAIGN_IDS="\"CampaignIds\":[\"$1\"]," ;;
        --adgroup)  shift; ADGROUP_IDS="\"AdGroupIds\":[\"$1\"]," ;;
        --keyword)  shift; KEYWORD_IDS="\"KeywordIds\":[\"$1\"]," ;;
    esac
    shift
done

if [ -z "$CAMPAIGN_IDS" ] && [ -z "$ADGROUP_IDS" ] && [ -z "$KEYWORD_IDS" ]; then
    ALL_IDS=$(get_all_campaign_ids)
    [ -z "$ALL_IDS" ] && { echo "В кабинете нет кампаний."; exit 0; }
    CAMPAIGN_IDS="\"CampaignIds\":[$ALL_IDS],"
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${CAMPAIGN_IDS}${ADGROUP_IDS}${KEYWORD_IDS} },
    "FieldNames": ["KeywordId","AdGroupId","CampaignId","Bid","ContextBid","StrategyPriority","CompetitorsBids","AuctionBids"]
  }
}
EOF
)

RESP=$(direct_call bids "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.Bids[]? // empty
  | "kw=\(.KeywordId) ag=\(.AdGroupId) [\(.ServingStatus)]  current=\(.CurrentBids // [] | length) auction=\(.AuctionBids // [] | length) competitors=\(.CompetitorsBids // [] | length)"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }

echo ""
echo "ℹ️  Чтобы изменить ставки: direct_call bids '{\"method\":\"set\",\"params\":{\"Bids\":[{\"KeywordId\":\"<id>\",\"Bid\":<микросумма>}]}}'"
echo "   Bid в МИКРО-РУБЛЯХ (1 руб = 1000000)."
