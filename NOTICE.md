# Происхождение кода

Основная часть скилла `yandex-direct` (каталог `plugins/yandex-direct/skills/yandex-direct/scripts` и справочники в `references/`) взята из открытого репозитория `artwist-polyakov/polyakov-claude-skills` под лицензией MIT, автор Aleksandr Poliakov. Текст лицензии: `plugins/yandex-direct/skills/yandex-direct/LICENSE-upstream`.

Что изменено при переносе:

- токен читается из `~/.claude/secrets/yandex-direct-app.json`, как во всём паке, и настройка `YANDEX_DIRECT_CLIENT_LOGIN` из прежних версий продолжает работать;
- убраны упоминания сторонних платных сервисов и ссылки на внешний репозиторий, перекрёстные ссылки переведены на скиллы этого пака;
- рядом сохранён прежний shell-контур пака: мастер получения токена, быстрые чтения, ОРД и erid, прогноз бюджета, визитки, история изменений.

Остальные скиллы пака написаны для этого репозитория.
