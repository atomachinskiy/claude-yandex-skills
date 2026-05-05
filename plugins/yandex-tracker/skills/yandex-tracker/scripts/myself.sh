#!/bin/sh
# myself.sh — info about the current user in Tracker.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config
tracker_call GET /myself | $JQ .
