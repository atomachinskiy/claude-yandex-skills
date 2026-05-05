---
name: yandex-metrika
description: |
  Аналитика Яндекс.Метрики через общий yandex-auth токен.
  Список счётчиков, инфо о счётчике, traffic-summary за период, цели и конверсии.
  Triggers: yandex metrika, яндекс метрика, метрика, аналитика метрики, счётчик,
  визиты, конверсии, цели, трафик.
---

# yandex-metrika

Аналитика Яндекс.Метрики (Reporting API v1).

## Конфигурация
Использует общий токен из `yandex-auth`. Scope: `metrika:read`.

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `counters.sh` | Список всех счётчиков пользователя | `[--search Q] [--json] [--full]` |
| `counter-info.sh` | Подробная инфо о счётчике | `<id> [--json]` |
| `traffic-summary.sh` | Трафик за период (visits/users/pageviews/bounce) | `<id> [--from --to] [--json]` |
| `goals.sh` | Список целей счётчика | `<id> [--json]` |

## Workflow

```bash
bash scripts/counters.sh                          # узнать ID
bash scripts/counter-info.sh 97431059             # детали
bash scripts/traffic-summary.sh 97431059 \
    --from 2026-04-01 --to 2026-04-30             # отчёт по трафику
bash scripts/goals.sh 97431059                    # цели
```

## Особенности
- accuracy=1 (без сэмплирования) по умолчанию.
- Метрики: `ym:s:visits, ym:s:users, ym:s:pageviews, ym:s:bounceRate, ym:s:avgVisitDurationSeconds, ym:s:percentNewVisitors`.
- Полный справочник метрик/dimensions: https://yandex.ru/dev/metrika/doc/api2/api_v1/intro.html
