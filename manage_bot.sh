#!/bin/bash

# Telegram Obsidian Bot management script

SERVICE_NAME="telegram-obsidian-bot.service"

case "$1" in
    start)
        echo "Starting Telegram Obsidian Bot..."
        sudo systemctl start $SERVICE_NAME
        ;;
    stop)
        echo "Stopping Telegram Obsidian Bot..."
        sudo systemctl stop $SERVICE_NAME
        ;;
    restart)
        echo "Restarting Telegram Obsidian Bot..."
        sudo systemctl restart $SERVICE_NAME
        ;;
    status)
        echo "Checking Telegram Obsidian Bot status..."
        sudo systemctl status $SERVICE_NAME
        ;;
    logs)
        echo "Showing Telegram Obsidian Bot logs..."
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    enable)
        echo "Enabling Telegram Obsidian Bot to start on boot..."
        sudo systemctl enable $SERVICE_NAME
        ;;
    disable)
        echo "Disabling Telegram Obsidian Bot from starting on boot..."
        sudo systemctl disable $SERVICE_NAME
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|enable|disable}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the bot service"
        echo "  stop    - Stop the bot service"
        echo "  restart - Restart the bot service"
        echo "  status  - Show service status"
        echo "  logs    - Show live logs"
        echo "  enable  - Enable service to start on boot"
        echo "  disable - Disable service from starting on boot"
        exit 1
        ;;
esac
