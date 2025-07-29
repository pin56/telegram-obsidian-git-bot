# Telegram Obsidian Git Bot

Telegram бот для автоматического сохранения сообщений в Obsidian vault через Git.

## Описание

Этот бот позволяет автоматически сохранять сообщения из Telegram в ваш Obsidian vault, который синхронизируется через Git. Бот поддерживает:

- Сохранение текстовых сообщений
- Сохранение пересланных сообщений с указанием автора
- Автоматическую синхронизацию с GitHub
- Автозапуск при загрузке системы
- Автоматическое обновление

## Быстрая установка



### 1. Интерактивная установка (рекомендуется)
```bash
wget https://raw.github.com/pin56/telegram-obsidian-git-bot/main/install.sh
chmod +x install.sh
sudo ./install.sh
```


### 2. Docker установка (рекомендуется)
```bash
wget https://raw.githubusercontent.com/pin56/telegram-obsidian-git-bot/main/docker_install.sh
chmod +x docker_install.sh
./docker_install.sh
```

## Подготовка

### Получение Telegram Bot Token
1. Найдите @BotFather в Telegram
2. Отправьте `/newbot`
3. Следуйте инструкциям
4. Сохраните токен

### Получение GitHub Personal Access Token
1. GitHub → Settings → Developer settings → Personal access tokens
2. Создайте токен с правами `repo`
3. Сохраните токен

### Получение Telegram User ID
1. Найдите @userinfobot в Telegram
2. Отправьте любое сообщение
3. Сохраните User ID

## Управление ботом

После установки используйте команды:

```bash
# Обычная установка
telegram-bot start      # запустить
telegram-bot stop       # остановить
telegram-bot restart    # перезапустить
telegram-bot status     # статус
telegram-bot logs       # логи
telegram-bot update     # обновить
telegram-bot config     # конфигурация

# Docker установка
telegram-bot start      # запустить
telegram-bot stop       # остановить
telegram-bot restart    # перезапустить
telegram-bot status     # статус
telegram-bot logs       # логи
telegram-bot shell      # войти в контейнер
telegram-bot update     # обновить
```

## Конфигурация

Переменные окружения в `.env` файле:

| Переменная | Описание | Пример |
|------------|----------|--------|
| `TELEGRAM_BOT_TOKEN` | Токен Telegram бота | `123456789:ABCdefGHIjklMNOpqrsTUVwxyz` |
| `USER_ID` | ID пользователей Telegram | `123456789` или `123456789,987654321` |
| `GIT_TOKEN` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxxxxxxxxxx` |
| `FILE_NAME` | Имя файла в Obsidian vault | `daily.md` |

## Структура проекта

```
telegram-obsidian-git-bot/
├── bot.py              # Основной файл бота
├── redactor.py         # Модуль для работы с Git и Obsidian
├── requirements.txt    # Python зависимости
├── install.sh          # Интерактивный установщик
├── quick-install.sh    # Быстрый установщик
├── docker_install.sh   # Docker установщик
├── check-system.sh     # Проверка системы
├── INSTALL.md          # Подробная инструкция
└── README.md           # Этот файл
```

## Автоматические функции

- **Автозапуск**: Бот автоматически запускается при загрузке системы
- **Автообновление**: Обновление каждые 6 часов
- **Автоперезапуск**: При сбоях бот автоматически перезапускается

## Устранение неполадок

### Проверка статуса
```bash
telegram-bot status
```

### Просмотр логов
```bash
telegram-bot logs
```

### Проверка конфигурации
```bash
cat /opt/telegram-obsidian-bot/.env
```

### Обновление бота
```bash
telegram-bot update
```

## Удаление

```bash
# Обычная установка
sudo ./install.sh uninstall

# Docker установка
./docker_install.sh uninstall
```

## Требования

- Linux (Ubuntu, Debian, CentOS, Fedora, Arch Linux)
- Python 3.7+ (для обычной установки)
- Docker (с встроенным Docker Compose) (для Docker установки)
- Git
- Root права (sudo)

## Поддержка

При возникновении проблем:

1. Проверьте логи: `telegram-bot logs`
2. Убедитесь, что все переменные окружения настроены
3. Проверьте права доступа к GitHub репозиторию
4. Убедитесь, что бот добавлен в чат

## Безопасность

- Храните токены в безопасном месте
- Не публикуйте .env файл
- Регулярно обновляйте токены
- Используйте отдельного пользователя для запуска бота

## Лицензия

MIT License

## Автор

pin56 - [GitHub](https://github.com/pin56)

