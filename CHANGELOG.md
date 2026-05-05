# Changelog

Все значимые изменения проекта будут документироваться в этом файле.
Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

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
- Плагин `yandex-auth`: рабочий OAuth-flow через приложение «Я-Клауд-Клиентс»
  (client_id `2f69a4396d684385a5f6578dd5eb7863`).
  - Кросс-платформа (macOS / Linux / Windows-bash).
  - Выбор браузера через `--browser <yandex|chrome|firefox|safari|edge|default|none>`
    или интерактивное меню.
  - Сохранение токена в `~/.claude/secrets/yandex-app.json` (chmod 600)
    с авто-валидацией через `login.yandex.ru/info`.
  - Команда `--status` с live-проверкой токена.
- 14 сервисных плагинов в стадии scaffold (унифицированная структура):
  metrika, webmaster, wordstat, direct, audience, forms, calendar, mail,
  disk, telemost, tracker, bot-platform, 360-admin, messenger.
- Каждый сервисный плагин: `plugin.json`, `SKILL.md`, `config/README.md`,
  `config/.env.example`, `scripts/common.sh` (с bridge на `yandex-auth`),
  `references/`, `cache/`, `.gitignore`.
- Скрипт-репликатор `scripts/scaffold-plugins.sh` для перегенерации шаблонов.
- End-to-end smoke test на `yandex-disk`: токен из `yandex-auth` → `call GET /`
  → реальный ответ от `cloud-api.yandex.net` с метаданными аккаунта.
