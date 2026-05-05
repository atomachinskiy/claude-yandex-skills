#!/bin/sh
# list-hosts.sh — list all sites added to Webmaster for the current user.
# Usage: list-hosts.sh [--json]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

USER_ID=$(call GET /user/ | $JQ -r '.user_id')
DATA=$(call GET "/user/$USER_ID/hosts/")

if [ "$1" = "--json" ]; then echo "$DATA" | $JQ .; exit 0; fi

N=$(echo "$DATA" | $JQ -r '.hosts | length')
{
    echo "# Webmaster — $N hosts (user $USER_ID)"
    echo ""
    echo "$DATA" | $JQ -r '.hosts[] | "\(.host_id)|\(.unicode_host_url)|\(.verified)|\(.main_mirror.host_id // "-")"' | \
        awk -F'|' '{ printf "%-35s %-40s verified=%-5s main_mirror=%s\n", $1, $2, $3, $4 }'
} | limit_output
