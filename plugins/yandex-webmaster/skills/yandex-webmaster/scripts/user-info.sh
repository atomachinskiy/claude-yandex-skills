#!/bin/sh
# user-info.sh — get current user_id (used by other scripts).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config
call GET /user/ | $JQ .
