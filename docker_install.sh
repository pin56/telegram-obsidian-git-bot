#!/bin/bash

# Telegram Obsidian Git Bot - Docker Installer
# Автор: pin56
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка root прав
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Этот скрипт не должен запускаться с правами root"
        exit 1
    fi
}

# Проверка системы
check_system() {
    print_info "Проверка системы..."
    
    # Проверка ОС
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Этот скрипт поддерживает только Linux"
        exit 1
    fi
    
    # Проверка Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен. Установите Docker и попробуйте снова"
        exit 1
    fi
    
    # Проверка Docker Compose
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose не установлен. Установите Docker Compose и попробуйте снова"
        exit 1
    fi
    
    # Проверка Git
    if ! command -v git &> /dev/null; then
        print_error "Git не установлен. Установите Git и попробуйте снова"
        exit 1
    fi
    
    print_success "Система готова к установке"
}

# Получение параметров от пользователя
get_user_input() {
    print_info "Настройка параметров бота..."
    
    # Telegram Bot Token
    while true; do
        read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
        if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
            break
        else
            print_error "Token не может быть пустым"
        fi
    done
    
    # User ID
    while true; do
        read -p "Введите ваш Telegram User ID (или несколько через запятую): " USER_ID
        if [[ -n "$USER_ID" ]]; then
            break
        else
            print_error "User ID не может быть пустым"
        fi
    done
    
    # GitHub Token
    while true; do
        read -p "Введите GitHub Personal Access Token: " GIT_TOKEN
        if [[ -n "$GIT_TOKEN" ]]; then
            break
        else
            print_error "GitHub Token не может быть пустым"
        fi
    done
    
    # Имя файла в Obsidian
    read -p "Введите имя файла в Obsidian vault (по умолчанию: daily.md): " FILE_NAME
    FILE_NAME=${FILE_NAME:-daily.md}
    
    # GitHub репозиторий
    read -p "Введите URL вашего GitHub репозитория (по умолчанию: https://github.com/pin-obs/obs-vault.git): " REPO_URL_CLEAN
    REPO_URL_CLEAN=${REPO_URL_CLEAN:-https://github.com/pin-obs/obs-vault.git}
    
    # Формируем URL с токеном для использования в приложении
    REPO_URL="https://${GIT_TOKEN}@${REPO_URL_CLEAN#https://}"
    
    print_success "Параметры получены"
}

# Создание Dockerfile
create_dockerfile() {
    print_info "Создание Dockerfile..."
    
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY . .

# Создание директории для Obsidian файлов
RUN mkdir -p obsidian_files

# Настройка Git
RUN git config --global user.name "Telegram Bot"
RUN git config --global user.email "bot@telegram.com"

# Создание пользователя для запуска приложения
RUN useradd -m -u 1000 botuser && chown -R botuser:botuser /app
USER botuser

# Команда по умолчанию
CMD ["python", "bot.py"]
EOF

    print_success "Dockerfile создан"
    
    # Создание .dockerignore
    cat > .dockerignore << 'EOF'
.git
.gitignore
README.md
.env
obsidian_files/
logs/
*.log
Dockerfile
docker-compose.yml
.dockerignore
EOF

    print_success ".dockerignore создан"
}

# Создание docker-compose.yml
create_docker_compose() {
    print_info "Создание docker-compose.yml..."
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  telegram-bot:
    build: .
    container_name: telegram-obsidian-bot
    restart: unless-stopped
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - USER_ID=${USER_ID}
      - GIT_TOKEN=${GIT_TOKEN}
      - FILE_NAME=${FILE_NAME}
      - REPO_URL=${REPO_URL}
    volumes:
      - ./obsidian_files:/app/obsidian_files
      - ./logs:/app/logs
    networks:
      - bot-network

networks:
  bot-network:
    driver: bridge
EOF

    print_success "docker-compose.yml создан"
}

# Создание .env файла
create_env_file() {
    print_info "Создание .env файла..."
    
    cat > .env << EOF
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
USER_ID=${USER_ID}

# GitHub Configuration
GIT_TOKEN=${GIT_TOKEN}
FILE_NAME=${FILE_NAME}

# Repository Configuration
REPO_URL=${REPO_URL}
REPO_URL_CLEAN=${REPO_URL_CLEAN}
EOF

    print_success ".env файл создан"
}

# Создание systemd сервиса
create_systemd_service() {
    print_info "Создание systemd сервиса..."
    
    sudo tee /etc/systemd/system/telegram-obsidian-bot.service > /dev/null << EOF
[Unit]
Description=Telegram Obsidian Git Bot
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
    ExecStart=/usr/bin/docker compose up -d
    ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

    print_success "systemd сервис создан"
}

# Создание скриптов управления
create_management_scripts() {
    print_info "Создание скриптов управления..."
    
    # Скрипт запуска
    cat > telegram-bot-docker << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.." 2>/dev/null || cd /opt/telegram-obsidian-bot

case "$1" in
    start)
        docker compose up -d
        echo "Бот запущен"
        ;;
    stop)
        docker compose down
        echo "Бот остановлен"
        ;;
    restart)
        docker compose restart
        echo "Бот перезапущен"
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f
        ;;
    shell)
        docker compose exec telegram-bot /bin/bash
        ;;
    update)
        git pull
        docker compose build --no-cache
        docker compose up -d
        echo "Бот обновлен и перезапущен"
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|shell|update}"
        exit 1
        ;;
esac
EOF

    chmod +x telegram-bot-docker
    
    # Перемещение в /usr/local/bin
    sudo mv telegram-bot-docker /usr/local/bin/
    
    # Создание символической ссылки для удобства
    sudo ln -sf /usr/local/bin/telegram-bot-docker /usr/local/bin/telegram-bot
    
    print_success "Скрипты управления созданы"
}

# Создание директорий
create_directories() {
    print_info "Создание необходимых директорий..."
    
    mkdir -p obsidian_files
    mkdir -p logs
    
    print_success "Директории созданы"
}

# Настройка Git
setup_git() {
    print_info "Настройка Git..."
    
    # Клонирование репозитория если он не существует
    if [[ ! -d "obsidian_files/.git" ]]; then
        print_info "Клонирование репозитория..."
        git clone "${REPO_URL_CLEAN}" obsidian_files || {
            print_warning "Не удалось клонировать репозиторий. Создаем пустую директорию."
            mkdir -p obsidian_files
        }
    fi
    
    print_success "Git настроен"
}

# Сборка и запуск Docker контейнера
build_and_run() {
    print_info "Сборка Docker образа..."
    docker compose build --no-cache
    
    print_info "Запуск контейнера..."
    docker compose up -d
    
    print_success "Контейнер запущен"
}

# Настройка автозапуска
setup_autostart() {
    print_info "Настройка автозапуска..."
    
    # Перезагрузка systemd
    sudo systemctl daemon-reload
    
    # Включение автозапуска
    sudo systemctl enable telegram-obsidian-bot.service
    
    print_success "Автозапуск настроен"
}

# Проверка работы
check_status() {
    print_info "Проверка статуса бота..."
    
    sleep 10
    
    if docker compose ps | grep -q "Up"; then
        print_success "Бот успешно запущен!"
        print_info "Для просмотра логов используйте: telegram-bot logs"
        print_info "Для остановки используйте: telegram-bot stop"
        print_info "Для перезапуска используйте: telegram-bot restart"
        print_info "Для входа в контейнер используйте: telegram-bot shell"
    else
        print_error "Бот не запустился. Проверьте логи: telegram-bot logs"
        docker compose logs
        exit 1
    fi
}

# Основная функция установки
main() {
    print_info "Начинаем установку Telegram Obsidian Git Bot..."
    
    check_root
    check_system
    get_user_input
    create_dockerfile
    create_docker_compose
    create_env_file
    create_directories
    setup_git
    create_management_scripts
    create_systemd_service
    build_and_run
    setup_autostart
    check_status
    
    # Создание README для установки
    cat > INSTALL_INFO.md << EOF
# Telegram Obsidian Git Bot - Информация об установке

## Установленные компоненты

- **Docker контейнер**: telegram-obsidian-bot
- **Systemd сервис**: telegram-obsidian-bot.service
- **Скрипты управления**: telegram-bot, telegram-bot-docker

## Конфигурация

- **Telegram Bot Token**: ${TELEGRAM_BOT_TOKEN}
- **User ID**: ${USER_ID}
- **GitHub Token**: ${GIT_TOKEN}
- **Файл Obsidian**: ${FILE_NAME}
- **Репозиторий**: ${REPO_URL_CLEAN}

## Команды управления

\`\`\`bash
telegram-bot start      # запустить
telegram-bot stop       # остановить
telegram-bot restart    # перезапустить
telegram-bot status     # статус
telegram-bot logs       # логи
telegram-bot shell      # войти в контейнер
telegram-bot update     # обновить
\`\`\`

## Автозапуск

Бот настроен на автоматический запуск при загрузке системы.

## Логи

Логи сохраняются в директории \`logs/\` и доступны через команду \`telegram-bot logs\`.

## Удаление

Для удаления бота выполните:

\`\`\`bash
./docker_install.sh uninstall
\`\`\`
EOF

    print_success "Установка завершена успешно!"
    print_info "Бот будет автоматически запускаться при загрузке системы"
    print_info "Информация об установке сохранена в файле INSTALL_INFO.md"
}

# Обработка аргументов командной строки
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        print_info "Удаление Telegram Obsidian Git Bot..."
        docker compose down
        sudo systemctl disable telegram-obsidian-bot.service
        sudo rm -f /etc/systemd/system/telegram-obsidian-bot.service
        sudo rm -f /usr/local/bin/telegram-bot-docker
        sudo rm -f /usr/local/bin/telegram-bot
        sudo systemctl daemon-reload
        print_success "Бот удален"
        ;;
    *)
        echo "Использование: $0 {install|uninstall}"
        exit 1
        ;;
esac 