# Changelog

Все значимые изменения проекта будут документироваться в этом файле.
Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [2.0.0] — 2026-09-15

### Changed — скилл Директа переписан на полный набор операций

Прежний скилл умел только читать: 18 shell-скриптов, вызовы `get`, 144 строки
документации. Теперь ядро Директа это 23 команды на Python (стандартная библиотека,
сторонних зависимостей нет) и 24 справочника, а прежний shell-контур сохранён рядом.
Источник ядра и что изменено при переносе: `NOTICE.md`.

### Added

- Запись: кампании, группы, объявления и комплекты, фразы, минус-фразы, ставки и
  корректировки, цели кампании с сохранением существующего списка, условия
  ретаргетинга. Все команды записи по умолчанию печатают план и ничего не меняют,
  запись включается отдельным флагом.
- Комбинаторные объявления: сборка комплектов, аудит последствий автоконвертации,
  превью отдельной страницей для согласования с клиентом.
- Фиды и товарные кампании, загрузка изображений, быстрые ссылки и уточнения.
- Ретаргетинг по сегментам Яндекс Метрики.
- Недельный лимит общего счёта: чтение, установка, снятие.
- Диагностика групп со статусом «мало показов» до перестройки семантики.
- Кросс-минусовка пересекающихся фраз.
- Выгрузка кампании одним файлом, кэш с явной ценой запросов в баллах.
- 80 модульных тестов: `cd plugins/yandex-direct/skills/yandex-direct/scripts &&
  python3 -m unittest discover -s tests`.
- `references/ОСНОВЫ.md`: доступ и приложения, `Bearer` вместо `OAuth`, обычный
  кабинет против агентского и `Client-Login`, коды 53/58/8000/8800, цена запросов
  в баллах с замерами, расхождение `TEXT_CAMPAIGN` и ЕПК в интерфейсе.

### Compatibility

- Токен по-прежнему берётся из `~/.claude/secrets/yandex-direct-app.json`, который
  пишет мастер `direct-oauth-flow.sh`. Переустанавливать доступ не нужно.
- Настройка `YANDEX_DIRECT_CLIENT_LOGIN` из версии 0.2 продолжает работать как
  синоним `YANDEX_DIRECT_ACCOUNT`.
- Проверено на Python 3.12; синтаксически код совместим с 3.9, то есть заводится и
  на системном питоне macOS.
- Живая проверка 15.09.2026 на кабинете `a-tomachinsky`: доступ, список кампаний,
  чтение лимита счёта и сухой прогон его установки.

### Fixed
- `yandex-wordstat`: рабочий бэкенд Yandex Cloud Search API v2. Поддержан статический
  Cloud API-ключ (`Authorization: Api-Key`) наряду с JSON-ключом сервисного аккаунта,
  `folderId` стал необязательным, `regions` уходят строками, добавлен обязательный
  `numPhrases`. До этого облачный бэкенд не работал вовсе: ждал только JSON-ключ и
  посылал регионы числами без `numPhrases`.
- `yandex-wordstat`: в `config/.env.example` исправлена роль сервисного аккаунта на
  `search-api.webSearch.user` (прежние `search-api.*` объявлены устаревшими и отвечают
  `code 7 denied`) и описана область действия ключа `yc.search-api.execute`.

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
