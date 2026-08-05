#!/bin/bash

set -e

APP_DIR="/home/ubuntu/Attendance_API"

echo "===================================="
echo "Validating Attendance API AMI..."
echo "===================================="

echo "Checking Python..."
python3.11 --version

echo "Checking Poetry..."
poetry --version

echo "Checking Java..."
java -version

echo "Checking Liquibase..."
liquibase --version

echo "Checking PostgreSQL Client..."
psql --version

echo "Checking Redis Client..."
redis-cli --version

echo "Checking Attendance API directory..."

test -d "${APP_DIR}"

echo "Checking required files..."

test -f "${APP_DIR}/app.py"
test -f "${APP_DIR}/config.yaml"
test -f "${APP_DIR}/liquibase.properties"
test -f "${APP_DIR}/migration/db.changelog-master.xml"
test -f "${APP_DIR}/log.conf"
test -f "${APP_DIR}/lib/postgresql-42.7.2.jar"

echo "Checking virtual environment..."

test -d "${APP_DIR}/.venv"

echo "Checking Gunicorn..."

test -x "${APP_DIR}/.venv/bin/gunicorn"

echo "Checking systemd service..."

test -f /etc/systemd/system/attendance-api.service

echo "Checking service enabled..."

systemctl is-enabled attendance-api.service

echo "===================================="
echo "AMI Validation Successful"
echo "===================================="