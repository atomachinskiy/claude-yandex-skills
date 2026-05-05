---
name: yandex-metrika
description: |
  Аналитика Яндекс.Метрики: трафик, конверсии, цели, UTM, источники, e-commerce, расходы Директа. Cache-first, 30-строчный лимит stdout.
  Использует общий OAuth-токен Яндекса (плагин yandex-auth). Cache-first,
  лимит stdout 30 строк по умолчанию.
  Triggers: yandex-metrika, metrika, яндекс metrika.
---

# yandex-metrika

Аналитика Яндекс.Метрики: трафик, конверсии, цели, UTM, источники, e-commerce, расходы Директа. Cache-first, 30-строчный лимит stdout.

## Конфигурация

Скилл ходит за токеном в общий файл `~/.claude/secrets/yandex-app.json`, который выпускает плагин `yandex-auth`. Если токен не выпущен — скрипты выдадут ошибку с инструкцией запустить `yandex-auth/oauth-flow.sh`.

Scope в OAuth-приложении: `metrika:read,metrika:write,metrika:expenses,metrika:user_params`.

## Принципы

1. **Cache-first** — конфигурационные данные кешируются надолго; отчёты и live-данные — короткий TTL или без кеша.
2. **Гигиена контекста** — stdout по умолчанию 30 строк. Полные данные пишутся в файл (CSV/JSON), доступны через grep/rg.
3. **Никаких токенов в скилле** — только общий из `yandex-auth`.

## API

База: `https://api-metrika.yandex.net`

## Workflow

> ⚠️ Скилл в стадии scaffold. Реальные команды добавляются по мере наполнения.

### Sanity-check

```bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh --status
```

## Скрипты

| Скрипт | Назначение |
|---|---|
| `scripts/common.sh` | Подгружает общий токен, определяет `API_BASE`, кеш-хелперы, `call` wrapper. |

## Ссылки

- yandex-auth: `../../yandex-auth/skills/yandex-auth/`
- Marketplace: `../../../.claude-plugin/marketplace.json`
