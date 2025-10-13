#!/bin/bash

# Setup script for Telegram Obsidian Bot Docker service
# This script installs and enables the systemd service for Docker

set -e

SERVICE_NAME="telegram-obsidian-bot-docker"
SERVICE_FILE="telegram-obsidian-bot-docker.service"
PROJECT_DIR="/home/pin/projects/homies/python/telegram-obsidian-git-bot"

echo "Setting up Telegram Obsidian Bot Docker service..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root" 
   exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running"
    exit 1
fi

# Copy service file to systemd directory
echo "Copying service file to /etc/systemd/system/"
sudo cp "$PROJECT_DIR/$SERVICE_FILE" "/etc/systemd/system/"

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service
echo "Enabling $SERVICE_NAME service..."
sudo systemctl enable "$SERVICE_NAME"

echo "Service setup complete!"
echo ""
echo "To start the service: sudo systemctl start $SERVICE_NAME"
echo "To stop the service: sudo systemctl stop $SERVICE_NAME"
echo "To check status: sudo systemctl status $SERVICE_NAME"
echo "To view logs: sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "The service will automatically start on boot."
