#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Validating Salary AMI"
echo "========================================="

#############################################
# Verify Repository
#############################################

echo "Checking Repository..."

test -d /home/ubuntu/Salary_API

echo "Repository Verified."

#############################################
# Verify Build Artifact
#############################################

echo "Checking Salary JAR..."

test -f /home/ubuntu/Salary_API/target/salary-0.1.0-RELEASE.jar

echo "Salary JAR Verified."

#############################################
# Verify Service File
#############################################

echo "Checking salary.service..."

test -f /etc/systemd/system/salary.service

echo "salary.service Verified."

#############################################
# Verify Service Enabled
#############################################

echo "Checking Salary Service Enablement..."

sudo systemctl is-enabled salary >/dev/null

echo "Salary Service Enabled."

#############################################
# Verify Java
#############################################

echo "Checking Java Installation..."

java -version

#############################################
# Verify Maven
#############################################

echo "Checking Maven Installation..."

mvn -version

#############################################
# Verify Git
#############################################

echo "Checking Git Installation..."

git --version

#############################################
# Verify Python
#############################################

echo "Checking Python Installation..."

python3 --version

#############################################
# Verify Log Directory
#############################################

echo "Checking Log Directory..."

test -d /home/ubuntu/logs

echo "Log Directory Verified."

#############################################
# Validation Successful
#############################################

echo "========================================="
echo "Salary AMI Validation Successful"
echo "========================================="
