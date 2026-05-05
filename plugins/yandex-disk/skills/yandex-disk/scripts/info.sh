#!/bin/sh
# info.sh — show Yandex.Disk account info: usage, capacity, user.
# Usage: info.sh [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

OUTPUT_JSON=0
[ "$1" = "--json" ] && OUTPUT_JSON=1

DATA=$(call GET /)

if [ "$OUTPUT_JSON" -eq 1 ]; then
    echo "$DATA" | $JQ .
    exit 0
fi

USER=$(echo "$DATA" | $JQ -r '.user.login // "?"')
TOTAL_GB=$(echo "$DATA" | $JQ -r '.total_space' | awk '{printf "%.1f", $1/1024/1024/1024}')
USED_GB=$(echo "$DATA" | $JQ -r '.used_space' | awk '{printf "%.1f", $1/1024/1024/1024}')
TRASH_MB=$(echo "$DATA" | $JQ -r '.trash_size' | awk '{printf "%.1f", $1/1024/1024}')
PAID=$(echo "$DATA" | $JQ -r '.is_paid')

echo "# Yandex.Disk — $USER"
echo "Total:  ${TOTAL_GB} GB  (paid: $PAID)"
echo "Used:   ${USED_GB} GB"
echo "Trash:  ${TRASH_MB} MB"
