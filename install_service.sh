#!/bin/bash

# Script to install and enable the Telegram Obsidian Bot service

echo "Installing Telegram Obsidian Bot service..."

# Copy service file to systemd directory
sudo cp telegram-obsidian-bot.service /etc/systemd/system/

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable telegram-obsidian-bot.service

# Start the service
sudo systemctl start telegram-obsidian-bot.service

echo "Service installed and started!"
echo "Check status with: sudo systemctl status telegram-obsidian-bot.service"
echo "View logs with: sudo journalctl -u telegram-obsidian-bot.service -f"
