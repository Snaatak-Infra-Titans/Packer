#!/bin/bash

set -Eeuo pipefail

echo "Updating package repositories..."

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

echo "========== APT CACHE =========="

apt-cache policy zip
apt-cache policy python3
apt-cache policy openjdk-17-jdk
apt-cache policy elasticsearch

echo "========== APT SEARCH =========="

apt-cache search "^zip$"
apt-cache search "^python3$"
apt-cache search "^elasticsearch$"

echo "========== DPKG ARCH =========="

dpkg --print-architecture

echo "========== SOURCES =========="

grep -R "^deb" /etc/apt/ || true

echo "========== OS =========="

cat /etc/os-release

echo "========== APT SOURCES =========="

cat /etc/apt/sources.list || true
ls -l /etc/apt/sources.list.d/ || true

echo "Installing required packages..."

sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    zip \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jdk \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg

echo "Adding Elasticsearch repository..."

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
sudo tee /etc/apt/sources.list.d/elastic-7.x.list >/dev/null

sudo apt-get update

echo "Installing Elasticsearch..."

sudo apt-get install -y elasticsearch

echo "Verifying installed software..."

python3 --version
pip3 --version
java -version
git --version
jq --version

echo "Checking Elasticsearch installation..."

dpkg -l | grep elasticsearch

if [ ! -f /usr/share/elasticsearch/bin/elasticsearch ]; then
    echo "ERROR: Elasticsearch binary not found."
    exit 1
fi

echo "Elasticsearch package installed successfully."

echo "Cloning Notification repository..."

cd /home/ubuntu

rm -rf Notification

git clone -b main https://github.com/Snaatak-Infra-Titans/Notification.git

sudo chown -R ubuntu:ubuntu /home/ubuntu/Notification

cd /home/ubuntu/Notification

echo "Notification repository cloned successfully."

echo "Verifying repository structure..."

test -f notification_api.py
test -f requirements.txt
test -f config.yaml

echo "Repository structure verified."

echo "Creating Python virtual environment..."

python3 -m venv venv

source venv/bin/activate

python -m pip install --upgrade pip

pip install --no-cache-dir -r requirements.txt

pip check

deactivate

echo "Creating log directory..."

mkdir -p /home/ubuntu/logs

echo "Setting ownership..."

sudo chown -R ubuntu:ubuntu /home/ubuntu/Notification
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs

echo "Cleaning apt cache..."

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Notification AMI installation completed successfully."
