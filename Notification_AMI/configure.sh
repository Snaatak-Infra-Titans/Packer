#!/bin/bash

set -Eeuo pipefail

echo "Configuring Notification AMI..."

#
# Install Notification API systemd service
#

echo "Installing notification-api.service..."

sudo mv /tmp/notification-api.service \
    /etc/systemd/system/notification-api.service

sudo chmod 644 \
    /etc/systemd/system/notification-api.service

#
# Create Notification environment file
#

echo "Creating notification environment file..."

sudo mkdir -p /etc/notification

sudo tee /etc/notification/notification.env >/dev/null <<EOF
SERVER_HOST=0.0.0.0
SERVER_PORT=8085

ELASTIC_HOST=localhost
ELASTIC_PORT=9200
ELASTIC_INDEX=employee_index

SCYLLA_HOST=otms.scylladb.internal
SCYLLA_PORT=9042
SCYLLA_USERNAME=scylladb
SCYLLA_PASSWORD=password
SCYLLA_KEYSPACE=employee_db

SMTP_FROM=jenkinsotms@gmail.com
SMTP_USERNAME=jenkinsotms@gmail.com
SMTP_PASSWORD=zvdftllukvincrgj
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
EOF

sudo chmod 600 /etc/notification/notification.env

#
# Reload systemd
#

sudo systemctl daemon-reload

#
# Enable services
#

echo "Enabling Elasticsearch..."
sudo systemctl enable elasticsearch

echo "Enabling Notification API..."
sudo systemctl enable notification-api

#
# Start Elasticsearch
#

echo "Starting Elasticsearch..."

sudo systemctl restart elasticsearch

echo "Waiting for Elasticsearch..."

ES_READY=false

for i in {1..60}
do
    if curl -fsS http://127.0.0.1:9200 >/dev/null 2>&1
    then
        ES_READY=true
        echo "Elasticsearch is UP."
        break
    fi
    sleep 2
done

if [[ "$ES_READY" != "true" ]]; then
    echo "ERROR: Elasticsearch did not become ready."

    echo "========== Elasticsearch status =========="
    sudo systemctl --no-pager --full status elasticsearch || true

    echo "========== Elasticsearch logs =========="
    sudo journalctl -u elasticsearch --no-pager -n 100 || true

    exit 1
fi

#
# Start Notification API
#

echo "Starting Notification API with Gunicorn..."

sudo systemctl restart notification-api

echo "Waiting for Notification API..."

API_READY=false

for i in {1..60}
do
    if curl -fsS \
        http://127.0.0.1:8085/api/v1/notification/health \
        >/dev/null 2>&1
    then
        API_READY=true
        echo "Notification API is UP."
        break
    fi

    sleep 2
done

if [[ "$API_READY" != "true" ]]; then
    echo "ERROR: Notification API did not become ready."

    echo "========== Notification API status =========="
    sudo systemctl --no-pager --full status notification-api || true

    echo "========== Notification API logs =========="
    sudo journalctl -u notification-api --no-pager -n 150 || true

    echo "========== Application log =========="
    sudo tail -n 150 /home/ubuntu/logs/notification-api.log || true

    exit 1
fi

echo "Configuration completed successfully."
