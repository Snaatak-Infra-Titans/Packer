#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "========================================="
echo "Notification Golden AMI Build"
echo "========================================="

echo "Initializing Packer plugins..."
packer init .

echo "Validating Packer template..."
packer validate .

echo "Starting Packer build..."
packer build .

echo "========================================="
echo "Notification Golden AMI Build Completed"
echo "========================================="
