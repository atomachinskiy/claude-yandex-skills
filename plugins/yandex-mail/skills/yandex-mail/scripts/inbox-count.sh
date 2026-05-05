#!/bin/sh
# inbox-count.sh — show count of messages in INBOX (total + unread).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

case "$YANDEX_LOGIN" in *@*) EMAIL="$YANDEX_LOGIN" ;; *) EMAIL="${YANDEX_LOGIN}@yandex.ru" ;; esac

python3 - <<PY
import imaplib, base64, sys
email = "$EMAIL"
token = "$YANDEX_ACCESS_TOKEN"
auth_b64 = base64.b64encode(f"user={email}\x01auth=Bearer {token}\x01\x01".encode()).decode()
try:
    M = imaplib.IMAP4_SSL("imap.yandex.ru", 993)
    M.authenticate("XOAUTH2", lambda x: auth_b64.encode())
    typ, total = M.select("INBOX", readonly=True)
    typ, unread = M.search(None, "UNSEEN")
    total_n = int(total[0]) if typ == "OK" else "?"
    unread_n = len(unread[0].split()) if typ == "OK" else "?"
    print(f"INBOX ({email})")
    print(f"  Total:  {total_n}")
    print(f"  Unread: {unread_n}")
    M.logout()
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PY
