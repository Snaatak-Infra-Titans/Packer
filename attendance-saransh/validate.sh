#!/usr/bin/env bash

################################################################################
#
# Script Name : validate.sh
#
# Description :
# Performs post-install validation of the Attendance API Golden AMI.
#
################################################################################

set -Eeuo pipefail

##############################################
# Variables
##############################################

readonly APP_USER="ubuntu"

readonly APP_DIR="/home/ubuntu/Attendance_API"

readonly SERVICE_NAME="attendance-api"

readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

readonly MIGRATION_SERVICE_NAME="attendance-migration"

readonly MIGRATION_SERVICE_FILE="/etc/systemd/system/${MIGRATION_SERVICE_NAME}.service"

readonly LOG_DIR="/var/log/attendance-api"

readonly JDBC_DRIVER="${APP_DIR}/lib/postgresql-42.7.2.jar"

##############################################
# Logging
##############################################

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
NC="\033[0m"

log_info() {

    echo -e "${BLUE}[INFO]${NC} $1"

}

log_success() {

    echo -e "${GREEN}[SUCCESS]${NC} $1"

}

log_error() {

    echo -e "${RED}[ERROR]${NC} $1"

}

##############################################
# Error Handler
##############################################

error_handler() {

    log_error "Validation failed at line ${1}"

    exit 1

}

trap 'error_handler ${LINENO}' ERR

##############################################
# Root Check
##############################################

if [[ $EUID -ne 0 ]]
then

    log_error "Run validation as root."

    exit 1

fi

##############################################
# Software Validation
##############################################

log_info "Checking installed software..."

python3.11 --version

java -version

git --version

poetry --version

liquibase --version >/dev/null

psql --version

redis-cli --version

log_success "Software validation passed."

##############################################
# Repository Validation
##############################################

log_info "Checking Attendance API..."

required_files=(

"${APP_DIR}/app.py"

"${APP_DIR}/config.yaml"

"${APP_DIR}/poetry.lock"

"${APP_DIR}/pyproject.toml"

"${APP_DIR}/liquibase.properties"

"${APP_DIR}/migration/db.changelog-master.xml"

"${APP_DIR}/log.conf"

"${JDBC_DRIVER}"

)

for file in "${required_files[@]}"
do

    [[ -e "$file" ]] || {

        log_error "$file missing."

        exit 1

    }

done

log_success "Repository validation passed."

##############################################
# Virtual Environment
##############################################

log_info "Checking Python virtual environment..."

[[ -d "${APP_DIR}/.venv" ]]

[[ -x "${APP_DIR}/.venv/bin/python" ]]

[[ -x "${APP_DIR}/.venv/bin/gunicorn" ]]

sudo -u "${APP_USER}" "${APP_DIR}/.venv/bin/python" -c "

import flask
import psycopg2
import redis
import yaml
import gunicorn

"

log_success "Virtual environment verified."

##############################################
# JDBC Driver
##############################################

log_info "Checking PostgreSQL JDBC driver..."

[[ -s "${JDBC_DRIVER}" ]]

log_success "JDBC driver verified."

##############################################
# Log Directory
##############################################

log_info "Checking log directory..."

[[ -d "${LOG_DIR}" ]]

log_success "Log directory verified."

##############################################
# Systemd Validation
##############################################

log_info "Checking systemd service..."

[[ -f "${SERVICE_FILE}" ]]

[[ -f "${MIGRATION_SERVICE_FILE}" ]]

systemd-analyze verify "${SERVICE_FILE}" "${MIGRATION_SERVICE_FILE}"

systemctl is-enabled "${SERVICE_NAME}" >/dev/null

systemctl is-enabled "${MIGRATION_SERVICE_NAME}" >/dev/null

! grep -Eq "^(Requires|After)=postgresql\.service$" "${MIGRATION_SERVICE_FILE}"

grep -q "Restart=always" "${SERVICE_FILE}"

grep -q "Restart=on-failure" "${MIGRATION_SERVICE_FILE}"

log_success "Systemd validation passed."

##############################################
# Final Summary
##############################################

echo
echo "==========================================="
echo " Attendance API AMI Validation Successful"
echo "==========================================="

echo "Application Directory : ${APP_DIR}"

echo "Systemd Service       : ${SERVICE_NAME}"

echo "Python Version        : $(python3.11 --version 2>&1)"

echo "Poetry Version        : $(poetry --version)"

echo "Liquibase Installed   : Yes"

echo "Virtual Environment   : OK"

echo "Gunicorn              : OK"

echo "JDBC Driver           : OK"

echo "API Service Enabled   : YES"

echo "Migration Retry       : ENABLED"

echo

echo "==========================================="

log_success "Golden AMI validation completed successfully."

exit 0