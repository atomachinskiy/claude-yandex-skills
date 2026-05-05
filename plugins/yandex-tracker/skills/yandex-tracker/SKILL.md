---
name: yandex-tracker
description: |
  Яндекс.Трекер — задачи, очереди, поиск тикетов через REST API. Работает с общим
  yandex-auth токеном плюс X-Org-Id (для Yandex 360) или X-Cloud-Org-Id (для Cloud).
  Triggers: yandex tracker, трекер, задачи, очереди, тикеты, issues.
---

# yandex-tracker

Tracker API v3. Задачи, очереди, поиск.

## Конфигурация

Помимо общего токена из `yandex-auth`, нужен **X-Org-Id**:
- `YANDEX_TRACKER_ORG_ID=12345` (для Yandex 360 организации)
- `YANDEX_TRACKER_CLOUD_ORG_ID=bpf...` (для Yandex Cloud организации)

Найти org_id: https://tracker.yandex.ru/admin/orgs (правое верхнее меню профиля).

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `myself.sh` | Текущий пользователь Tracker | — |
| `list-queues.sh` | Все очереди в организации | `[--json]` |
| `list-issues.sh` | Поиск задач по запросу | `[--query "..."] [--limit N] [--json]` |

## Workflow

```bash
bash scripts/myself.sh                          # sanity-check
bash scripts/list-queues.sh                     # все очереди
bash scripts/list-issues.sh                     # мои открытые тикеты
bash scripts/list-issues.sh --query "Queue: BK AND Status: open"
```

## Tracker query syntax

Полный справочник: https://yandex.ru/support/tracker/ru/user/queries.html
