---
name: yandex-calendar
description: |
  Работа с Яндекс.Календарём через CalDAV. Список календарей, события за
  период, поиск встреч. Auth через login + общий yandex-auth токен (как Basic).
  Triggers: yandex calendar, яндекс календарь, caldav, события, встречи,
  расписание, календарь.
---

# yandex-calendar

CalDAV-клиент к Яндекс.Календарю через `https://caldav.yandex.ru`.

## Auth

Yandex CalDAV принимает **HTTP Basic** с парой `<login>:<oauth-token>` (вместо пароля используется OAuth-токен из `yandex-auth`). Логин в адресе principal должен быть в email-форме (`a.tomachinsky@yandex.ru`).

Скилл достаёт login и токен автоматически из `~/.claude/secrets/yandex-app.json` через `yandex-auth/common.sh`.

## Workflow

### Sanity-check

```bash
bash scripts/list-calendars.sh
```

Должен вывести список календарей с их CalDAV-путями (`/calendars/<email>/events-XXXXXX/`).

### События за период

```bash
bash scripts/list-events.sh "/calendars/<email>/events-853016/" --from 2026-05-01 --to 2026-05-31
```

По умолчанию: сегодня → сегодня + 30 дней.

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `list-calendars.sh` | Все календари юзера | — |
| `list-events.sh` | События в диапазоне дат | `<calendar-path> [--from YYYY-MM-DD] [--to YYYY-MM-DD]` |
| `common.sh` | CalDAV helpers (PROPFIND, REPORT, Basic auth) | — |

## Что НЕ покрыто (потенциально для следующих версий)

- Создание / редактирование событий (`PUT` ICS файла)
- Подписки на чужие календари
- Полная поддержка повторяющихся событий (RRULE сейчас не разворачивается — показываем только базовое)
- Todos (`/calendars/.../todos-XXXX/`) — структура та же что у events, скрипт работает, но формат VTODO не парсится отдельно

## Технические заметки

- CalDAV — это XML over HTTP с методами `PROPFIND` (read tree) и `REPORT` (queries). Не путать с обычным REST.
- iCalendar (`.ics`) — формат содержимого событий. Парсится regex'ами в `list-events.sh` (упрощённо, для production-quality нужен полноценный парсер).
- Time-range запрос требует UTC-формат `YYYYMMDDThhmmssZ`. Скрипт сам конвертирует из `YYYY-MM-DD`.
