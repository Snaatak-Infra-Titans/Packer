#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Validating Notification AMI"
echo "========================================="

#
# Elasticsearch
#

echo "Checking Elasticsearch..."

if ! curl -fsS http://127.0.0.1:9200 >/dev/null 2>&1
then
    echo "ERROR: Elasticsearch health check failed."
    sudo systemctl --no-pager --full status elasticsearch || true
    sudo journalctl -u elasticsearch --no-pager -n 100 || true
    exit 1
fi

echo "Elasticsearch is Healthy."

#
# Notification API systemd service
#

echo "Checking Notification API Service..."

if ! sudo systemctl is-active --quiet notification-api
then
    echo "ERROR: Notification API service is not active."

    echo "========================================="
    echo "Notification API Service Status"
    echo "========================================="

    sudo systemctl --no-pager --full status notification-api || true

    echo "========================================="
    echo "Notification API Journal"
    echo "========================================="

    sudo journalctl -u notification-api --no-pager -n 150 || true

    echo "========================================="
    echo "Notification API Application Log"
    echo "========================================="

    sudo tail -n 150 /home/ubuntu/logs/notification-api.log || true

    exit 1
fi

echo "Notification API Service is Running with Gunicorn."

#
# Notification API health endpoint
# Confirmed current endpoint:
# GET /api/v1/notification/health
#

echo "Checking Notification API Health Endpoint..."

API_STATUS=""

for i in {1..30}
do
    API_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" \
        http://127.0.0.1:8085/api/v1/notification/health || true)

    if [[ "$API_STATUS" == "200" ]]; then
        echo "Notification API Health Check Passed."
        break
    fi

    sleep 2
done

if [[ "$API_STATUS" != "200" ]]; then
    echo "ERROR: Notification API health endpoint returned HTTP ${API_STATUS:-no-response}."

    echo "========================================="
    echo "Notification API Service Status"
    echo "========================================="

    sudo systemctl --no-pager --full status notification-api || true

    echo "========================================="
    echo "Notification API Logs"
    echo "========================================="

    sudo journalctl -u notification-api --no-pager -n 150 || true
    sudo tail -n 150 /home/ubuntu/logs/notification-api.log || true

    exit 1
fi

#
# Python environment
#

[[ -d /home/ubuntu/Notification/venv ]]

echo "Python Virtual Environment Verified."

#
# Repository
#

[[ -f /home/ubuntu/Notification/notification_api.py ]]

echo "Repository Verified."

echo "========================================="
echo "Notification AMI Validation Successful"
echo "========================================="
