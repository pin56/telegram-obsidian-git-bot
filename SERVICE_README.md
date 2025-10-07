# Telegram Obsidian Bot - Service Setup

This directory contains files to run the Telegram Obsidian Bot as a systemd service, ensuring it runs continuously and automatically restarts if it crashes.

## Files

- `telegram-obsidian-bot.service` - Systemd service configuration
- `install_service.sh` - Script to install and enable the service
- `manage_bot.sh` - Script to manage the bot service

## Installation

1. Make sure your bot is working correctly by running it manually first:
   ```bash
   python bot.py
   ```

2. Install the service:
   ```bash
   ./install_service.sh
   ```

## Management

Use the management script to control the bot:

```bash
# Start the bot
./manage_bot.sh start

# Stop the bot
./manage_bot.sh stop

# Restart the bot
./manage_bot.sh restart

# Check status
./manage_bot.sh status

# View live logs
./manage_bot.sh logs

# Enable auto-start on boot
./manage_bot.sh enable

# Disable auto-start on boot
./manage_bot.sh disable
```

## Manual Systemd Commands

You can also use systemd commands directly:

```bash
# Check status
sudo systemctl status telegram-obsidian-bot.service

# View logs
sudo journalctl -u telegram-obsidian-bot.service -f

# Restart service
sudo systemctl restart telegram-obsidian-bot.service
```

## Features

- **Automatic restart**: The service will automatically restart if the bot crashes
- **Boot startup**: The bot will start automatically when the system boots
- **Logging**: All output is logged to the system journal
- **Easy management**: Simple scripts for common operations

## Troubleshooting

If the service fails to start:

1. Check the logs: `sudo journalctl -u telegram-obsidian-bot.service -n 50`
2. Verify the virtual environment path in the service file
3. Make sure all dependencies are installed in the virtual environment
4. Check that the `.env` file exists and contains valid configuration
