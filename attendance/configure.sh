#!/bin/bash

set -Eeuo pipefail

APP_DIR="/home/ubuntu/Attendance_API"
SERVICE_NAME="attendance-api"
SERVICE_SOURCE="/tmp/attendance-api.service"
SERVICE_DESTINATION="/etc/systemd/system/${SERVICE_NAME}.service"

echo "=========================================="
echo "Configuring Attendance API..."
echo "=========================================="

echo "Verifying Attendance API files..."

required_files=(
    "${APP_DIR}/app.py"
    "${APP_DIR}/config.yaml"
    "${APP_DIR}/liquibase.properties"
    "${APP_DIR}/migration/db.changelog-master.xml"
    "${APP_DIR}/lib/postgresql-42.7.2.jar"
    "${APP_DIR}/log.conf"
    "${APP_DIR}/.venv/bin/gunicorn"
)

for file in "${required_files[@]}"; do
    if [[ ! -e "$file" ]]; then
        echo "ERROR: Required file not found -> $file"
        exit 1
    fi
done

echo "Repository verification successful."

echo "Setting ownership..."

sudo chown -R ubuntu:ubuntu "${APP_DIR}"

echo "Setting permissions..."

sudo find "${APP_DIR}" -type d -exec chmod 755 {} \;
sudo find "${APP_DIR}" -type f -exec chmod 644 {} \;

sudo chmod 755 "${APP_DIR}/.venv/bin/"*
sudo chmod 755 "${APP_DIR}/lib"

sudo chmod 644 "${APP_DIR}/lib/postgresql-42.7.2.jar"

# Files containing credentials
sudo chmod 600 "${APP_DIR}/config.yaml"
sudo chmod 600 "${APP_DIR}/liquibase.properties"

echo "Installing systemd service..."

if [[ ! -f "${SERVICE_SOURCE}" ]]; then
    echo "ERROR: ${SERVICE_SOURCE} not found."
    exit 1
fi

sudo install \
    -o root \
    -g root \
    -m 644 \
    "${SERVICE_SOURCE}" \
    "${SERVICE_DESTINATION}"

echo "Creating log directory..."

sudo mkdir -p /var/log/attendance-api
sudo chown ubuntu:ubuntu /var/log/attendance-api
sudo chmod 755 /var/log/attendance-api

echo "Reloading systemd..."

sudo systemctl daemon-reload

echo "Enabling Attendance API service..."

sudo systemctl enable "${SERVICE_NAME}.service"

#
# IMPORTANT:
# Do NOT start the service during the AMI build.
# Liquibase will execute automatically when the EC2
# instance boots for the first time.
#

sudo systemctl stop "${SERVICE_NAME}.service" 2>/dev/null || true

echo "=========================================="
echo "Attendance API configuration completed."
echo "=========================================="