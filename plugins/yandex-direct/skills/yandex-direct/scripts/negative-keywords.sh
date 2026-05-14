#!/bin/sh
# negative-keywords.sh — account-level shared sets of negative keywords.
# Direct API: POST /negativekeywordsharedsets
# Usage:
#   bash negative-keywords.sh                        # все наборы минус-слов
#   bash negative-keywords.sh --id 12345             # конкретный набор

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

IDS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --id) shift; IDS="\"$1\"," ;;
    esac
    shift
done

if [ -z "$IDS" ]; then
    echo "ℹ️  API требует явно указать --id <set_id>."
    echo "    Использование: bash negative-keywords.sh --id 12345"
    echo "    Узнать ID можно в кабинете Директа: Библиотека → Списки минус-фраз."
    exit 0
fi

BODY=$(cat <<EOF
{
  "method": "get",
  "params": {
    "SelectionCriteria": { "Ids": [${IDS%,}] },
    "FieldNames": ["Id","Name","NegativeKeywords"]
  }
}
EOF
)

RESP=$(direct_call negativekeywordsharedsets "$BODY")
if echo "$RESP" | grep -q '"error"'; then
    echo "$RESP" | jq . 2>/dev/null || echo "$RESP"
    exit 1
fi

echo "$RESP" | jq -r '
  .result.NegativeKeywordSharedSets[]? // empty
  | "id=\(.Id)  \(.Name)\n  ключевых слов в наборе: \(.NegativeKeywords.Items | length)\n  \(.NegativeKeywords.Items | join("  ·  "))"
' 2>/dev/null | limit_output || { echo "$RESP" | head -c 800; echo; }
