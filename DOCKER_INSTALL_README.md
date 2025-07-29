# Docker Installer для Telegram Obsidian Git Bot

## Быстрая установка

```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/pin56/telegram-obsidian-git-bot/main/docker_install.sh
chmod +x docker_install.sh

# Запустить установку
./docker_install.sh
```

## Что делает скрипт

1. **Проверяет систему** - убеждается, что установлены Docker, Docker Compose и Git
2. **Запрашивает параметры** - собирает все необходимые токены и настройки
3. **Создает Dockerfile** - настраивает контейнер с Python и зависимостями
4. **Создает docker-compose.yml** - конфигурирует сервис с переменными окружения
5. **Настраивает Git** - клонирует репозиторий для Obsidian файлов
6. **Создает systemd сервис** - настраивает автозапуск
7. **Создает скрипты управления** - добавляет команды `telegram-bot`
8. **Собирает и запускает** - создает образ и запускает контейнер

## Требования

- Linux система
- Docker (с встроенным Docker Compose)
- Git
- Telegram Bot Token
- GitHub Personal Access Token
- Telegram User ID

## Команды управления

После установки используйте:

```bash
telegram-bot start      # запустить
telegram-bot stop       # остановить
telegram-bot restart    # перезапустить
telegram-bot status     # статус
telegram-bot logs       # логи
telegram-bot shell      # войти в контейнер
telegram-bot update     # обновить
```

## Удаление

```bash
./docker_install.sh uninstall
```

## Структура после установки

```
telegram-obsidian-git-bot/
├── Dockerfile              # Docker образ
├── docker-compose.yml      # Конфигурация Docker
├── .env                    # Переменные окружения
├── .dockerignore           # Исключения для Docker
├── obsidian_files/         # Obsidian файлы (монтируется)
├── logs/                   # Логи (монтируется)
├── INSTALL_INFO.md         # Информация об установке
└── docker_install.sh       # Скрипт установки
```

## Автозапуск

Бот автоматически запускается при загрузке системы через systemd сервис.

## Безопасность

- Все токены хранятся в `.env` файле
- Контейнер запускается от непривилегированного пользователя
- Файлы монтируются как volumes для сохранения данных 