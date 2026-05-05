---
name: yandex-disk
description: |
  Облако Яндекс.Диск через REST API: файлы, папки, публикация ссылок. Также fallback на WebDAV.
  Использует общий OAuth-токен Яндекса (плагин yandex-auth). Cache-first,
  лимит stdout 30 строк по умолчанию.
  Triggers: yandex-disk, disk, яндекс disk.
---

# yandex-disk

Облако Яндекс.Диск через REST API: файлы, папки, публикация ссылок. Также fallback на WebDAV.

## Конфигурация

Скилл ходит за токеном в общий файл `~/.claude/secrets/yandex-app.json`, который выпускает плагин `yandex-auth`. Если токен не выпущен — скрипты выдадут ошибку с инструкцией запустить `yandex-auth/oauth-flow.sh`.

Scope в OAuth-приложении: `cloud_api:disk.read,cloud_api:disk.write,cloud_api:disk.info`.

## Принципы

1. **Cache-first** — конфигурационные данные (списки, метаданные) кешируются надолго; отчёты и live-данные — короткий TTL или без кеша.
2. **Гигиена контекста** — stdout по умолчанию ограничен 30 строками. Полные данные пишутся в файл (CSV/JSON), доступны через grep/rg.
3. **Никаких токенов в скилле** — только общий из `yandex-auth`. Не дублируем `.env` под каждый сервис.
4. **No destructive ops by default** — пишущие методы есть, но они должны быть явно вызваны и предупреждать пользователя.

## API

База: `https://cloud-api.yandex.net/v1/disk`

Документация: см. `references/` (по мере наполнения).

## Workflow

### Sanity-check

```bash
bash scripts/info.sh
```

Должен вывести аккаунт, total/used/trash в GB.

### Типичный сценарий

```bash
bash scripts/list.sh /Загрузки                # посмотреть что в папке
bash scripts/upload.sh ./report.pdf /Отчёты/  # положить файл
bash scripts/download.sh /Отчёты/report.pdf   # скачать
bash scripts/publish.sh /Отчёты/report.pdf    # публичная ссылка
bash scripts/search.sh "договор"               # найти по имени
```

## Скрипты

| Скрипт | Назначение | Аргументы |
|---|---|---|
| `info.sh` | Account info, использование диска | `[--json]` |
| `list.sh` | Содержимое папки (имя, размер, дата) | `[PATH] [--limit N] [--json] [--full]` |
| `upload.sh` | Загрузить локальный файл на Диск | `<local> <remote> [--overwrite]` |
| `download.sh` | Скачать файл с Диска | `<remote> [local]` |
| `publish.sh` | Опубликовать → получить публичную ссылку | `<remote>` |
| `search.sh` | Поиск по имени файла | `<query> [N]` |
| `common.sh` | Shared: load_token, call, cache, limit_output | — |

## Особенности

- **Пути**: `disk:/foo` или `/foo` — оба работают, скрипты сами нормализуют. Кириллица URL-кодируется автоматически.
- **Rate limit**: read ≈ 40 req/sec, write ≈ 10 req/sec. Для batch-операций добавь `sleep 0.1` между вызовами.
- **Trash**: при удалении файлы попадают в корзину. REST для Trash есть, но не реализован тут.
- **WebDAV**: альтернативный путь — `https://webdav.yandex.ru` с Basic-auth. Не реализован (REST покрывает 95% задач).

## Ссылки

- yandex-auth: `../../yandex-auth/skills/yandex-auth/`
- Marketplace: `../../../.claude-plugin/marketplace.json`
