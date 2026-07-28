#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Configuring Salary AMI"
echo "========================================="

sudo mv /tmp/salary.service /etc/systemd/system/salary.service

sudo chmod 644 /etc/systemd/system/salary.service

sudo systemctl daemon-reload

sudo systemctl enable salary

echo "Salary service installed and enabled."

echo "========================================="
echo "Salary AMI Configuration Completed"
echo "========================================="
