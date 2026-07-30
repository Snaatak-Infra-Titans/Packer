#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Updating Ubuntu Packages"
echo "========================================="

sudo apt-get update -y

echo "========================================="
echo "Installing Required Packages"
echo "========================================="

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
    apt-transport-https \
    gnupg

echo "========================================="
echo "Installing Elasticsearch 7.17.x"
echo "========================================="

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
sudo tee /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update -y

sudo apt-get install -y elasticsearch

echo "========================================="
echo "Verifying Installed Versions"
echo "========================================="

python3 --version
pip3 --version
java -version
git --version

echo "========================================="
echo "Cloning Notification Repository"
echo "========================================="

cd /home/ubuntu

rm -rf Notification

git clone -b main https://github.com/Snaatak-Infra-Titans/Notification.git

cd Notification

echo "========================================="
echo "Creating Python Virtual Environment"
echo "========================================="

python3 -m venv venv

source venv/bin/activate

pip install --upgrade pip

pip install --no-cache-dir -r requirements.txt

pip check

deactivate

echo "========================================="
echo "Creating Log Directory"
echo "========================================="

mkdir -p /home/ubuntu/logs

echo "========================================="
echo "Installation Completed Successfully"
echo "========================================="
