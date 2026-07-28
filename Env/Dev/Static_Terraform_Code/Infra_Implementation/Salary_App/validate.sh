#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo "Validating Salary AMI"
echo "========================================="
#############################################
# Verifying artifact available
#############################################
echo "Checking jar..."
test -f /home/ubuntu/Salary_API/target/salary-0.1.0-RELEASE.jar

#############################################
# Check Salary Service
#############################################

echo "Checking Salary Service..."

sudo systemctl is-active --quiet salary

echo "Salary Service is Running."

#############################################
# Check Service Enabled
#############################################

echo "Checking Salary Service Enablement..."

sudo systemctl is-enabled salary >/dev/null

echo "Salary Service is Enabled."

#############################################
# Validate Health Endpoint
#############################################

echo "Checking Salary Health Endpoint..."

API_STATUS=""

for i in {1..30}
do
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        http://127.0.0.1:8082/actuator/health || true)

    if [[ "$API_STATUS" == "200" ]]; then
        echo "Salary API Health Check Passed."
        break
    fi

    sleep 2
done

if [[ "$API_STATUS" != "200" ]]; then

    echo "========================================="
    echo "Salary Service Logs"
    echo "========================================="

    sudo journalctl -u salary --no-pager -n 100

    echo "========================================="
    echo "Salary Service Status"
    echo "========================================="

    sudo systemctl --no-pager --full status salary

    exit 1
fi

#############################################
# Verify Repository
#############################################

echo "Checking Repository..."

[[ -d /home/ubuntu/Salary_API ]]

echo "Repository Verified."

#############################################
# Verify JAR
#############################################

echo "Checking Build Artifact..."

[[ -f /home/ubuntu/Salary_API/target/salary-0.1.0-RELEASE.jar ]]

echo "Salary JAR Verified."

#############################################
# Validate Java
#############################################

echo "Checking Java Installation..."

java -version

#############################################
# Validate Maven
#############################################

echo "Checking Maven Installation..."

mvn -version

#############################################
# Validate Git
#############################################

echo "Checking Git Installation..."

git --version

#############################################
# Validate Log Directory
#############################################

echo "Checking Log Directory..."

[[ -d /home/ubuntu/logs ]]

echo "Log Directory Verified."

#############################################
# Validation Successful
#############################################

echo "========================================="
echo "Salary AMI Validation Successful"
echo "========================================="
