#!/bin/bash

set -Eeuo pipefail

echo "Configuring Notification AMI..."

#
# Install Systemd Services
#

echo "Installing notification-api.service..."

sudo mv /tmp/notification-api.service \
    /etc/systemd/system/notification-api.service

sudo chmod 644 \
    /etc/systemd/system/notification-api.service

echo "Installing notification-sync.service..."

sudo mv /tmp/notification-sync.service \
    /etc/systemd/system/notification-sync.service

sudo chmod 644 \
    /etc/systemd/system/notification-sync.service

#
# Create Environment File
#

echo "Creating notification environment file..."

sudo mkdir -p /etc/notification

sudo tee /etc/notification/notification.env >/dev/null <<EOF
SMTP_FROM=jenkinsotms@gmail.com
SMTP_USERNAME=jenkinsotms@gmail.com
SMTP_PASSWORD=jenkinsotms@gmail.com
EOF

sudo chmod 600 /etc/notification/notification.env

#
# Reload Systemd
#

sudo systemctl daemon-reload

#
# Enable Services
#

echo "Enabling Elasticsearch..."
sudo systemctl enable elasticsearch

echo "Enabling Notification API..."
sudo systemctl enable notification-api

echo "Enabling Notification Sync..."
sudo systemctl enable notification-sync

#
# Start Elasticsearch
#

echo "Starting Elasticsearch..."

sudo systemctl start elasticsearch

echo "Waiting for Elasticsearch..."

until curl -s http://127.0.0.1:9200 >/dev/null
do
    sleep 2
done

#
# Start Notification API
#

echo "Starting Notification API..."

sudo systemctl start notification-api

echo "Waiting for Notification API..."

for i in {1..30}
do
    if curl -fs http://127.0.0.1:8085/api/v1/notification/health >/dev/null
    then
        echo "Notification API is UP."
        break
    fi
    sleep 2
done

#
# Start Notification Sync
#

echo "Starting Notification Sync..."

sudo systemctl start notification-sync

echo "Configuration completed successfully."
