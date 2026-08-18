#!/bin/bash

set -Eeuo pipefail

echo "Updating package repositories..."

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

echo "Repairing base Ubuntu packages..."

sudo apt-get -y -f install
sudo DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

echo "Installing required packages..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    apt-transport-https \
    ca-certificates \
    gnupg

echo "Verifying required software..."

python3 --version
pip3 --version
git --version

echo "Adding Elasticsearch repository..."

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
sudo gpg --dearmor --yes -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
sudo tee /etc/apt/sources.list.d/elastic-7.x.list >/dev/null

sudo apt-get update

echo "Installing Elasticsearch..."

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y elasticsearch

echo "Checking Elasticsearch installation..."

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

sudo chown -R ubuntu:ubuntu /home/ubuntu/Notification
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs

echo "Cleaning apt cache..."

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Notification AMI installation completed successfully."
