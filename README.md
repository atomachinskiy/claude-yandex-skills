# claude-yandex-skills

Marketplace плагинов для Claude Code, покрывающих экосистему Яндекса.
Один OAuth — все сервисы.

> Статус: **0.0.1 — каркас.** Структура развёрнута, OAuth-инфраструктура работает,
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

### Marketplace

```
/plugin marketplace add atomachinskiy/claude-yandex-skills
/plugin install yandex-auth@claude-yandex-skills
/plugin install yandex-metrika@claude-yandex-skills   # любые из списка
```

### Первый запуск

```bash
bash ~/.claude/skills/yandex-auth/scripts/oauth-flow.sh
```

Откроется браузер с authorize-страницей Яндекса. После «Разрешить» —
скрипт ловит токен из URL, валидирует через `login.yandex.ru/info`,
кладёт в `~/.claude/secrets/yandex-app.json`. Один раз — и работает всё.

Проверка:
```bash
bash ~/.claude/skills/yandex-auth/scripts/oauth-flow.sh --status
```

## Список плагинов

| Плагин | Сервис | Статус |
|---|---|---|
| `yandex-auth` | Единая точка авторизации | ✅ работает |
| `yandex-metrika` | Аналитика (трафик, конверсии, UTM) | 🟡 scaffold |
| `yandex-webmaster` | Управление сайтами в поиске | 🟡 scaffold |
| `yandex-wordstat` | Поисковый спрос (dual-backend: legacy + cloud) | 🟢 working (legacy) |
| `yandex-direct` | Контекстная реклама | 🟡 scaffold |
| `yandex-audience` | Сегменты аудиторий | 🟡 scaffold |
| `yandex-forms` | Конструктор форм | 🔴 limited (no public API) |
| `yandex-calendar` | Календарь (CalDAV) | 🟢 MVP working |
| `yandex-mail` | Почта 360 (IMAP/SMTP) | 🟡 scaffold |
| `yandex-disk` | Облако (REST + WebDAV) | 🟢 working |
| `yandex-telemost` | Видеовстречи | 🟡 scaffold |
| `yandex-tracker` | Трекер задач | 🟡 scaffold |
| `yandex-bot-platform` | Диалоги Алисы / навыки | 🟡 scaffold |
| `yandex-360-admin` | Админ-API организации | 🟡 scaffold |
| `yandex-messenger` | Мессенджер (бот-API) | 🟡 scaffold |

## Roadmap наполнения

### Фаза 1 — критично для пилотных пользователей
- [ ] `yandex-wordstat` — **dual-backend**: legacy OAuth (для существующих юзеров с одобренным scope) + cloud IAM (для новых, Yandex закрыл legacy onboarding).
- [ ] `yandex-disk` — REST для файлов клиентов
- [ ] `yandex-forms` — чтение ответов на формы
- [ ] `yandex-calendar` — CalDAV для расписаний

### Фаза 2 — рабочий инструментарий
- [ ] `yandex-mail` — IMAP/SMTP
- [ ] `yandex-tracker` — задачи и очереди
- [ ] `yandex-direct` — рекламный кабинет (полный цикл)

### Фаза 3 — миграция существующего
- [ ] `yandex-metrika` — переписать существующий локальный скилл на общую инфру

### Фаза 4 — по запросу
- [ ] `yandex-360-admin`, `yandex-messenger`, `yandex-bot-platform`,
      `yandex-telemost`, `yandex-audience`, `yandex-webmaster`

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
