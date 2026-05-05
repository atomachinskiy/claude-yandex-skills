---
name: yandex-forms
description: |
  Конструктор форм Яндекса. ⚠️ Публичный REST API ограничен / отсутствует.
  Скилл работает в режиме probe + workaround-инструкции. Для production —
  использовать webhook или интеграцию формы с Tracker / Sheets.
  Triggers: yandex forms, яндекс формы, конструктор форм, опросы.
---

# yandex-forms

⚠️ **Публичного REST API у Яндекс Форм нет** (на 2026). Это известное ограничение —
у конкурентов (Google Forms, Typeform) API есть, у Яндекса — пока нет.

## Что доступно

- `scripts/list-surveys.sh` — пробинг известных endpoint'ов (`forms.yandex.ru/api/v1/`,
  `forms.yandex.ru/api/v2/`). Возвращает HTTP-коды и подсказки по обходу.

## Workaround'ы

1. **Webhook в форме**: в редакторе формы → настройки → «Уведомления» → добавить URL.
   Каждый ответ POST'ится на твой сервер (n8n / Cloudflare Worker / собственный).
2. **Интеграция с Yandex Tracker**: создавать тикет на каждый ответ (если у тебя есть Tracker).
3. **Экспорт в Яндекс.Таблицу**: в форме → «Связать с таблицей» → ответы автоматически
   ложатся в Sheet → читать через `yandex-disk` или `yandex-calendar` (Sheets in Disk).
4. **Yandex 360 admin API** (`api360.yandex.net`) — если у тебя 360 для бизнеса,
   возможно там есть формы. Проверь scope в OAuth.

## Когда добавим реальные команды

Если Яндекс выкатит публичный API (планы есть, см. https://yandex.ru/dev/forms/),
обновим скилл — добавим `responses.sh`, `export-csv.sh`, `create-survey.sh`.

## Структура папки

| Файл | Назначение |
|---|---|
| `scripts/list-surveys.sh` | Probe endpoints, report status |
| `scripts/common.sh` | Shared helpers (от templates) |
