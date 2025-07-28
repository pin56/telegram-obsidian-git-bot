#!/bin/bash

# Telegram Obsidian Git Bot Installer
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
REPO_URL="https://github.com/pin56/telegram-obsidian-git-bot.git"
BOT_DIR="/opt/telegram-obsidian-bot"
SERVICE_NAME="telegram-obsidian-bot"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

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

# Проверка на root права
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Проверка и установка зависимостей
install_dependencies() {
    print_info "Проверка и установка системных зависимостей..."
    
    # Обновление пакетов
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y python3 python3-pip python3-venv git curl wget
    elif command -v yum &> /dev/null; then
        yum update -y
        yum install -y python3 python3-pip git curl wget
    elif command -v dnf &> /dev/null; then
        dnf update -y
        dnf install -y python3 python3-pip git curl wget
    elif command -v pacman &> /dev/null; then
        pacman -Syu --noconfirm python python-pip git curl wget
    else
        print_error "Неизвестный пакетный менеджер. Установите python3, pip3 и git вручную."
        exit 1
    fi
    
    print_success "Системные зависимости установлены"
}

# Создание пользователя для бота
create_bot_user() {
    print_info "Создание пользователя для бота..."
    
    if ! id "botuser" &>/dev/null; then
        useradd -r -s /bin/bash -d $BOT_DIR botuser
        print_success "Пользователь botuser создан"
    else
        print_info "Пользователь botuser уже существует"
    fi
}

# Клонирование/обновление репозитория
setup_repository() {
    print_info "Настройка репозитория..."
    
    if [ -d "$BOT_DIR" ]; then
        print_info "Обновление существующего репозитория..."
        cd $BOT_DIR
        git fetch --all
        git reset --hard origin/main
        print_success "Репозиторий обновлен"
    else
        print_info "Клонирование репозитория..."
        git clone $REPO_URL $BOT_DIR
        chown -R botuser:botuser $BOT_DIR
        print_success "Репозиторий клонирован"
    fi
}

# Настройка Python окружения
setup_python_env() {
    print_info "Настройка Python окружения..."
    
    cd $BOT_DIR
    
    # Создание виртуального окружения
    python3 -m venv venv
    source venv/bin/activate
    
    # Установка зависимостей
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Установка дополнительных зависимостей для redactor.py
    pip install GitPython
    
    print_success "Python окружение настроено"
}

# Настройка переменных окружения
setup_environment() {
    print_info "Настройка переменных окружения..."
    
    cd $BOT_DIR
    
    # Создание .env файла если его нет
    if [ ! -f ".env" ]; then
        touch .env
        chown botuser:botuser .env
    fi
    
    # Функция для обновления переменной в .env
    update_env_var() {
        local var_name=$1
        local var_desc=$2
        local current_value=$(grep "^${var_name}=" .env | cut -d'=' -f2- 2>/dev/null || echo "")
        
        echo ""
        print_info "$var_desc"
        if [ ! -z "$current_value" ]; then
            echo "Текущее значение: $current_value"
        fi
        read -p "Введите новое значение (или нажмите Enter для пропуска): " new_value
        
        if [ ! -z "$new_value" ]; then
            # Удаляем старую строку если есть
            sed -i "/^${var_name}=/d" .env
            # Добавляем новую строку
            echo "${var_name}=${new_value}" >> .env
            print_success "$var_name обновлен"
        fi
    }
    
    # Настройка переменных
    update_env_var "TELEGRAM_BOT_TOKEN" "Telegram Bot Token (получите у @BotFather)"
    update_env_var "USER_ID" "ID пользователей Telegram (через запятую для нескольких)"
    update_env_var "GIT_TOKEN" "GitHub Personal Access Token"
    update_env_var "FILE_NAME" "Имя файла в Obsidian vault (например: daily.md)"
    
    chown botuser:botuser .env
    print_success "Переменные окружения настроены"
}

# Создание systemd сервиса
create_systemd_service() {
    print_info "Создание systemd сервиса..."
    
    cat > $SERVICE_FILE << EOF
[Unit]
Description=Telegram Obsidian Git Bot
After=network.target

[Service]
Type=simple
User=botuser
Group=botuser
WorkingDirectory=$BOT_DIR
Environment=PATH=$BOT_DIR/venv/bin
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/bot.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Перезагрузка systemd и включение автозапуска
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    
    print_success "Systemd сервис создан и включен в автозапуск"
}

# Создание скрипта обновления
create_update_script() {
    print_info "Создание скрипта автоматического обновления..."
    
    cat > /usr/local/bin/update-telegram-bot << 'EOF'
#!/bin/bash

BOT_DIR="/opt/telegram-obsidian-bot"
SERVICE_NAME="telegram-obsidian-bot"

echo "Обновление Telegram Obsidian Bot..."

# Остановка сервиса
systemctl stop $SERVICE_NAME

# Обновление кода
cd $BOT_DIR
git fetch --all
git reset --hard origin/main

# Обновление зависимостей
source venv/bin/activate
pip install -r requirements.txt

# Запуск сервиса
systemctl start $SERVICE_NAME

echo "Обновление завершено!"
EOF
    
    chmod +x /usr/local/bin/update-telegram-bot
    
    # Создание cron задачи для автоматического обновления (каждые 6 часов)
    (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/update-telegram-bot") | crontab -
    
    print_success "Скрипт обновления создан и настроен cron"
}

# Создание скрипта управления
create_management_script() {
    print_info "Создание скрипта управления..."
    
    cat > /usr/local/bin/telegram-bot << 'EOF'
#!/bin/bash

SERVICE_NAME="telegram-obsidian-bot"

case "$1" in
    start)
        systemctl start $SERVICE_NAME
        echo "Бот запущен"
        ;;
    stop)
        systemctl stop $SERVICE_NAME
        echo "Бот остановлен"
        ;;
    restart)
        systemctl restart $SERVICE_NAME
        echo "Бот перезапущен"
        ;;
    status)
        systemctl status $SERVICE_NAME
        ;;
    logs)
        journalctl -u $SERVICE_NAME -f
        ;;
    update)
        /usr/local/bin/update-telegram-bot
        ;;
    config)
        nano /opt/telegram-obsidian-bot/.env
        systemctl restart $SERVICE_NAME
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|logs|update|config}"
        echo "  start   - запустить бота"
        echo "  stop    - остановить бота"
        echo "  restart - перезапустить бота"
        echo "  status  - показать статус"
        echo "  logs    - показать логи"
        echo "  update  - обновить бота"
        echo "  config  - редактировать конфигурацию"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/telegram-bot
    
    print_success "Скрипт управления создан"
}

# Основная функция установки
main_install() {
    print_info "Начинаем установку Telegram Obsidian Git Bot..."
    
    check_root
    install_dependencies
    create_bot_user
    setup_repository
    setup_python_env
    setup_environment
    create_systemd_service
    create_update_script
    create_management_script
    
    print_success "Установка завершена!"
    echo ""
    print_info "Команды управления:"
    echo "  telegram-bot start   - запустить бота"
    echo "  telegram-bot stop    - остановить бота"
    echo "  telegram-bot status  - показать статус"
    echo "  telegram-bot logs    - показать логи"
    echo "  telegram-bot update  - обновить бота"
    echo "  telegram-bot config  - редактировать конфигурацию"
    echo ""
    print_info "Бот будет автоматически запускаться при загрузке системы"
    print_info "Автоматическое обновление настроено каждые 6 часов"
    echo ""
    print_warning "Не забудьте настроить переменные в .env файле!"
}

# Функция обновления
update_only() {
    print_info "Обновление Telegram Obsidian Git Bot..."
    
    check_root
    setup_repository
    setup_python_env
    create_update_script
    
    print_success "Обновление завершено!"
}

# Функция удаления
uninstall() {
    print_warning "Удаление Telegram Obsidian Git Bot..."
    
    check_root
    
    # Остановка и отключение сервиса
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    systemctl disable $SERVICE_NAME 2>/dev/null || true
    
    # Удаление файлов
    rm -f $SERVICE_FILE
    rm -f /usr/local/bin/telegram-bot
    rm -f /usr/local/bin/update-telegram-bot
    
    # Удаление cron задачи
    crontab -l 2>/dev/null | grep -v "update-telegram-bot" | crontab -
    
    # Перезагрузка systemd
    systemctl daemon-reload
    
    print_success "Удаление завершено!"
    print_info "Директория $BOT_DIR сохранена. Удалите её вручную если нужно."
}

# Обработка аргументов командной строки
case "${1:-install}" in
    install)
        main_install
        ;;
    update)
        update_only
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Использование: $0 {install|update|uninstall}"
        echo "  install   - полная установка (по умолчанию)"
        echo "  update    - только обновление кода"
        echo "  uninstall - удаление бота"
        exit 1
        ;;
esac 