#!/bin/sh
# list-folders.sh — list IMAP folders in the user's Yandex mailbox.
# Yandex IMAP uses XOAUTH2 with the OAuth token from yandex-auth (no separate password needed).
# Requires Python 3 with imaplib (stdlib).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

case "$YANDEX_LOGIN" in *@*) EMAIL="$YANDEX_LOGIN" ;; *) EMAIL="${YANDEX_LOGIN}@yandex.ru" ;; esac

python3 - <<PY
import imaplib, base64, sys

email = "$EMAIL"
token = "$YANDEX_ACCESS_TOKEN"

auth_string = f"user={email}\x01auth=Bearer {token}\x01\x01"
auth_b64 = base64.b64encode(auth_string.encode()).decode()

try:
    M = imaplib.IMAP4_SSL("imap.yandex.ru", 993)
    M.authenticate("XOAUTH2", lambda x: auth_b64.encode())
    typ, data = M.list()
    if typ != "OK":
        print(f"LIST failed: {data}", file=sys.stderr)
        sys.exit(1)
    print(f"# IMAP folders for {email}")
    print()
    for line in data:
        s = line.decode(errors='replace')
        # parse "(\HasNoChildren) "/" "INBOX""
        import re
        m = re.match(r'\((.*?)\) "(.+?)" "?(.+?)"?$', s)
        if m:
            flags, sep, name = m.groups()
            print(f"  {name}")
        else:
            print(f"  {s}")
    M.logout()
except imaplib.IMAP4.error as e:
    print(f"IMAP error: {e}", file=sys.stderr)
    print("Hint: ensure mail:imap_full scope is in your OAuth app and token re-issued.", file=sys.stderr)
    sys.exit(1)
PY
