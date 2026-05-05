---
name: yandex-wordstat
description: |
  Анализ поискового спроса через Yandex Wordstat. Топ запросов, динамика,
  региональная статистика. Поддержка двух backend'ов: legacy OAuth (для
  существующих пользователей с одобренной заявкой) и cloud IAM (для новых,
  через Yandex Cloud Search API). Auto-dispatcher выбирает по конфигу.
  Triggers: wordstat, вордстат, поисковый спрос, частотность запросов,
  семантическое ядро, сезонность.
---

# yandex-wordstat

Анализ поискового спроса в Яндексе. **Один скилл, два бэкенда.**

## Backends

| Backend | Когда использовать | Конфиг | Доступ |
|---|---|---|---|
| `legacy` | Если есть одобренная заявка в Директе под прошлым приложением (`YANDEX_WORDSTAT_TOKEN`) | `YANDEX_WORDSTAT_TOKEN` в `.env` | Yandex закрыл onboarding для новых юзеров |
| `cloud` | Yandex Cloud Search API v2 — preview, для новых пользователей | `YANDEX_CLOUD_FOLDER_ID` + `YANDEX_CLOUD_SA_KEY_FILE` | SA с ролью `search-api.user` |
| auto | Auto-resolve | Если есть SA-key → cloud, иначе → legacy | по контексту |

Override через `YANDEX_WORDSTAT_BACKEND=legacy|cloud` в `config/.env`.

## Configuration

### Legacy (для существующих пользователей)

```
# config/.env
YANDEX_WORDSTAT_TOKEN=<approved-oauth-token>
```

Если у тебя был отдельный OAuth-app под Wordstat с одобренной заявкой — токен оттуда работает here as-is.

Если такого нет, скилл попробует использовать общий токен из `yandex-auth/secrets/yandex-app.json`. Скорее всего вернёт 403, потому что новые приложения не получают `direct:api-stats` scope автоматически.

### Cloud (для новых пользователей)

```
# config/.env
YANDEX_WORDSTAT_BACKEND=cloud
YANDEX_CLOUD_FOLDER_ID=b1g0123456789abc
YANDEX_CLOUD_SA_KEY_FILE=/Users/<USER>/.claude/secrets/yandex-cloud-sa-key.json
```

Создание SA и выпуск ключа:

```bash
yc iam service-account create --name claude-wordstat
yc iam key create --service-account-name claude-wordstat \
  --output ~/.claude/secrets/yandex-cloud-sa-key.json
yc resource-manager folder add-access-binding <folder-id> \
  --role search-api.user \
  --service-account-name claude-wordstat
```

Скилл сам генерит JWT (PS256), обменивает на IAM token, кеширует на 1 час.

## Workflow

### Sanity-check

```bash
bash scripts/top-requests.sh "таргетолог" --limit 5
```

Должен вывести шапку с `backend: legacy|cloud`, total volume и top-N запросов.

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `top-requests.sh` | Топ запросов по фразе с частотностью | `<phrase> [--region 225] [--limit 30] [--json] [--full]` |
| `common.sh` | Backend dispatcher, JWT/IAM helper, call wrappers | — |

## Регионы

`225` — Россия (default). Список region IDs: https://yandex.ru/dev/wordstat/doc/concepts/geographyRussia.html

Несколько регионов через запятую: `--region 225,213,2`.

## Особенности

- **Cloud caveat**: при `dynamics` operator restriction — для weekly/monthly работает только оператор `+`. Минус-слова, кавычки и группировки — только daily.
- **Rate limit**: легаси — 1000 запросов/день на токен. Cloud — по квоте Yandex Cloud.
- **Кеш**: `cache/iam_token.txt` хранит IAM на 1 час (cloud backend).
