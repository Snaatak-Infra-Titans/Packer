#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Configuring Salary AMI"
echo "========================================="

#############################################
# Install Systemd Service
#############################################

echo "Installing salary.service..."

sudo mv /tmp/salary.service \
/etc/systemd/system/salary.service

sudo chmod 644 \
/etc/systemd/system/salary.service

#############################################
# Reload Systemd
#############################################

echo "Reloading Systemd..."

sudo systemctl daemon-reload

#############################################
# Enable Salary Service
#############################################

echo "Enabling Salary Service..."

sudo systemctl enable salary

#############################################
# Wait for Application
#############################################

echo "Waiting for Salary API to become healthy..."

for i in {1..30}
do
    if curl -fs http://127.0.0.1:8082/actuator/health >/dev/null
    then
        echo "Salary API is Healthy."
        break
    fi

    sleep 2
done

#############################################
# Verify Service Status
#############################################

if ! sudo systemctl is-active --quiet salary
then
    echo "========================================="
    echo "Salary Service Failed"
    echo "========================================="

    sudo journalctl -u salary --no-pager -n 100

    exit 1
fi

#############################################
# Configuration Complete
#############################################

echo "========================================="
echo "Salary AMI Configuration Completed"
echo "========================================="
