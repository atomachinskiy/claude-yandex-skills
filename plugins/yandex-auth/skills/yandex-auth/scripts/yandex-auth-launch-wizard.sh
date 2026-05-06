#!/usr/bin/env bash
# yandex-auth-launch-wizard.sh — открывает отдельное окно терминала с подгруженной
# командой oauth-flow.sh. AI-ассистент (Claude Code) запускает этот скрипт через Bash tool
# у пользователя — у него САМО открывается окно Terminal/PowerShell, в котором мастер
# спрашивает выбор браузера, открывает Yandex OAuth, ловит access_token. AI токен не видит.
#
# Cross-platform: macOS / Linux / WSL / Git Bash на Windows.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WIZARD="$SCRIPT_DIR/oauth-flow.sh"

[ -f "$WIZARD" ] || { echo "❌ Не найден $WIZARD"; exit 1; }

OS="$(uname -s 2>/dev/null || echo unknown)"

case "$OS" in
  Darwin)
    ESCAPED_PATH="${WIZARD//\"/\\\"}"
    /usr/bin/osascript <<EOF
tell application "Terminal"
    activate
    do script "bash \"$ESCAPED_PATH\""
end tell
EOF
    echo "✅ Открыл Terminal.app с мастером авторизации Yandex. Перейди в новое окно и следуй инструкциям там."
    ;;

  Linux|WSL*)
    if command -v gnome-terminal >/dev/null 2>&1; then
      gnome-terminal -- bash -c "bash '$WIZARD'; echo; read -p 'Нажми Enter чтобы закрыть...'"
    elif command -v konsole >/dev/null 2>&1; then
      konsole -e bash -c "bash '$WIZARD'; echo; read -p 'Нажми Enter чтобы закрыть...'"
    elif command -v xterm >/dev/null 2>&1; then
      xterm -e bash -c "bash '$WIZARD'; echo; read -p 'Нажми Enter чтобы закрыть...'"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
      xfce4-terminal -e "bash -c \"bash '$WIZARD'; echo; read -p 'Нажми Enter чтобы закрыть...'\""
    else
      echo "❌ Не нашёл терминал-эмулятор. Запусти руками:"
      echo "    bash \"$WIZARD\""
      exit 1
    fi
    echo "✅ Открыл терминал с мастером Yandex OAuth. Перейди в новое окно."
    ;;

  MINGW*|MSYS*|CYGWIN*)
    NATIVE_WIZARD="$(cygpath -w "$WIZARD")"
    GIT_BASH="$(command -v bash || echo 'C:\Program Files\Git\bin\bash.exe')"
    NATIVE_BASH="$(cygpath -w "$GIT_BASH" 2>/dev/null || echo "$GIT_BASH")"
    powershell.exe -NoProfile -Command "Start-Process powershell -ArgumentList '-NoExit','-Command',\"& '$NATIVE_BASH' '$NATIVE_WIZARD'\""
    echo "✅ Открыл PowerShell-окно с мастером Yandex OAuth. Перейди в новое окно."
    ;;

  *)
    echo "❌ Не распознал ОС ($OS). Запусти мастер руками:"
    echo "    bash \"$WIZARD\""
    exit 1
    ;;
esac
