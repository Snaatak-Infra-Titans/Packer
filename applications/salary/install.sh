#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?Salary artifact path is required}"
app_dir="/opt/otms/salary"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl openjdk-17-jre-headless
rm -rf /var/lib/apt/lists/*

install -d -o ubuntu -g ubuntu -m 0755 "${app_dir}"
install -o ubuntu -g ubuntu -m 0644 "${artifact_path}" "${app_dir}/salary.jar"

install -d -m 0755 /etc/otms
touch /etc/otms/salary.env
chmod 0600 /etc/otms/salary.env

cat >/etc/systemd/system/salary-api.service <<'UNIT'
[Unit]
Description=OTMS Salary API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/otms/salary
EnvironmentFile=-/etc/otms/salary.env
ExecStart=/usr/bin/java -jar /opt/otms/salary/salary.jar
Restart=always
RestartSec=10
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable salary-api.service
test -s "${app_dir}/salary.jar"
java -version
systemctl is-enabled --quiet salary-api.service
