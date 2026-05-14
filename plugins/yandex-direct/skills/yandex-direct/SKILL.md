---
name: yandex-direct
description: |
  Контекстная реклама Яндекс.Директ — кампании, объявления, отчёты, ставки.
  Использует ОТДЕЛЬНОЕ OAuth-приложение ("Claud direct", client_id 040b84bb…),
  токен живёт в ~/.claude/secrets/yandex-direct-app.json (chmod 600).
  Direct API v5 → POST + Authorization: Bearer.
  Triggers: yandex-direct, директ, яндекс директ, реклама в директе.
---

## Установка токена (первый раз)

Direct требует свой токен — общий yandex-auth не подходит.

```bash
bash scripts/direct-oauth-flow.sh
```

Скрипт откроет браузер на oauth.yandex.ru для app `"Claud direct"`, после подтверждения вставишь `access_token` из callback-URL. Токен сохранится в `~/.claude/secrets/yandex-direct-app.json`.

Проверка статуса:
```bash
bash scripts/direct-oauth-flow.sh --status
```

## Probe — проверка доступа

```bash
bash scripts/probe.sh
```

Вернёт список клиентов аккаунта или подробный error_code с подсказкой. Типовые коды:
- `58` — заявка на API для этого OAuth-app ещё не одобрена (проверь в кабинете Директа → Настройки API)
- `53/54` — токен невалиден, перевыпусти через `direct-oauth-flow.sh`
- `8000` — токен не передаётся, проверь `$DIRECT_TOKEN_FILE`

## Команды

### Список кампаний
```bash
bash scripts/campaigns.sh                     # все
bash scripts/campaigns.sh --state ON          # только активные
bash scripts/campaigns.sh --type TEXT_CAMPAIGN
```

Вывод: `[<state>/<status>]  <id>  <name>  (<type>, start=YYYY-MM-DD)`

### Отчёт по кампании
```bash
bash scripts/report.sh <campaign_id>                       # за 30 дней
bash scripts/report.sh <campaign_id> --from 2026-05-01 --to 2026-05-14
```

Формат: TSV с колонками Date, Impressions, Clicks, Cost, Ctr, AvgCpc, Conversions. Async polling — Direct может отдать `201` пока отчёт готовится, скрипт сам ждёт `retryIn` секунд.

### Произвольный API-вызов
```bash
. scripts/common.sh && load_config
direct_call <resource> '<json-body>'
```

Например:
```bash
direct_call ads '{"method":"get","params":{"SelectionCriteria":{"CampaignIds":["12345"]},"FieldNames":["Id","Status","Type"]}}'
direct_call adgroups '{"method":"get","params":{"SelectionCriteria":{},"FieldNames":["Id","Name","Type"]}}'
direct_call keywords '{"method":"get","params":{"SelectionCriteria":{"AdGroupIds":["67890"]},"FieldNames":["Id","Keyword","Bid"]}}'
```

Полный справочник endpoint'ов: https://yandex.ru/dev/direct/doc/

## Что НЕ делать
- Не использовать `Authorization: OAuth ...` — Direct требует `Bearer`
- Не делать GET — Direct API v5 принимает только POST
- Не хранить токен в `.env` плагина — он живёт в `~/.claude/secrets/`
- Не переиспользовать общий yandex-app.json — он от другого OAuth-приложения
