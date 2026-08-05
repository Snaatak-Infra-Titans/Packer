#!/usr/bin/env bash

################################################################################
#
# Script Name : install.sh
#
# Description :
#   Installs and configures all prerequisites required to build the
#   Attendance API Golden AMI.
#
################################################################################

set -Eeuo pipefail

###############################################################################
# Variables
###############################################################################

readonly APP_USER="ubuntu"
readonly APP_GROUP="ubuntu"

readonly APP_HOME="/home/${APP_USER}"

readonly APP_DIR="${APP_HOME}/Attendance_API"

readonly REPO_URL="https://github.com/Snaatak-Infra-Titans/Attendance_API.git"

readonly REPO_BRANCH="main"

readonly LIQUIBASE_VERSION="4.27.0"

readonly JDBC_VERSION="42.7.2"

###############################################################################
# Logging
###############################################################################

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

###############################################################################
# Error Handling
###############################################################################

cleanup() {

    rm -f /tmp/liquibase.tar.gz 2>/dev/null || true

}

error_handler() {

    log_error "Installation failed at line ${1}"

    cleanup

    exit 1

}

trap 'error_handler ${LINENO}' ERR

###############################################################################
# Root Validation
###############################################################################

if [[ $EUID -ne 0 ]]
then

    log_error "Run this script as root."

    exit 1

fi

###############################################################################
# Configure APT
###############################################################################

log_info "Configuring APT..."

cat >/etc/apt/apt.conf.d/99packer <<EOF
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::ForceIPv4 "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

export DEBIAN_FRONTEND=noninteractive

###############################################################################
# Install Python Repository
###############################################################################

if ! command -v python3.11 >/dev/null 2>&1
then

    log_info "Adding Deadsnakes Repository..."

    add-apt-repository -y ppa:deadsnakes/ppa

fi

###############################################################################
# Update Packages
###############################################################################

log_info "Updating package cache..."

apt-get update -y

###############################################################################
# Install Required Packages
###############################################################################

log_info "Installing operating system packages..."

apt-get install -y \
    software-properties-common \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    zip \
    jq \
    ca-certificates \
    gnupg \
    libpq-dev \
    postgresql-client \
    redis-tools \
    openjdk-17-jre-headless \
    python3.11 \
    python3.11-dev \
    python3.11-venv

###############################################################################
# Verify Software
###############################################################################

log_info "Verifying installed software..."

python3 --version

python3.11 --version

java -version

git --version

psql --version

redis-cli --version

which python3

which python3.11

log_success "Base software installed successfully."

###############################################################################
# Install Poetry
###############################################################################

log_info "Installing Poetry..."

if [[ ! -f "${APP_HOME}/.local/bin/poetry" ]]
then

    sudo -u "${APP_USER}" bash <<'EOF'

set -Eeuo pipefail

curl -sSL \
https://install.python-poetry.org | python3.11 -

EOF

fi

###############################################################################
# Configure PATH
###############################################################################

if ! grep -q '.local/bin' "${APP_HOME}/.bashrc"
then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${APP_HOME}/.bashrc"
fi

export PATH="${APP_HOME}/.local/bin:$PATH"

ln -sf \
    "${APP_HOME}/.local/bin/poetry" \
    /usr/local/bin/poetry

###############################################################################
# Verify Poetry
###############################################################################

log_info "Verifying Poetry..."

poetry --version

which poetry

log_success "Poetry installed successfully."

###############################################################################
# Install Liquibase
###############################################################################

log_info "Installing Liquibase ${LIQUIBASE_VERSION}..."

rm -rf /opt/liquibase

mkdir -p /opt/liquibase

curl \
    -L \
    --retry 5 \
    --retry-delay 5 \
    --retry-all-errors \
    "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
    -o /tmp/liquibase.tar.gz

tar -xzf \
    /tmp/liquibase.tar.gz \
    -C /opt/liquibase

chmod +x /opt/liquibase/liquibase

ln -sf \
    /opt/liquibase/liquibase \
    /usr/local/bin/liquibase

###############################################################################
# Verify Liquibase
###############################################################################

liquibase --version

log_success "Liquibase installed successfully."

###############################################################################
# Clone Attendance API
###############################################################################

log_info "Downloading Attendance API..."

rm -rf "${APP_DIR}"

git clone \
    --depth 1 \
    --single-branch \
    --branch "${REPO_BRANCH}" \
    "${REPO_URL}" \
    "${APP_DIR}"

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

###############################################################################
# Repository Validation
###############################################################################

log_info "Validating Attendance API repository..."

cd "${APP_DIR}"

required_files=(

app.py
pyproject.toml
poetry.lock
config.yaml
liquibase.properties
log.conf
migration/db.changelog-master.xml

)

for file in "${required_files[@]}"
do

    if [[ ! -f "$file" ]]
    then

        log_error "$file not found."

        exit 1

    fi

done

log_success "Repository validation successful."

##############################################
# Configure Poetry
##############################################

log_info "Configuring Poetry..."

sudo -u "${APP_USER}" bash <<EOF

set -Eeuo pipefail

export PATH="\$HOME/.local/bin:\$PATH"

poetry config virtualenvs.create true

poetry config virtualenvs.in-project true

EOF

log_success "Poetry configured."
##############################################
# Install Python Dependencies
##############################################

log_info "Installing Attendance API dependencies..."

sudo -u "${APP_USER}" bash <<EOF

set -Eeuo pipefail

cd "${APP_DIR}"

export PATH="\$HOME/.local/bin:\$PATH"

# Remove old virtual environment
rm -rf .venv

# Create virtual environment using Python 3.11
poetry env use python3.11

# Install project dependencies
poetry install --no-root

EOF

log_success "Python dependencies installed."

###############################################################################
# Verify Virtual Environment
###############################################################################

log_info "Verifying virtual environment..."

if [[ ! -d "${APP_DIR}/.venv" ]]
then
    log_error ".venv directory not found."
    exit 1
fi

if [[ ! -x "${APP_DIR}/.venv/bin/python" ]]
then
    log_error "Python executable not found."
    exit 1
fi

if [[ ! -x "${APP_DIR}/.venv/bin/gunicorn" ]]
then
    log_error "Gunicorn executable not found."
    exit 1
fi

log_success "Virtual environment verified."

###############################################################################
# Verify Python Modules
###############################################################################

log_info "Checking required Python modules..."

sudo -u "${APP_USER}" "${APP_DIR}/.venv/bin/python" <<EOF

import flask
import psycopg2
import redis
import yaml
import gunicorn
import flasgger

print("Python dependency verification successful.")

EOF

log_success "Python dependencies verified."

###############################################################################
# Download PostgreSQL JDBC Driver
###############################################################################

log_info "Downloading PostgreSQL JDBC Driver..."

mkdir -p "${APP_DIR}/lib"

curl \
    -L \
    --retry 5 \
    --retry-delay 5 \
    --retry-all-errors \
    "https://repo1.maven.org/maven2/org/postgresql/postgresql/${JDBC_VERSION}/postgresql-${JDBC_VERSION}.jar" \
    -o "${APP_DIR}/lib/postgresql-${JDBC_VERSION}.jar"

if [[ ! -s "${APP_DIR}/lib/postgresql-${JDBC_VERSION}.jar" ]]
then

    log_error "PostgreSQL JDBC driver download failed."

    exit 1

fi

chmod 644 "${APP_DIR}/lib/postgresql-${JDBC_VERSION}.jar"

log_success "PostgreSQL JDBC Driver installed."

###############################################################################
# Application Log Directory
###############################################################################

log_info "Creating log directory..."

mkdir -p /var/log/attendance-api

chown "${APP_USER}:${APP_GROUP}" /var/log/attendance-api

chmod 755 /var/log/attendance-api

log_success "Log directory created."

###############################################################################
# Final Ownership
###############################################################################

log_info "Setting ownership..."

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

###############################################################################
# Final Validation
###############################################################################

log_info "Performing final validation..."

validation_files=(

"${APP_DIR}/app.py"

"${APP_DIR}/config.yaml"

"${APP_DIR}/pyproject.toml"

"${APP_DIR}/poetry.lock"

"${APP_DIR}/liquibase.properties"

"${APP_DIR}/migration/db.changelog-master.xml"

"${APP_DIR}/log.conf"

"${APP_DIR}/.venv/bin/python"

"${APP_DIR}/.venv/bin/gunicorn"

"${APP_DIR}/lib/postgresql-${JDBC_VERSION}.jar"

)

for file in "${validation_files[@]}"
do

    if [[ ! -e "$file" ]]
    then

        log_error "$file does not exist."

        exit 1

    fi

done

log_success "Application validation successful."

###############################################################################
# Installed Software Summary
###############################################################################

echo
echo "======================================================"
echo " Attendance API Golden AMI"
echo " Installation Summary"
echo "======================================================"

echo "Python       : $(python3.11 --version 2>&1)"

echo "Java         : $(java -version 2>&1 | head -1)"

echo "Git          : $(git --version)"

echo "Poetry       : $(poetry --version)"

echo "Liquibase    : $(liquibase --version | head -1)"

echo "PostgreSQL   : $(psql --version)"

echo "Redis CLI    : $(redis-cli --version)"

echo

echo "Repository   : ${APP_DIR}"

echo "Virtual Env  : ${APP_DIR}/.venv"

echo

echo "======================================================"

###############################################################################
# Cleanup
###############################################################################

log_info "Cleaning temporary files..."

rm -f /tmp/liquibase.tar.gz

find /tmp \
    -type f \
    -delete 2>/dev/null || true

###############################################################################
# Reduce AMI Size
###############################################################################

log_info "Cleaning package cache..."

apt-get autoremove -y

apt-get autoclean

apt-get clean

###############################################################################
# Remove Unnecessary Logs
###############################################################################

find /var/log \
    -type f \
    -name "*.gz" \
    -delete 2>/dev/null || true

find /var/log \
    -type f \
    -name "*.1" \
    -delete 2>/dev/null || true

truncate -s 0 /var/log/wtmp || true

truncate -s 0 /var/log/btmp || true

truncate -s 0 /var/log/lastlog || true

###############################################################################
# Flush Filesystem
###############################################################################

sync

###############################################################################
# Complete
###############################################################################

log_success "======================================================"

log_success "Attendance API installation completed successfully."

log_success "Golden AMI is ready."

log_success "======================================================"

exit 0

