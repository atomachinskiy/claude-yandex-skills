# claude-yandex-skills

Marketplace плагинов для Claude Code, покрывающих экосистему Яндекса.
Один OAuth — все сервисы.

> Статус: **0.2.0 — все 15 плагинов закрыты.** OAuth-инфраструктура работает,
> сервисные плагины наполняются по фазам (см. Roadmap ниже).

## Зачем

В экосистеме Яндекса 14+ API-сервисов: Метрика, Вебмастер, Wordstat, Директ,
Аудитории, Формы, Календарь, Почта, Диск, Телемост, Трекер, Боты, 360 Admin,
Мессенджер. Одним OAuth-приложением (тип «Веб-сервисы») можно охватить все —
и иметь *один токен* на все сервисы.

Этот пакет реализует такой подход:
- Один плагин **`yandex-auth`** выпускает и хранит токен.
- 14 сервисных плагинов (`yandex-metrika`, `yandex-webmaster`, ...) подсасывают
  токен из общего хранилища и работают каждый со своим API.

## Архитектура

```
┌────────────────────────────────────────────────────────────────┐
│  OAuth-приложение в Яндексе («Я-Клауд-Клиентс»)                │
│  client_id = 2f69a4396d68...                                   │
│  scopes = метрика, вебмастер, директ, аудитории, формы,        │
│           календарь, почта, диск, трекер, телемост, ...        │
└────────────────┬───────────────────────────────────────────────┘
                 │ implicit OAuth flow, response_type=token
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  yandex-auth (этот плагин)                                     │
│  scripts/oauth-flow.sh — браузер → токен → файл                │
│  scripts/common.sh — load_token, auth_header, status           │
└────────────────┬───────────────────────────────────────────────┘
                 │ записывает / читает
                 ▼
┌────────────────────────────────────────────────────────────────┐
│  ~/.claude/secrets/yandex-app.json   (chmod 600)               │
│  { access_token, login, user_id, issued_at, ... }              │
└────────────────┬───────────────────────────────────────────────┘
                 │ читают
        ┌────────┼────────┬─────────┬─────────┬───── ...
        ▼        ▼        ▼         ▼         ▼
   yandex-     yandex-  yandex-   yandex-   yandex-
    metrika    forms    disk      direct    tracker     ...
```

Каждый сервисный плагин в своём `scripts/common.sh` сорсит
`yandex-auth/scripts/common.sh`, вызывает `yandex_load_token`, и дёргает
свой API через готовую функцию `call <method> <path>`.

## Установка

📖 **Полная пошаговая инструкция для AI-ассистента — [docs/INSTALL.md](docs/INSTALL.md).**
Эта инструкция оптимизирована под установку через Claude Code: AI делает всё сам через `git clone`, пользователю нужно только нажать «Разрешить» в браузере и вставить URL обратно. Без `/plugin` slash-команд, без Git Bash на Windows.

### Быстрый старт (вручную)

```bash
git clone --depth 1 https://github.com/atomachinskiy/claude-yandex-skills.git ~/.claude/yandex-skills-local
```

**OAuth (один токен на все сервисы):**

macOS / Linux:
```bash
bash ~/.claude/yandex-skills-local/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh
```

Windows (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\yandex-skills-local\plugins\yandex-auth\skills\yandex-auth\scripts\oauth-flow.ps1"
```

Откроется браузер с authorize-страницей Яндекса. После «Разрешить» —
скрипт ловит токен из URL, валидирует через `login.yandex.ru/info`,
кладёт в `~/.claude/secrets/yandex-app.json`. Один раз — и работает всё.

Проверка токена:
```bash
# macOS/Linux
bash ~/.claude/yandex-skills-local/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh --status
# Windows
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\yandex-skills-local\plugins\yandex-auth\skills\yandex-auth\scripts\oauth-flow.ps1" -Status
```

### Альтернатива — Marketplace (требует ручного ввода slash-команд в Claude Code)

```
/plugin marketplace add atomachinskiy/claude-yandex-skills
/plugin install yandex-auth@claude-yandex-skills
/plugin install yandex-metrika@claude-yandex-skills   # любые из списка
```

⚠️ Slash-команды Claude Code может выполнить только сам пользователь — AI через `Bash` tool их вызвать не может. Поэтому marketplace-путь подходит, только если ты ставишь руками сам.

## Список плагинов

| Плагин | Сервис | Статус |
|---|---|---|
| `yandex-auth` | Единая точка авторизации | ✅ работает |
| `yandex-metrika` | Аналитика (трафик, конверсии, UTM, цели) | 🟢 working |
| `yandex-webmaster` | Управление сайтами в поиске (SQI, queries, hosts) | 🟢 working |
| `yandex-wordstat` | Поисковый спрос (dual-backend: legacy + cloud) | 🟢 working (legacy) |
| `yandex-direct` | Контекстная реклама | ⚠️ probe (нужно отд. OAuth-app) |
| `yandex-audience` | Сегменты аудиторий | ⚠️ probe (нужен scope audience:use) |
| `yandex-forms` | Конструктор форм | 🔴 limited (no public API) |
| `yandex-calendar` | Календарь (CalDAV) | 🟢 MVP working |
| `yandex-mail` | Почта 360 (IMAP/SMTP) | 🟡 IMAP XOAUTH2 (нужно включить IMAP в ящике) |
| `yandex-disk` | Облако (REST + WebDAV) | 🟢 working |
| `yandex-telemost` | Видеовстречи | ⚠️ probe (нужен Yandex 360 для бизнеса) |
| `yandex-tracker` | Трекер задач | 🟡 готово (нужен X-Org-Id в .env) |
| `yandex-bot-platform` | Диалоги Алисы / навыки | ⚠️ probe (нужен скилл в Dialogs Console) |
| `yandex-360-admin` | Админ-API организации | ⚠️ probe (нужен scope directory:read + org_id) |
| `yandex-messenger` | Мессенджер (бот-API) | ⚠️ probe (нужен отдельный bot-токен) |

## Roadmap наполнения

### ✅ Фаза 1 — закрыта (2026-05-05)
- [x] `yandex-wordstat` — dual-backend (legacy + cloud IAM); `top-requests.sh` working на legacy.
- [x] `yandex-disk` — полный REST: info, list, upload, download, publish, search.
- [x] `yandex-forms` — probe + workaround docs (публичный API ограничен).
- [x] `yandex-calendar` — CalDAV MVP: list-calendars + list-events.

### ✅ Фаза 2 — закрыта (2026-05-05)
- [x] `yandex-metrika` — counters, counter-info, traffic-summary, goals (live).
- [x] `yandex-webmaster` — list-hosts, host-info, popular-queries (live).
- [x] `yandex-tracker` — myself, list-queues, list-issues (нужен X-Org-Id).
- [x] `yandex-mail` — IMAP XOAUTH2: list-folders, inbox-count (нужно включить IMAP в Я.Почте).
- [x] `yandex-direct`, `yandex-audience`, `yandex-telemost`, `yandex-360-admin`,
      `yandex-bot-platform`, `yandex-messenger` — probe-скрипт + activation-инструкции
      (каждый требует отдельной заявки / scope / setup).

## Дальше

Все 15 плагинов закрыты структурно. Будущие апдейты по ситуации:
- Полная реализация direct/audience/etc. — когда соответствующие сервисы будут активированы у пользователя.
- Расширение существующих скиллов (e.g. metrika , ).
- Возможный публичный релиз репо (сейчас приватный).

## Структура

```
.claude-plugin/marketplace.json     — каталог плагинов
plugins/<slug>/                     — один плагин
├── .claude-plugin/plugin.json
└── skills/<slug>/
    ├── SKILL.md                    — frontmatter + workflow + scripts
    ├── .gitignore                  — config/.env, cache/*
    ├── cache/.gitkeep
    ├── config/
    │   ├── README.md               — как получить креденшелы
    │   └── .env.example            — шаблон скилл-специфичных параметров
    ├── references/                 — углублённая документация по фичам
    └── scripts/
        ├── common.sh               — общий: load_config, auth_header, call, cache
        └── <feature>.sh            — per-feature команды
scripts/scaffold-plugins.sh         — генератор-репликатор шаблона
```

## Лицензия

MIT — см. `LICENSE`.
