#!/bin/sh
# feeds.sh — product feeds for Smart Banners / Performance campaigns.
# Direct API: POST /feeds method=get
# Usage:
#   bash feeds.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

IDS_FILTER=""
while [ $# -gt 0 ]; do
    case "$1" in
        --id) shift; IDS_FILTER="\"$1\"," ;;
    esac
    shift
done

if [ -z "$IDS_FILTER" ]; then
    echo "ℹ️  API Директа требует явно указать --id <feed_id> для просмотра конкретного фида."
    echo "    Узнать ID можно в кабинете Директа: Библиотека → Фиды."
    echo "    Использование: bash feeds.sh --id 12345"
    exit 0
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { "Ids": [${IDS_FILTER%,}] },
    "FieldNames": ["Id","Name","BusinessType","SourceType","UrlFeed","FileFeed","UpdateStatus","UpdatedAt"]
  }
}
EOF
)

RESP=$(direct_call feeds "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.Feeds[]? // empty
  | "id=\(.Id) [\(.BusinessType)/\(.SourceType)]  \(.Name)\n  url=\(.UrlFeed.Url // "-")  status=\(.UpdateStatus)  updated=\(.UpdatedAt // "-")"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
