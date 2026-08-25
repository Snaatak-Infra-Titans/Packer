#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?Attendance artifact path is required}"
app_dir="/opt/otms/attendance"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libpq5 \
    python3 \
    python3-pip \
    python3-venv
rm -rf /var/lib/apt/lists/*

install -d -o ubuntu -g ubuntu -m 0755 "${app_dir}"
tar -xzf "${artifact_path}" --strip-components=1 -C "${app_dir}"
python3 -m venv "${app_dir}/.venv"
"${app_dir}/.venv/bin/pip" install --no-cache-dir --upgrade pip
"${app_dir}/.venv/bin/pip" install --no-cache-dir -r "${app_dir}/requirements.txt"
chown -R ubuntu:ubuntu "${app_dir}"

install -d -m 0755 /etc/otms
touch /etc/otms/attendance.env
chmod 0600 /etc/otms/attendance.env

cat >/etc/systemd/system/attendance-api.service <<'UNIT'
[Unit]
Description=OTMS Attendance API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/otms/attendance
Environment="CONFIG_FILE=/opt/otms/attendance/config.yaml"
EnvironmentFile=-/etc/otms/attendance.env
ExecStart=/opt/otms/attendance/.venv/bin/gunicorn app:app --bind 0.0.0.0:8081 --log-config /opt/otms/attendance/log.conf
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable attendance-api.service
test -x "${app_dir}/.venv/bin/gunicorn"
test -f "${app_dir}/app.py"
systemctl is-enabled --quiet attendance-api.service
