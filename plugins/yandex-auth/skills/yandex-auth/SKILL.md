---
name: yandex-auth
description: |
  Единый OAuth-flow для всех скиллов экосистемы Яндекса. Выпускает один
  токен через приложение «Я-Клауд-Клиентс» (client_id 2f69a4396d68...),
  сохраняет в ~/.claude/secrets/yandex-app.json. Остальные плагины
  yandex-* читают токен оттуда автоматически.
  Triggers: yandex auth, яндекс авторизация, яндекс токен, выпустить токен
  яндекс, обновить токен яндекс, проверить токен яндекс.
---

# yandex-auth — единая точка авторизации

Базовый плагин пакета `claude-yandex-skills`. Без него остальные скиллы (metrika, webmaster, direct, forms и т.д.) не работают — они ходят за токеном сюда.

## Как использовать

### Первый раз (выпустить токен)

```bash
bash plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh
```

Что произойдёт:
1. Откроется браузер на authorize-странице Яндекса.
2. Юзер логинится под нужным аккаунтом и жмёт «Разрешить».
3. Скрипт ловит `access_token` из адресной строки (юзер копирует и вставляет).
4. Валидирует через `https://login.yandex.ru/info` (узнаёт login + user_id).
5. Сохраняет в `~/.claude/secrets/yandex-app.json` с правами 600.

### Проверить статус

```bash
bash plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh --status
```

Покажет аккаунт, дату выпуска и проверит токен живым запросом.

### Из других плагинов

Каждый yandex-* плагин в своих скриптах:

```sh
. "$HOME/.claude/skills/yandex-auth/scripts/common.sh"  # путь после установки
yandex_load_token   # экспортирует YANDEX_ACCESS_TOKEN, YANDEX_LOGIN, YANDEX_USER_ID

curl -H "$(yandex_auth_header)" "https://api.metrika.yandex.net/management/v1/counters"
```

## Файл с токеном

`~/.claude/secrets/yandex-app.json`:
```json
{
  "access_token": "...",
  "client_id": "2f69a4396d684385a5f6578dd5eb7863",
  "issued_at": "2026-05-05T15:30:00Z",
  "expires_at_estimate": "2027-05-05T15:30:00Z",
  "yandex_login": "andrey...",
  "yandex_user_id": "1234567"
}
```

⚠️ **Файл секретный.** Права 600. Не коммитить, не пересылать.

## Когда токен умер

Yandex implicit-flow токены живут до ~1 года, могут быть отозваны раньше:
- юзер сменил пароль
- юзер вручную отозвал в `https://id.yandex.ru/security/apps`
- приложение заблокировано Яндексом

Восстановление — `oauth-flow.sh` ещё раз.

## Scope

Scope в authorize-URL не передаём → юзер получает **все scope**, которые
админ вшил в приложение в кабинете `oauth.yandex.ru/client/`.

Если в приложение добавили новый сервис — старый токен новый scope не
покрывает. Нужно переавторизоваться (`oauth-flow.sh`) — Яндекс выдаст
обновлённый токен с расширенным scope.

⚠️ **Wordstat scope** требует ручной заявки в поддержку Яндекса.
Получают не все. Если у юзера нет доступа к Wordstat — общий токен всё
равно работает, просто `yandex-wordstat` будет ловить 403 от Яндекса.
