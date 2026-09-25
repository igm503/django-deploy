#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--renewal-only" ]; }; then
    echo "Usage: $0 [--renewal-only]"
    echo "Obtain a certificate and enable renewal, or only enable renewal for existing certificates."
    exit 2
fi

if [ "$#" -eq 0 ]; then
    sudo apt install python3 python3-venv libaugeas0
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip
    sudo /opt/certbot/bin/pip install certbot certbot-nginx
    sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot
    sudo certbot --nginx
fi

sudo test -x /usr/bin/certbot
sudo install -m 0644 "$SCRIPT_DIR/templates/certbot-renew.service" "$SCRIPT_DIR/templates/certbot-renew.timer" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer
echo "Automatic renewal enabled for all managed certificates (twice daily)."
