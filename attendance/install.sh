#!/bin/bash

set -Eeuo pipefail

APP_DIR="/home/ubuntu/Attendance_API"
LIQUIBASE_VERSION="4.27.0"
POSTGRES_JDBC_VERSION="42.7.2"

echo "Updating package repositories..."

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

echo "Installing base dependencies..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common \
    git \
    curl \
    wget \
    unzip \
    zip \
    jq \
    ca-certificates \
    gnupg \
    build-essential \
    libpq-dev \
    postgresql-client \
    redis-tools \
    openjdk-17-jre-headless

echo "Adding Python 3.11 repository..."

sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update

echo "Installing Python 3.11..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv

echo "Verifying installed software..."

python3.11 --version
java -version
git --version
psql --version
redis-cli --version

echo "Installing Poetry..."

curl -sSL https://install.python-poetry.org | \
    POETRY_HOME=/opt/poetry python3.11 -

sudo ln -sf /opt/poetry/bin/poetry /usr/local/bin/poetry

poetry --version

echo "Installing Liquibase ${LIQUIBASE_VERSION}..."

sudo rm -rf /opt/liquibase
sudo mkdir -p /opt/liquibase

wget -q \
    "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
    -O /tmp/liquibase.tar.gz

sudo tar -xzf /tmp/liquibase.tar.gz -C /opt/liquibase

sudo ln -sf /opt/liquibase/liquibase /usr/local/bin/liquibase

liquibase --version

echo "Cloning Attendance API repository..."

sudo rm -rf "${APP_DIR}"

git clone \
    --branch main \
    --single-branch \
    https://github.com/Snaatak-Infra-Titans/Attendance_API.git \
    "${APP_DIR}"

sudo chown -R ubuntu:ubuntu "${APP_DIR}"

cd "${APP_DIR}"

echo "Verifying Attendance API repository structure..."

test -f app.py
test -f pyproject.toml
test -f poetry.lock
test -f config.yaml
test -f liquibase.properties
test -f migration/db.changelog-master.xml
test -f log.conf

echo "Repository structure verified."

echo "Installing Attendance API Python dependencies..."

sudo -u ubuntu poetry config virtualenvs.create true
sudo -u ubuntu poetry config virtualenvs.in-project true

# Flask and psycopg2 are currently in the repository's dev group.
# Therefore, the dev dependencies are required for runtime.
sudo -u ubuntu poetry install \
    --no-root \
    --with dev \
    --no-interaction \
    --no-ansi

echo "Verifying Python dependencies..."

sudo -u ubuntu "${APP_DIR}/.venv/bin/python" -c \
    "import flask, psycopg2, redis, yaml, gunicorn; print('Python dependencies verified')"

echo "Installing PostgreSQL JDBC driver..."

sudo mkdir -p "${APP_DIR}/lib"

sudo wget -q \
    "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION}/postgresql-${POSTGRES_JDBC_VERSION}.jar" \
    -O "${APP_DIR}/lib/postgresql-${POSTGRES_JDBC_VERSION}.jar"

test -s "${APP_DIR}/lib/postgresql-${POSTGRES_JDBC_VERSION}.jar"

sudo chown -R ubuntu:ubuntu "${APP_DIR}"
sudo chmod 755 "${APP_DIR}"
sudo chmod 644 "${APP_DIR}/lib/postgresql-${POSTGRES_JDBC_VERSION}.jar"

echo "Creating Attendance API log directory..."

sudo mkdir -p /var/log/attendance-api
sudo chown ubuntu:ubuntu /var/log/attendance-api
sudo chmod 755 /var/log/attendance-api

echo "Cleaning temporary files and APT cache..."

sudo rm -f /tmp/liquibase.tar.gz
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Attendance API AMI installation completed successfully."