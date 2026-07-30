#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Validating Notification AMI"
echo "========================================="

#############################################
# Elasticsearch
#############################################

echo "Checking Elasticsearch..."

until curl -s http://127.0.0.1:9200 >/dev/null
do
    sleep 2
done

echo "Elasticsearch is Healthy."

#############################################
# Notification API Service
#############################################

echo "Checking Notification API Service..."

sudo systemctl is-active --quiet notification-api

echo "Notification API Service is Running."

#############################################
# Notification Sync Service
#############################################

echo "Checking Notification Sync Service..."

sudo systemctl is-enabled notification-sync >/dev/null

echo "Notification Sync Service is Running."

#############################################
# Notification API Health
#############################################

echo "Checking Notification API Health Endpoint..."

API_STATUS=""

for i in {1..30}
do
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        http://127.0.0.1:8085/api/v1/notification/health || true)

    if [[ "$API_STATUS" == "200" ]]; then
        echo "Notification API Health Check Passed."
        break
    fi

    sleep 2
done

if [[ "$API_STATUS" != "200" ]]; then

    echo "========================================="
    echo "Notification API Logs"
    echo "========================================="

    sudo journalctl -u notification-api --no-pager -n 100

    echo "========================================="
    echo "Notification API Status"
    echo "========================================="

    sudo systemctl --no-pager --full status notification-api

    exit 1
fi

#############################################
# Validate Python Environment
#############################################

[[ -d /home/ubuntu/Notification/venv ]]

echo "Python Virtual Environment Verified."

#############################################
# Validate Repository
#############################################

[[ -f /home/ubuntu/Notification/notification_api.py ]]

echo "Repository Verified."

#############################################
# Validation Successful
#############################################

echo "========================================="
echo "Notification AMI Validation Successful"
echo "========================================="
