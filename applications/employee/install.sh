#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?Employee artifact path is required}"
app_dir="/opt/otms/employee"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl
rm -rf /var/lib/apt/lists/*

install -d -o ubuntu -g ubuntu -m 0755 "${app_dir}"
install -o ubuntu -g ubuntu -m 0755 "${artifact_path}" "${app_dir}/employee-api"

install -d -m 0755 /etc/otms /etc/employee-api
touch /etc/otms/employee.env
chmod 0600 /etc/otms/employee.env

cat >/etc/systemd/system/employee-api.service <<'UNIT'
[Unit]
Description=OTMS Employee API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/otms/employee
Environment="GIN_MODE=release"
EnvironmentFile=-/etc/otms/employee.env
ExecStart=/opt/otms/employee/employee-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable employee-api.service
test -x "${app_dir}/employee-api"
systemctl is-enabled --quiet employee-api.service
