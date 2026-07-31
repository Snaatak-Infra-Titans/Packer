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
    openjdk-17-jdk \
    maven \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg

echo "========================================="
echo "Installing Golang Migrate CLI"
echo "========================================="

MIGRATE_VERSION="4.18.3"

wget -O /tmp/migrate.tar.gz \
https://github.com/golang-migrate/migrate/releases/download/v${MIGRATE_VERSION}/migrate.linux-amd64.tar.gz

sudo tar -xzf /tmp/migrate.tar.gz -C /usr/local/bin

sudo chmod +x /usr/local/bin/migrate

rm -f /tmp/migrate.tar.gz

echo "========================================="
echo "Verifying Installed Versions"
echo "========================================="

java -version
mvn -version
git --version
python3 --version
pip3 --version
jq --version
migrate -version

echo "========================================="
echo "Cloning Salary Repository"
echo "========================================="

cd /home/ubuntu

rm -rf Salary_API

git clone -b main https://github.com/Snaatak-Infra-Titans/Salary_API.git

sudo chown -R ubuntu:ubuntu /home/ubuntu/Salary_API

cd /home/ubuntu/Salary_API

echo "Repository cloned successfully."

echo "========================================="
echo "Verifying Repository Structure"
echo "========================================="

test -f pom.xml
test -d src
test -d migration
test -f Makefile
test -f migration.json

echo "Repository structure verified."

echo "========================================="
echo "Building Salary API"
echo "========================================="

mvn clean package -DskipTests

echo "========================================="
echo "Verifying Build Artifact"
echo "========================================="

if [[ ! -f target/salary-0.1.0-RELEASE.jar ]]; then
    echo "ERROR: salary-0.1.0-RELEASE.jar not found."
    exit 1
fi

echo "Salary JAR created successfully."

echo "========================================="
echo "Creating Log Directory"
echo "========================================="

mkdir -p /home/ubuntu/logs

echo "========================================="
echo "Setting Ownership"
echo "========================================="

sudo chown -R ubuntu:ubuntu /home/ubuntu/Salary_API
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs

echo "========================================="
echo "Installation Completed Successfully"
echo "========================================="
