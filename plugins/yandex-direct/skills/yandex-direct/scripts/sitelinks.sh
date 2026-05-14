#!/bin/sh
# sitelinks.sh — sitelink sets (быстрые ссылки в объявлениях).
# Direct API: POST /sitelinks method=get
# Usage:
#   bash sitelinks.sh
#   bash sitelinks.sh --id 12345

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

IDS_FILTER=""
while [ $# -gt 0 ]; do
    case "$1" in
        --id) shift; IDS_FILTER="\"$1\"" ;;
    esac
    shift
done

if [ -z "$IDS_FILTER" ]; then
    IDS_FILTER=$(get_referenced_ids SitelinkSetId)
    if [ -z "$IDS_FILTER" ]; then
        echo "Наборов быстрых ссылок не найдено."
        exit 0
    fi
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { "Ids": [$IDS_FILTER] },
    "FieldNames": ["Id","Sitelinks"]
  }
}
EOF
)

RESP=$(direct_call sitelinks "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.SitelinksSets[]? // empty
  | "набор id=\(.Id) (\(.Sitelinks | length) ссылок):\n" + (
      [.Sitelinks[]? | "  • \(.Title)  →  \(.Href)\(if .Description then "\n    "+.Description else "" end)"] | join("\n")
    )
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
