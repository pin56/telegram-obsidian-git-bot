#!/bin/bash

# Telegram Obsidian Git Bot Docker Installer
# Автор: pin56
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Константы
CONTAINER_NAME="telegram-obsidian-bot"
IMAGE_NAME="telegram-obsidian-bot"
DATA_DIR="/opt/telegram-obsidian-bot-data"

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

# Проверка Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен. Установите Docker и попробуйте снова."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker не запущен или у вас нет прав. Запустите Docker и попробуйте снова."
        exit 1
    fi
    
    # Проверяем доступность docker compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose не доступен. Убедитесь, что у вас установлена современная версия Docker."
        exit 1
    fi
}

# Создание Dockerfile
create_dockerfile() {
    print_info "Создание Dockerfile..."
    
    cat > Dockerfile << 'EOF'
FROM python:3.9-slim

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
RUN pip install --no-cache-dir GitPython

# Клонирование репозитория
RUN git clone https://github.com/pin56/telegram-obsidian-git-bot.git .

# Создание директории для данных
RUN mkdir -p /app/obsidian_files

# Создание пользователя
RUN useradd -m -u 1000 botuser && chown -R botuser:botuser /app
USER botuser

# Переменные окружения
ENV PYTHONUNBUFFERED=1

# Команда запуска
CMD ["python", "bot.py"]
EOF
    
    print_success "Dockerfile создан"
}

# Создание docker compose.yml
create_docker_compose() {
    print_info "Создание docker compose.yml..."
    
    cat > docker compose.yml << EOF
version: '3.8'

services:
  telegram-obsidian-bot:
    build: .
    container_name: $CONTAINER_NAME
    restart: unless-stopped
    volumes:
      - $DATA_DIR:/app/obsidian_files
      - ./env:/app/.env
    environment:
      - PYTHONUNBUFFERED=1
    networks:
      - bot-network

networks:
  bot-network:
    driver: bridge
EOF
    
    print_success "docker compose.yml создан"
}

# Создание .env файла
create_env_file() {
    print_info "Создание .env файла..."
    
    if [ ! -f "env" ]; then
        touch env
    fi
    
    # Функция для обновления переменной в .env
    update_env_var() {
        local var_name=$1
        local var_desc=$2
        local current_value=$(grep "^${var_name}=" env | cut -d'=' -f2- 2>/dev/null || echo "")
        
        echo ""
        print_info "$var_desc"
        if [ ! -z "$current_value" ]; then
            echo "Текущее значение: $current_value"
        fi
        read -p "Введите новое значение (или нажмите Enter для пропуска): " new_value
        
        if [ ! -z "$new_value" ]; then
            # Удаляем старую строку если есть
            sed -i "/^${var_name}=/d" env
            # Добавляем новую строку
            echo "${var_name}=${new_value}" >> env
            print_success "$var_name обновлен"
        fi
    }
    
    # Настройка переменных
    update_env_var "TELEGRAM_BOT_TOKEN" "Telegram Bot Token (получите у @BotFather)"
    update_env_var "USER_ID" "ID пользователей Telegram (через запятую для нескольких)"
    update_env_var "GIT_TOKEN" "GitHub Personal Access Token"
    update_env_var "FILE_NAME" "Имя файла в Obsidian vault (например: daily.md)"
    
    print_success ".env файл создан"
}

# Создание скрипта управления
create_management_script() {
    print_info "Создание скрипта управления..."
    
    cat > /usr/local/bin/telegram-bot-docker << 'EOF'
#!/bin/bash

CONTAINER_NAME="telegram-obsidian-bot"

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
        update)
            docker compose down
            docker compose build --no-cache
            docker compose up -d
            echo "Обновление завершено!"
            ;;
        config)
            nano env
            docker compose restart
            ;;
        shell)
            docker compose exec telegram-obsidian-bot bash
            ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|update|config|shell}"
        echo "  start   - запустить бота"
        echo "  stop    - остановить бота"
        echo "  restart - перезапустить бота"
        echo "  status  - показать статус"
        echo "  logs    - показать логи"
        echo "  update  - обновить бота"
        echo "  config  - редактировать конфигурацию"
        echo "  shell   - войти в контейнер"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/telegram-bot-docker
    
    print_success "Скрипт управления создан"
}

# Создание директории для данных
create_data_dir() {
    print_info "Создание директории для данных..."
    
    mkdir -p $DATA_DIR
    chmod 755 $DATA_DIR
    
    print_success "Директория для данных создана"
}

# Сборка и запуск
build_and_run() {
    print_info "Сборка Docker образа..."
    docker compose build
    
    print_info "Запуск контейнера..."
    docker compose up -d
    
    print_success "Контейнер запущен"
}

# Основная функция установки
main_install() {
    print_info "Начинаем установку Telegram Obsidian Git Bot в Docker..."
    
    check_docker
    create_data_dir
    create_dockerfile
    create_docker_compose
    create_env_file
    create_management_script
    build_and_run
    
    print_success "Установка завершена!"
    echo ""
    print_info "Команды управления:"
    echo "  telegram-bot-docker start   - запустить бота"
    echo "  telegram-bot-docker stop    - остановить бота"
    echo "  telegram-bot-docker status  - показать статус"
    echo "  telegram-bot-docker logs    - показать логи"
    echo "  telegram-bot-docker update  - обновить бота"
    echo "  telegram-bot-docker config  - редактировать конфигурацию"
    echo "  telegram-bot-docker shell   - войти в контейнер"
    echo ""
    print_info "Данные сохраняются в $DATA_DIR"
    print_info "Конфигурация в файле env"
}

# Функция удаления
uninstall() {
    print_warning "Удаление Telegram Obsidian Git Bot..."
    
    # Остановка и удаление контейнеров
    docker compose down 2>/dev/null || true
    docker rmi $IMAGE_NAME 2>/dev/null || true
    
    # Удаление файлов
    rm -f /usr/local/bin/telegram-bot-docker
    rm -f Dockerfile
    rm -f docker compose.yml
    rm -f env
    
    print_success "Удаление завершено!"
    print_info "Директория $DATA_DIR сохранена. Удалите её вручную если нужно."
}

# Обработка аргументов командной строки
case "${1:-install}" in
    install)
        main_install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Использование: $0 {install|uninstall}"
        echo "  install   - установка (по умолчанию)"
        echo "  uninstall - удаление"
        exit 1
        ;;
esac 