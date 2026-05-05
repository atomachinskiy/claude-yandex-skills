# yandex-metrika — конфигурация

Этот скилл использует **общий** OAuth-токен Яндекса, выпущенный через плагин `yandex-auth`.

## Откуда берётся токен

```
~/.claude/secrets/yandex-app.json
```

Файл создаётся командой `yandex-auth/scripts/oauth-flow.sh`. Один токен покрывает все scope'ы, которые включены в OAuth-приложение «Я-Клауд-Клиентс» — в том числе `metrika:read,metrika:write,metrika:expenses,metrika:user_params` для этого скилла.

## Если токена нет

```bash
bash ~/Workspaces/claude-yandex-skills/plugins/yandex-auth/skills/yandex-auth/scripts/oauth-flow.sh
```

## Дополнительные настройки

Скилл-специфичные параметры — в `config/.env` (если нужны). Шаблон — `.env.example`.
