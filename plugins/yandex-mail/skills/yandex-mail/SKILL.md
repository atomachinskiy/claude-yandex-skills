---
name: yandex-mail
description: |
  Яндекс.Почта через IMAP с XOAUTH2 (общий yandex-auth токен вместо пароля).
  Список папок, счётчик INBOX, поиск писем.
  Triggers: yandex mail, яндекс почта, почта, imap, inbox, входящие.
---

# yandex-mail

IMAP/SMTP клиент через XOAUTH2. Использует общий токен из `yandex-auth` как Bearer вместо пароля.

## Активация

⚠️ **Требует двух предварительных шагов:**

1. **Scope `mail:imap_full`** должен быть включён в OAuth-app «Я-Клауд-Клиентс». Если нет — добавить в кабинете oauth.yandex.ru, перевыпустить токен через `yandex-auth/oauth-flow.sh`.
2. **IMAP-доступ должен быть разрешён** в настройках Яндекс.Почты:
   https://mail.yandex.ru/?uid=...#setup/client → «С сервера imap.yandex.ru по протоколу IMAP» → включить.

Пока эти два шага не сделаны — скрипты возвращают `[UNAVAILABLE] AUTHENTICATE internal server error`.

## Скрипты

| Скрипт | Назначение |
|---|---|
| `list-folders.sh` | Все IMAP-папки в почтовом ящике |
| `inbox-count.sh` | Количество писем в INBOX (всего + непрочитанные) |

## Технические заметки

- Сервер: `imap.yandex.ru:993` (TLS)
- Auth: SASL XOAUTH2 (`user=<email>\x01auth=Bearer <token>\x01\x01` → base64)
- Реализация — Python 3 stdlib (imaplib, base64), без внешних зависимостей
- Email-форма: автоматически добавляется `@yandex.ru` если в логине нет `@`
