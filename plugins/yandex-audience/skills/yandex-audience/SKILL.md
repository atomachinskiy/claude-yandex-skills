---
name: yandex-audience
description: |
  Аудитории Яндекса: создание сегментов, lookalike, использование в Директе и VK Ads.
  Использует общий OAuth-токен Яндекса (плагин yandex-auth). Cache-first,
  лимит stdout 30 строк по умолчанию.
  Triggers: yandex-audience, audience, яндекс audience.
---

# yandex-audience

Аудитории Яндекса: создание сегментов, lookalike, использование в Директе и VK Ads.

## Конфигурация

Скилл ходит за токеном в общий файл `~/.claude/secrets/yandex-app.json`, который выпускает плагин `yandex-auth`. Если токен не выпущен — скрипты выдадут ошибку с инструкцией запустить `yandex-auth/oauth-flow.sh`.

Scope в OAuth-приложении: `audience:use`.

## Принципы

1. **Cache-first** — конфигурационные данные (списки, метаданные) кешируются надолго; отчёты и live-данные — короткий TTL или без кеша.
2. **Гигиена контекста** — stdout по умолчанию ограничен 30 строками. Полные данные пишутся в файл (CSV/JSON), доступны через grep/rg.
3. **Никаких токенов в скилле** — только общий из `yandex-auth`. Не дублируем `.env` под каждый сервис.
4. **No destructive ops by default** — пишущие методы есть, но они должны быть явно вызваны и предупреждать пользователя.

## API

База: `https://api-audience.yandex.ru/v1`

Документация: см. `references/` (по мере наполнения).

## Workflow

> ⚠️ Скилл в стадии scaffold. Реальные команды будут добавляться по мере наполнения. Пока доступен только sanity-check токена и общий API-вызов через `scripts/common.sh` функцию `call`.

### Sanity-check

```bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh --status
```

Должен вернуть `✅ Token present` и `Live check: 200 OK`.

### Тестовый вызов API (raw)

```sh
. scripts/common.sh
load_config
call GET /<endpoint>
```

## Скрипты

| Скрипт | Назначение |
|---|---|
| `scripts/common.sh` | Подгружает общий токен из `yandex-auth`, определяет `API_BASE`, кеш-хелперы, `call` wrapper. Сорсится из всех остальных скриптов. |

*Список наполняется по мере добавления конкретных команд.*

## Ссылки

- yandex-auth: `../../yandex-auth/skills/yandex-auth/`
- Marketplace: `../../../.claude-plugin/marketplace.json`
