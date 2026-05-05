---
name: yandex-webmaster
description: |
  Управление сайтами в Яндекс.Вебмастере через общий yandex-auth токен.
  Список хостов, инфо о сайте (SQI, страницы в поиске, индексация), топ запросов.
  Triggers: yandex webmaster, яндекс вебмастер, вебмастер, индексация, sqi,
  поисковые запросы, страницы в поиске.
---

# yandex-webmaster

Webmaster API v4. Управление сайтами и анализ поискового трафика.

## Конфигурация
Общий токен из `yandex-auth`. Scope: `webmaster:hostinfo`, `webmaster:verify`.

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `user-info.sh` | Текущий user_id (используется другими скриптами) | — |
| `list-hosts.sh` | Все сайты пользователя | `[--json]` |
| `host-info.sh` | Детали сайта: SQI, страницы в поиске, индексация | `<host-id> [--json]` |
| `popular-queries.sh` | Топ поисковых запросов сайта за период | `<host-id> [--from --to] [--limit N] [--json]` |

## Host ID

Yandex использует составной ID вида `https:dariabot.ru:443` (схема + домен + порт). Получить через `list-hosts.sh`.

## Workflow

```bash
bash scripts/list-hosts.sh
bash scripts/host-info.sh "https:dariabot.ru:443"
bash scripts/popular-queries.sh "https:dariabot.ru:443" --limit 20
```
