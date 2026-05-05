# yandex-direct — конфигурация

Этот скилл использует **общий** OAuth-токен Яндекса, выпущенный через плагин `yandex-auth`.

## Откуда берётся токен

```
~/.claude/secrets/yandex-app.json
```

Файл создаётся командой `yandex-auth/scripts/oauth-flow.sh`. Один токен покрывает все scope'ы, которые включены в OAuth-приложение «Я-Клауд-Клиентс» — в том числе `direct:api` для этого скилла.

## Если токена нет

Запусти:
```bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh
```

Подробнее — в `yandex-auth/SKILL.md`.

## Дополнительные настройки

Если для `yandex-direct` нужны какие-то отдельные параметры (URL клиента, идентификаторы организации и т.д.) — клади их в `config/.env` рядом с этим файлом. Шаблон — `.env.example`.
