#!/bin/sh
# report.sh — fetch a CUSTOM_REPORT for a campaign.
# Direct Reports API: async — Direct returns 201 then we poll until 200.
# Usage:
#   bash report.sh <campaign_id> [--from YYYY-MM-DD] [--to YYYY-MM-DD]
# Default: LAST_30_DAYS.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

CAMPAIGN_ID="$1"
shift 2>/dev/null
DATE_FROM=""
DATE_TO=""
while [ $# -gt 0 ]; do
    case "$1" in
        --from) shift; DATE_FROM="$1" ;;
        --to)   shift; DATE_TO="$1" ;;
    esac
    shift
done

if [ -z "$CAMPAIGN_ID" ]; then
    echo "Usage: bash report.sh <campaign_id> [--from YYYY-MM-DD] [--to YYYY-MM-DD]" >&2
    exit 2
fi

if [ -n "$DATE_FROM" ] && [ -n "$DATE_TO" ]; then
    DATE_RANGE_TYPE="CUSTOM_DATE"
    DATE_BLOCK="\"DateFrom\":\"$DATE_FROM\",\"DateTo\":\"$DATE_TO\","
else
    DATE_RANGE_TYPE="LAST_30_DAYS"
    DATE_BLOCK=""
fi

REPORT_NAME="report-$CAMPAIGN_ID-$(date +%s)"

BODY=$(cat <<EOF
{
  "params": {
    "SelectionCriteria": {
      "Filter": [{ "Field": "CampaignId", "Operator": "EQUALS", "Values": ["$CAMPAIGN_ID"] }]
    },
    "FieldNames": ["Date","Impressions","Clicks","Cost","Ctr","AvgCpc","Conversions"],
    "ReportName": "$REPORT_NAME",
    "ReportType": "CUSTOM_REPORT",
    "DateRangeType": "$DATE_RANGE_TYPE",
    $DATE_BLOCK
    "Format": "TSV",
    "IncludeVAT": "YES",
    "IncludeDiscount": "NO"
  }
}
EOF
)

# Reports endpoint is /v5/reports (not /v5/<resource>).
URL="https://api.direct.yandex.com/json/v5/reports"

echo "→ Запрашиваю отчёт по кампании $CAMPAIGN_ID..."

# Direct Reports: async via skipReportHeader=true, returnMoneyInMicros=false.
# Poll loop: 200 = ready, 201 = queued, 202 = in progress.
while true; do
    HTTP_AND_BODY=$(curl -s -w "\n___HTTP:%{http_code}___" --max-time 60 -X POST \
        -H "$(auth_header)" \
        -H "Accept-Language: ru" \
        -H "Content-Type: application/json; charset=utf-8" \
        -H "skipReportHeader: true" \
        -H "returnMoneyInMicros: false" \
        -H "processingMode: auto" \
        -d "$BODY" \
        "$URL")
    HTTP=$(echo "$HTTP_AND_BODY" | sed -n 's/.*___HTTP:\([0-9]*\)___.*/\1/p')
    REPORT_BODY=$(echo "$HTTP_AND_BODY" | sed 's/\n___HTTP:[0-9]*___$//')
    case "$HTTP" in
        200) break ;;
        201|202)
            RETRY=$(echo "$HTTP_AND_BODY" | sed -n 's/.*"retryIn"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
            RETRY="${RETRY:-5}"
            echo "  status $HTTP — отчёт готовится, жду ${RETRY}s..."
            sleep "$RETRY"
            ;;
        *)
            echo "❌ HTTP $HTTP"
            echo "$REPORT_BODY" | head -c 500
            exit 1
            ;;
    esac
done

echo ""
echo "✅ Отчёт готов:"
echo "$REPORT_BODY"
