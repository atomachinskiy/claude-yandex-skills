#!/bin/sh
# scaffold-plugins.sh — generate the unified scaffold for every yandex-* plugin
# (except yandex-auth, which is hand-written).
# Re-runnable; overwrites template files but preserves anything in scripts/<custom>.sh

set -e
ROOT="$HOME/Workspaces/claude-yandex-skills"

# slug | api_base | scope_hint | description_ru
PLUGINS=$(cat <<'PL'
yandex-disk|https://cloud-api.yandex.net/v1/disk|cloud_api:disk.read,cloud_api:disk.write,cloud_api:disk.info|Облако Яндекс.Диск через REST API: файлы, папки, публикация ссылок. Также fallback на WebDAV.
yandex-mail|imap.yandex.ru,smtp.yandex.ru|mail:imap_full,mail:smtp|Почта Яндекс 360: чтение, отправка, поиск через IMAP/SMTP с OAuth-токеном.
yandex-calendar|https://caldav.yandex.ru|calendar:caldav|Календарь Яндекс 360 через CalDAV: события, расписание, напоминания.
yandex-audience|https://api-audience.yandex.ru/v1|audience:use|Аудитории Яндекса: создание сегментов, lookalike, использование в Директе и VK Ads.
yandex-direct|https://api.direct.yandex.com/json/v5|direct:api|Контекстная реклама Яндекс.Директ: кампании, объявления, отчёты, ставки, ОРД-документы.
yandex-forms|https://forms.yandex.ru/api/v1|forms:read,forms:write|Конструктор форм: создание форм, чтение ответов, экспорт результатов.
yandex-telemost|https://telemost.yandex.ru/api/v1|meetings:hosts:write,meetings:user_info|Видеовстречи Яндекс.Телемост: создание встреч, расписание, ссылки.
yandex-wordstat|https://api.direct.yandex.ru/v4/json|direct:api-stats|Анализ поискового спроса (Wordstat). ⚠️ Доступ к scope требует ручной заявки в поддержку Яндекса.
yandex-tracker|https://api.tracker.yandex.net/v2|tracker:read,tracker:write|Трекер задач: задачи, очереди, комментарии, статусы, отчёты.
yandex-bot-platform|https://dialogs.yandex.ru/api/v1|dialogs:bot|Ботоплатформа Яндекс.Диалогов: навыки Алисы, голосовые скиллы, аналитика.
yandex-360-admin|https://api360.yandex.net|directory:full|Админ-API Яндекс 360: пользователи, домены, аудит, настройки организации.
yandex-messenger|https://botapi.messenger.yandex.net|messenger:read,messenger:write|Яндекс.Мессенджер: чаты, сообщения, поиск (бот-API).
yandex-webmaster|https://api.webmaster.yandex.net/v4|webmaster:hostinfo,webmaster:verify|Управление сайтами в Вебмастере: индексация, поисковые запросы, сайтмапы, переобход, ссылки.
PL
)

scaffold_one() {
    SLUG="$1"; API="$2"; SCOPE="$3"; DESC="$4"
    P="$ROOT/plugins/$SLUG"
    S="$P/skills/$SLUG"
    mkdir -p "$P/.claude-plugin" "$S/scripts" "$S/config" "$S/references" "$S/cache"
    touch "$S/cache/.gitkeep" "$S/scripts/.gitkeep" "$S/references/.gitkeep"

    # plugin.json
    cat > "$P/.claude-plugin/plugin.json" <<EOF
{
  "name": "$SLUG",
  "version": "0.0.1",
  "description": "$DESC",
  "author": { "name": "Andrey Tomachinskiy" }
}
EOF

    # .gitignore
    cat > "$S/.gitignore" <<'EOF'
config/.env
cache/*
!cache/.gitkeep
EOF

    # config/README.md
    cat > "$S/config/README.md" <<EOF
# $SLUG — конфигурация

Этот скилл использует **общий** OAuth-токен Яндекса, выпущенный через плагин \`yandex-auth\`.

## Откуда берётся токен

\`\`\`
~/.claude/secrets/yandex-app.json
\`\`\`

Файл создаётся командой \`yandex-auth/scripts/oauth-flow.sh\`. Один токен покрывает все scope'ы, которые включены в OAuth-приложение «Я-Клауд-Клиентс» — в том числе \`$SCOPE\` для этого скилла.

## Если токена нет

Запусти:
\`\`\`bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh
\`\`\`

Подробнее — в \`yandex-auth/SKILL.md\`.

## Дополнительные настройки

Если для \`$SLUG\` нужны какие-то отдельные параметры (URL клиента, идентификаторы организации и т.д.) — клади их в \`config/.env\` рядом с этим файлом. Шаблон — \`.env.example\`.
EOF

    # config/.env.example
    cat > "$S/config/.env.example" <<EOF
# $SLUG — дополнительные настройки (если нужны)
# Общий Yandex-токен берётся из ~/.claude/secrets/yandex-app.json — здесь его НЕ дублируем.
# Сюда кладём только параметры специфичные для этого скилла.
EOF

    # scripts/common.sh
    cat > "$S/scripts/common.sh" <<EOF
#!/bin/sh
# Common functions for $SLUG skill. POSIX sh compatible — no bashisms.

set -e

SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
CONFIG_FILE="\$SCRIPT_DIR/../config/.env"
CACHE_DIR="\$SCRIPT_DIR/../cache"

# API base for $SLUG
API_BASE="$API"

# Tools
JQ="\$(command -v jq || echo /usr/local/bin/jq)"

# ── Bridge to yandex-auth (shared OAuth token) ──────────────────
# Resolve yandex-auth/common.sh by climbing 3 levels up from scripts/ dir,
# then descending into plugins/yandex-auth/skills/yandex-auth/scripts/common.sh.
_AUTH_COMMON="\$SCRIPT_DIR/../../../../yandex-auth/skills/yandex-auth/scripts/common.sh"
if [ ! -f "\$_AUTH_COMMON" ]; then
    # Fallback when installed as plugins under ~/.claude/skills/
    _AUTH_COMMON="\$HOME/.claude/skills/yandex-auth/scripts/common.sh"
fi
# shellcheck disable=SC1090
. "\$_AUTH_COMMON"

# load_config — reads optional .env (skill-specific params), then ensures token.
load_config() {
    if [ -f "\$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        . "\$CONFIG_FILE"
    fi
    yandex_load_token   # sets YANDEX_ACCESS_TOKEN, YANDEX_LOGIN, YANDEX_USER_ID
}

# ── Cache helpers ──────────────────────────────────────────────
# cache_path TYPE KEY → echoes file path under cache/<type>/<key>
cache_path() {
    echo "\$CACHE_DIR/\$1/\$2"
}

# cache_get FILE [TTL_SECONDS] → echoes content, returns 0 on hit, 1 on miss
cache_get() {
    _f="\$1"; _ttl="\${2:-86400}"
    [ -f "\$_f" ] && [ -s "\$_f" ] || return 1
    _age=\$(( \$(date +%s) - \$(stat -f %m "\$_f" 2>/dev/null || stat -c %Y "\$_f") ))
    [ "\$_age" -gt "\$_ttl" ] && return 1
    cat "\$_f"
}

# cache_put FILE — reads stdin, writes to file
cache_put() {
    mkdir -p "\$(dirname "\$1")"
    cat > "\$1"
}

# ── Output limiter ─────────────────────────────────────────────
# Pipe through limit_output to keep stdout context-friendly.
limit_output() {
    if [ "\${OUTPUT_FULL:-0}" -eq 1 ]; then cat; return; fi
    awk 'NR<=30; END { if (NR>30) printf "# ... truncated (%d more lines). Use --full to show all.\n", NR-30 }'
}

# ── Auth header helper ─────────────────────────────────────────
auth_header() {
    printf 'Authorization: OAuth %s' "\$YANDEX_ACCESS_TOKEN"
}

# ── Generic call wrapper ───────────────────────────────────────
# call <method> <path> [extra curl args...]
# Echoes raw response body. Method examples: GET, POST.
call() {
    _method="\$1"; _path="\$2"; shift 2
    curl -s --max-time 30 -X "\$_method" \\
        -H "\$(auth_header)" \\
        -H "Content-Type: application/json" \\
        "\$@" \\
        "\$API_BASE\$_path"
}
EOF

    # SKILL.md
    cat > "$S/SKILL.md" <<EOF
---
name: $SLUG
description: |
  $DESC
  Использует общий OAuth-токен Яндекса (плагин yandex-auth). Cache-first,
  лимит stdout 30 строк по умолчанию.
  Triggers: $SLUG, ${SLUG#yandex-}, яндекс ${SLUG#yandex-}.
---

# $SLUG

$DESC

## Конфигурация

Скилл ходит за токеном в общий файл \`~/.claude/secrets/yandex-app.json\`, который выпускает плагин \`yandex-auth\`. Если токен не выпущен — скрипты выдадут ошибку с инструкцией запустить \`yandex-auth/oauth-flow.sh\`.

Scope в OAuth-приложении: \`$SCOPE\`.

## Принципы

1. **Cache-first** — конфигурационные данные (списки, метаданные) кешируются надолго; отчёты и live-данные — короткий TTL или без кеша.
2. **Гигиена контекста** — stdout по умолчанию ограничен 30 строками. Полные данные пишутся в файл (CSV/JSON), доступны через grep/rg.
3. **Никаких токенов в скилле** — только общий из \`yandex-auth\`. Не дублируем \`.env\` под каждый сервис.
4. **No destructive ops by default** — пишущие методы есть, но они должны быть явно вызваны и предупреждать пользователя.

## API

База: \`$API\`

Документация: см. \`references/\` (по мере наполнения).

## Workflow

> ⚠️ Скилл в стадии scaffold. Реальные команды будут добавляться по мере наполнения. Пока доступен только sanity-check токена и общий API-вызов через \`scripts/common.sh\` функцию \`call\`.

### Sanity-check

\`\`\`bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh --status
\`\`\`

Должен вернуть \`✅ Token present\` и \`Live check: 200 OK\`.

### Тестовый вызов API (raw)

\`\`\`sh
. scripts/common.sh
load_config
call GET /<endpoint>
\`\`\`

## Скрипты

| Скрипт | Назначение |
|---|---|
| \`scripts/common.sh\` | Подгружает общий токен из \`yandex-auth\`, определяет \`API_BASE\`, кеш-хелперы, \`call\` wrapper. Сорсится из всех остальных скриптов. |

*Список наполняется по мере добавления конкретных команд.*

## Ссылки

- yandex-auth: \`../../yandex-auth/skills/yandex-auth/\`
- Marketplace: \`../../../.claude-plugin/marketplace.json\`
EOF

    chmod +x "$S/scripts/common.sh" 2>/dev/null || true
}

echo "$PLUGINS" | while IFS='|' read -r slug api scope desc; do
    [ -z "$slug" ] && continue
    echo "→ $slug"
    scaffold_one "$slug" "$api" "$scope" "$desc"
done

echo ""
echo "=== syntax check on all common.sh ==="
for f in $ROOT/plugins/*/skills/*/scripts/common.sh; do
    sh -n "$f" && echo "  ok: $f" || echo "  FAIL: $f"
done

echo ""
echo "=== overall tree (depth 5) ==="
find "$ROOT" -maxdepth 5 -name "*.md" -o -name "*.json" -o -name "*.sh" | sort | head -60
echo "..."
echo "(total files: $(find $ROOT -type f | wc -l))"
