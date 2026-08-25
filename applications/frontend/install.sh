#!/usr/bin/env bash
set -euo pipefail

artifact_path="${1:?Frontend artifact path is required}"
web_root="/var/www/otms-frontend"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl nginx
rm -rf /var/lib/apt/lists/*

rm -rf "${web_root}"
install -d -o www-data -g www-data -m 0755 "${web_root}"
tar -xzf "${artifact_path}" -C "${web_root}"
chown -R www-data:www-data "${web_root}"

rm -f /etc/nginx/sites-enabled/default
cat >/etc/nginx/sites-available/otms-frontend <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/otms-frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX

ln -s /etc/nginx/sites-available/otms-frontend /etc/nginx/sites-enabled/otms-frontend
nginx -t
systemctl enable nginx.service
test -s "${web_root}/index.html"
systemctl is-enabled --quiet nginx.service
