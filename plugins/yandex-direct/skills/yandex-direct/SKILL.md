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

### Структура кабинета
```bash
bash scripts/campaigns.sh                          # все кампании
bash scripts/campaigns.sh --state ON               # только активные
bash scripts/adgroups.sh --campaign <id>           # группы в кампании
bash scripts/ads.sh --campaign <id>                # объявления (тексты + URL)
bash scripts/keywords.sh --campaign <id>           # ключевые слова со ставками
```

### Ставки и корректировки
```bash
bash scripts/bids.sh --campaign <id>               # текущие ставки, аукционные, конкурентов
bash scripts/bid-modifiers.sh --campaign <id>      # корректировки по мобильным/демографии/регионам
```

### Аудитории и таргетинг
```bash
bash scripts/audience-targets.sh --adgroup <id>    # ретаргетинг и аудиторные цели
bash scripts/feeds.sh --id <feed_id>               # товарные фиды (Smart Banners / Performance)
```

### Расширения объявлений
```bash
bash scripts/sitelinks.sh                          # быстрые ссылки (авто-собирает из объявлений)
bash scripts/vcards.sh                             # виртуальные визитки (контакты)
```

### Минус-слова и история
```bash
bash scripts/negative-keywords.sh --id <set_id>    # наборы минус-фраз
bash scripts/change-states.sh --since 2024-05-01T00:00:00Z  # что изменилось
```

### Прогноз и отчёты
```bash
bash scripts/forecast.sh "адвокат екатеринбург" "уголовный адвокат"  # есть ли спрос
bash scripts/forecast.sh --region 213 "доставка"                     # регион Москва=213
bash scripts/report.sh <campaign_id>                                  # отчёт за 30 дней
bash scripts/report.sh <campaign_id> --from 2026-05-01 --to 2026-05-14
```

Отчёт: TSV с Date, Impressions, Clicks, Cost, Ctr, AvgCpc, Conversions. Async polling — Direct может отдать `201` пока отчёт готовится.

### ОРД РКН
```bash
bash scripts/ord-documents.sh                      # ОРД-настройки кампаний (counter_ids, SocialDemo)
```
*Примечание:* полная erid-маркировка проходит через сторонний ОРД-оператор, в Direct API только мета-настройки.

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
