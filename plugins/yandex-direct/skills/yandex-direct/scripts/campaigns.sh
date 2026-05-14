#!/bin/sh
# campaigns.sh — list Direct campaigns of the authenticated account.
# Usage:
#   bash campaigns.sh                 # all campaigns
#   bash campaigns.sh --state ON      # only active
#   bash campaigns.sh --type TEXT_CAMPAIGN

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

STATES=""
TYPES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --state) shift; STATES="\"States\":[\"$1\"]," ;;
        --type)  shift; TYPES="\"Types\":[\"$1\"]," ;;
    esac
    shift
done

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { ${STATES}${TYPES} },
    "FieldNames": ["Id","Name","Type","Status","State","DailyBudget","StartDate"]
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
  .result.Campaigns[]
  | "[\(.State)/\(.Status)]  \(.Id)  \(.Name)  (\(.Type), start=\(.StartDate // "-"))"
' 2>/dev/null | limit_output \
    || { echo "$RESP" | head -c 600; echo; }
