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
echo "Verifying Installed Versions"
echo "========================================="

java -version
mvn -version
git --version
python3 --version
pip3 --version
jq --version

echo "========================================="
echo "Cloning Salary Repository"
echo "========================================="

cd /home/ubuntu

rm -rf Salary_API

git clone -b main https://github.com/Snaatak-Infra-Titans/Salary_API.git

cd Salary_API

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
