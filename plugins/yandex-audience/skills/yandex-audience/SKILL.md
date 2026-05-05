---
name: yandex-audience
description: |
  Аудитории Яндекса: создание сегментов, lookalike, использование в Директе и VK Ads.
  Использует общий OAuth-токен Яндекса (плагин yandex-auth). Cache-first,
  лимит stdout 30 строк по умолчанию.
  Triggers: yandex-audience, audience, яндекс audience.
---

⚠️ **Требует дополнительного setup'а** (общий токен из yandex-auth не покрывает этот сервис без активации).

## Probe

```bash
bash scripts/probe.sh
```

Скрипт дёргает основной endpoint, выводит реальный HTTP-код и инструкцию по активации (что нужно сделать чтобы заработало).

## Что нужно для активации

См. вывод `probe.sh` — там пошаговая инструкция (отдельное OAuth-приложение / новый scope / Yandex 360 для бизнеса / отдельный bot-токен).

## После активации

Когда доступ будет — добавим конкретные команды (list, get, create) в `scripts/`. Пока — только probe и общий `call` wrapper в `common.sh` для быстрого тестирования endpoint'ов.
