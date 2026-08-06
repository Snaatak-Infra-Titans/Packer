#!/usr/bin/env bash

set -Eeuo pipefail

readonly APP_USER="ubuntu"
readonly APP_GROUP="ubuntu"

readonly APP_HOME="/home/${APP_USER}"
readonly APP_DIR="${APP_HOME}/Attendance_API"

readonly LOG_DIR="/var/log/attendance-api"

readonly SERVICE_NAME="attendance-api"
readonly MIGRATION_SERVICE_NAME="attendance-migration"

readonly SERVICE_FILE="/tmp/attendance-api.service"
readonly MIGRATION_SERVICE_FILE="/tmp/attendance-migration.service"

readonly SYSTEMD_DIR="/etc/systemd/system"

readonly SYSTEMD_SERVICE="${SYSTEMD_DIR}/${SERVICE_NAME}.service"
readonly SYSTEMD_MIGRATION_SERVICE="${SYSTEMD_DIR}/${MIGRATION_SERVICE_NAME}.service"

##############################################
# Logging
##############################################

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

log_info() {

    echo -e "${BLUE}[INFO]${NC} $1"

}

log_success() {

    echo -e "${GREEN}[SUCCESS]${NC} $1"

}

log_warn() {

    echo -e "${YELLOW}[WARNING]${NC} $1"

}

log_error() {

    echo -e "${RED}[ERROR]${NC} $1"

}

##############################################
# Error Handling
##############################################

error_handler() {

    log_error "Configuration failed at line ${1}"

    exit 1

}

trap 'error_handler ${LINENO}' ERR

##############################################
# Root Validation
##############################################

if [[ $EUID -ne 0 ]]
then

    log_error "Run as root."

    exit 1

fi

##############################################
# Verify Installation
##############################################

log_info "Checking Attendance API installation..."

required_files=(

"${APP_DIR}/app.py"
"${APP_DIR}/config.yaml"
"${APP_DIR}/liquibase.properties"
"${APP_DIR}/log.conf"
"${APP_DIR}/migration/db.changelog-master.xml"
"${APP_DIR}/.venv/bin/python"
"${APP_DIR}/.venv/bin/gunicorn"
"${APP_DIR}/lib/postgresql-42.7.2.jar"

)

for file in "${required_files[@]}"
do

    if [[ ! -e "$file" ]]
    then

        log_error "$file not found."

        exit 1

    fi

done

log_success "Installation verified."

##############################################
# Ownership
##############################################

log_info "Setting ownership..."

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

##############################################
# Permissions
##############################################

log_info "Applying permissions..."

find "${APP_DIR}" -type d -exec chmod 755 {} \;

find "${APP_DIR}" -type f \
     ! -name "*.yaml" \
     ! -name "*.properties" \
     -exec chmod 644 {} \;

chmod 755 "${APP_DIR}/.venv/bin/"*

chmod 600 "${APP_DIR}/config.yaml"

chmod 600 "${APP_DIR}/liquibase.properties"

chmod 644 "${APP_DIR}/lib/postgresql-42.7.2.jar"

log_success "Permissions configured."

##############################################
# Log Directory
##############################################

mkdir -p "${LOG_DIR}"

chown "${APP_USER}:${APP_GROUP}" "${LOG_DIR}"

chmod 755 "${LOG_DIR}"

log_success "Log directory ready."

##############################################
# Validate Service File
##############################################

log_info "Validating systemd service file..."

if [[ ! -f "${SERVICE_FILE}" ]]
then
    log_error "Service file not found: ${SERVICE_FILE}"
    exit 1
fi

grep -q "ExecStart=" "${SERVICE_FILE}" || {
    log_error "Invalid systemd service file."
    exit 1
}

log_success "Service file validation completed."

##############################################
# Install Systemd Services
##############################################

log_info "Installing systemd service files..."

# Attendance Migration Service
install \
    -o root \
    -g root \
    -m 644 \
    "${MIGRATION_SERVICE_FILE}" \
    "${SYSTEMD_MIGRATION_SERVICE}"

# Attendance API Service
install \
    -o root \
    -g root \
    -m 644 \
    "${SERVICE_FILE}" \
    "${SYSTEMD_SERVICE}"

log_success "Systemd service files installed."

##############################################
# Reload systemd
##############################################

log_info "Reloading systemd..."

systemctl daemon-reload

log_success "Systemd daemon reloaded."

##############################################
# Enable Services
##############################################

log_info "Enabling systemd services..."

systemctl enable "${MIGRATION_SERVICE_NAME}"

systemctl enable "${SERVICE_NAME}"

log_success "Systemd services enabled."

##############################################
# Ensure Service is Stopped
##############################################

#
# IMPORTANT
#
# The application must NOT start while
# creating the Golden AMI.
#
# Liquibase migrations should execute only
# after an EC2 instance boots.
#

log_info "Stopping service if running..."

systemctl stop "${SERVICE_NAME}" 2>/dev/null || true

systemctl stop "${MIGRATION_SERVICE_NAME}" 2>/dev/null || true

systemctl reset-failed "${SERVICE_NAME}" 2>/dev/null || true

systemctl reset-failed "${MIGRATION_SERVICE_NAME}" 2>/dev/null || true

log_success "Service stopped."

##############################################
# Verify Installation
##############################################

log_info "Performing configuration validation..."

required_paths=(

"${SYSTEMD_SERVICE}"

"${SYSTEMD_MIGRATION_SERVICE}"

"${APP_DIR}/config.yaml"

"${APP_DIR}/.venv/bin/gunicorn"

"${APP_DIR}/app.py"

"${LOG_DIR}"

)

for path in "${required_paths[@]}"
do

    if [[ ! -e "$path" ]]
    then
        log_error "$path missing."
        exit 1
    fi

done

log_success "Configuration validation successful."

##############################################
# Print Summary
##############################################

echo
echo "=============================================="
echo " Attendance API Configuration Summary"
echo "=============================================="

echo "Application Directory : ${APP_DIR}"

echo "Service Name          : ${SERVICE_NAME}"

echo "Systemd Unit          : ${SYSTEMD_SERVICE}"

echo "Log Directory         : ${LOG_DIR}"

echo "Application User      : ${APP_USER}"

echo

systemctl is-enabled "${SERVICE_NAME}"
systemctl is-enabled "${MIGRATION_SERVICE_NAME}"

echo

echo "=============================================="

log_success "Attendance API configured successfully."

exit 0