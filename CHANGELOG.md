# Changelog

Все значимые изменения проекта будут документироваться в этом файле.
Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [0.2.0] — 2026-05-05

### Added — все 15 плагинов закрыты

**Working (рабочие скрипты, live-tested):**
- `yandex-metrika`: counters, counter-info, traffic-summary (visits/users/pageviews/bounce/duration), goals.
- `yandex-webmaster`: user-info, list-hosts, host-info (SQI, страницы в поиске), popular-queries.

**Conditional (готовые скрипты, нужен дополнительный конфиг):**
- `yandex-tracker`: myself, list-queues, list-issues с поддержкой `X-Org-Id` / `X-Cloud-Org-Id` headers.
- `yandex-mail`: IMAP XOAUTH2 через Python — list-folders, inbox-count. Требует `mail:imap_full` scope + IMAP включённый в настройках Я.Почты.

**Probe-style (заглушка с инструкцией активации):**
- `yandex-direct` — нужно отдельное OAuth-приложение в кабинете Директа.
- `yandex-audience` — нужен scope `audience:use` в OAuth-app.
- `yandex-telemost` — нужен Yandex 360 для бизнеса.
- `yandex-360-admin` — нужны scope `directory:read` и `org_id`.
- `yandex-bot-platform` — нужен зарегистрированный навык в Dialogs Developer Console.
- `yandex-messenger` — нужен отдельный bot-токен (не OAuth).

Каждый probe — рабочий скрипт `probe.sh`, который дёргает endpoint, показывает HTTP-код и пошаговую инструкцию что сделать чтобы заработало.

## [0.1.0] — 2026-05-05

### Added
- **`yandex-disk`**: полная REST-реализация. Скрипты `info`, `list`, `upload`,
  `download`, `publish`, `search`. Live-tested на cloud-api.yandex.net.
- **`yandex-wordstat`**: dual-backend dispatcher (legacy OAuth + cloud IAM).
  Скрипт `top-requests.sh` работает на legacy backend. Cloud-путь —
  с инструкцией по setup SA в Yandex Cloud, JWT/IAM exchange реализован.
- **`yandex-calendar`**: CalDAV MVP. Скрипты `list-calendars`, `list-events`.
  Auth через Basic (login + общий yandex-auth токен). Live-tested.
- **`yandex-forms`**: probe-скрипт + документация по workaround'ам
  (публичный API ограничен на 2026).

## [0.0.1] — 2026-05-05

### Added
- Каркас marketplace-репозитория (15 плагинов).
- Плагин `yandex-auth`: рабочий OAuth-flow через приложение «Я-Клауд-Клиентс».
  Кросс-платформа, выбор браузера, токен в `~/.claude/secrets/yandex-app.json`.
- 14 сервисных плагинов в стадии scaffold (унифицированная структура).
- Скрипт-репликатор `scripts/scaffold-plugins.sh`.
- End-to-end smoke test на yandex-disk.
