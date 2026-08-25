#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?Notification artifact path is required}"
app_dir="/opt/otms/notification"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
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
touch /etc/otms/notification.env
chmod 0600 /etc/otms/notification.env

cat >/etc/systemd/system/notification-api.service <<'UNIT'
[Unit]
Description=OTMS Notification API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/otms/notification
Environment="SERVER_HOST=0.0.0.0"
Environment="SERVER_PORT=8085"
Environment="CONFIG_FILE=/opt/otms/notification/config.yaml"
EnvironmentFile=-/etc/otms/notification.env
ExecStart=/opt/otms/notification/.venv/bin/gunicorn --bind 0.0.0.0:8085 --workers 2 --threads 4 --timeout 60 notification_api:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable notification-api.service
test -x "${app_dir}/.venv/bin/gunicorn"
test -f "${app_dir}/notification_api.py"
systemctl is-enabled --quiet notification-api.service
