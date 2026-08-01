#!/bin/bash

set -Eeuo pipefail

echo "Updating package repositories..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update

echo "Installing required packages..."
sudo apt-get install -y \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    git \
    curl \
    wget \
    unzip \
    zip \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jdk

echo "Adding Elasticsearch repository..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
sudo tee /etc/apt/sources.list.d/elastic-7.x.list >/dev/null

echo "Installing Elasticsearch..."
sudo apt-get update
sudo apt-get install -y elasticsearch

echo "Verifying installed software..."
python3 --version
pip3 --version
java -version
git --version
elasticsearch --version

echo "Cloning Notification repository..."
cd /home/ubuntu
rm -rf Notification

git clone -b main https://github.com/Snaatak-Infra-Titans/Notification.git

cd Notification

echo "Creating Python virtual environment..."
python3 -m venv venv

source venv/bin/activate

python -m pip install --upgrade pip
pip install --no-cache-dir -r requirements.txt

pip check

deactivate

echo "Creating log directory..."
mkdir -p /home/ubuntu/logs

echo "Cleaning apt cache..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Notification AMI installation completed successfully."
