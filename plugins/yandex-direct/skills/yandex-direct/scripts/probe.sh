#!/bin/sh
# probe.sh — check Yandex Direct API availability with dedicated Direct token.
# Direct API v5: POST + Authorization: Bearer (not OAuth).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"
load_config

echo "→ Probing Yandex Direct API v5 (/clients)"
echo "  Token user: $YANDEX_DIRECT_LOGIN"
echo ""

RESP=$(direct_call clients '{"method":"get","params":{"FieldNames":["ClientId","Login","Currency","Type"]}}')

if echo "$RESP" | grep -q '"error"'; then
    ERR_CODE=$(echo "$RESP" | sed -n 's/.*"error_code"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)
    ERR_STR=$(echo "$RESP" | sed -n 's/.*"error_string"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    ERR_DET=$(echo "$RESP" | sed -n 's/.*"error_detail"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    echo "❌ API error_code=$ERR_CODE — $ERR_STR"
    echo "   $ERR_DET"
    case "$ERR_CODE" in
        58)
            echo ""
            echo "ℹ️  error_code 58 = заявка на доступ не одобрена для этого OAuth-app."
            echo "   Проверь в кабинете Директа → Настройки API → 'Заявки на API'." ;;
        53|54)
            echo ""
            echo "ℹ️  Токен невалиден или истёк. Перевыпусти:"
            echo "   bash $SCRIPT_DIR/direct-oauth-flow.sh" ;;
        8000)
            echo ""
            echo "ℹ️  OAuth token missing — токен не передаётся правильно. Проверь $DIRECT_TOKEN_FILE" ;;
    esac
    exit 1
fi

echo "✅ Direct API доступен"
echo ""
echo "Список клиентов:"
echo "$RESP" | jq -r '.result.Clients[] | "  - \(.Login)  (id=\(.ClientId), currency=\(.Currency), type=\(.Type))"' 2>/dev/null \
    || echo "$RESP" | head -c 500
