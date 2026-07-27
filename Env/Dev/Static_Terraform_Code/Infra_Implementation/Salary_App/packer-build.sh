#!/bin/bash

set -Eeuo pipefail

###############################################
# Files
###############################################

PACKER_TEMPLATE="salary.pkr.hcl"
PACKER_VAR_FILE="packer.auto.pkrvars.hcl"
TF_VAR_FILE="terraform.tfvars"

###############################################
# Required Files
###############################################

FILES=(
"$PACKER_TEMPLATE"
"$PACKER_VAR_FILE"
"$TF_VAR_FILE"
"install.sh"
"configure.sh"
"validate.sh"
"salary.service"
)

for file in "${FILES[@]}"
do
    [[ -f "$file" ]] || {
        echo "ERROR : $file not found."
        exit 1
    }
done

###############################################
# Required Commands
###############################################

for cmd in aws packer git python3
do
    command -v "$cmd" >/dev/null || {
        echo "ERROR : $cmd not installed."
        exit 1
    }
done

###############################################
# AWS Authentication Check
###############################################

echo "Checking AWS Credentials..."

aws sts get-caller-identity >/dev/null

###############################################
# Read Variables
###############################################

source <(
python3 <<EOF
import re

for f in ("terraform.tfvars","packer.auto.pkrvars.hcl"):
    with open(f) as fp:
        for line in fp:
            m = re.match(r'(\w+)\s*=\s*"([^"]+)"', line)
            if m:
                print(f'{m.group(1).upper()}="{m.group(2)}"')
EOF
)

###############################################
# Discover Infrastructure
###############################################

echo "Finding VPC..."

echo "Finding Default VPC..."

VPC_ID=$(aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters Name=is-default,Values=true \
    --query "Vpcs[0].VpcId" \
    --output text)

echo "Finding Backend Subnet..."

echo "Finding Default Subnet..."

SUBNET_ID=$(aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query "Subnets[0].SubnetId" \
    --output text)

echo "Finding Default Security Group..."

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --filters \
        Name=group-name,Values=default \
        Name=vpc-id,Values="$VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text)

###############################################
# Validation
###############################################

[[ "$VPC_ID" == "None" ]] && {
    echo "ERROR : VPC not found."
    exit 1
}

[[ "$SUBNET_ID" == "None" ]] && {
    echo "ERROR : Backend subnet not found."
    exit 1
}

[[ "$SECURITY_GROUP_ID" == "None" ]] && {
    echo "ERROR : Salary Security Group not found."
    exit 1
}

###############################################
# Display
###############################################

echo
echo "========== Build Information =========="

printf "%-25s %s\n" "AWS Region" "$AWS_REGION"
printf "%-25s %s\n" "Environment" "$ENVIRONMENT"
printf "%-25s %s\n" "Application" "$APPLICATION"
printf "%-25s %s\n" "VPC" "$VPC_ID"
printf "%-25s %s\n" "Backend Subnet" "$SUBNET_ID"
printf "%-25s %s\n" "Security Group" "$SECURITY_GROUP_ID"
printf "%-25s %s\n" "AMI Name" "$AMI_NAME"

echo "======================================="
echo

###############################################
# Initialize Packer
###############################################

packer init .

###############################################
# Format Template
###############################################

packer fmt .

###############################################
# Validate Template
###############################################

packer validate \
    -var-file="$PACKER_VAR_FILE" \
    -var subnet_id="$SUBNET_ID" \
    -var security_group_id="$SECURITY_GROUP_ID" \
    "$PACKER_TEMPLATE"

###############################################
# Build Golden AMI
###############################################

packer build \
    -var-file="$PACKER_VAR_FILE" \
    -var subnet_id="$SUBNET_ID" \
    -var security_group_id="$SECURITY_GROUP_ID" \
    "$PACKER_TEMPLATE"
