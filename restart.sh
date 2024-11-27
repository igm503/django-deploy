#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 [nginx|gunicorn|all]"
    exit 1
fi

restart_gunicorn() {
    sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user daemon-reload 
    sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user restart $DJANGO_PROJECT_NAME.service
}

restart_nginx() {
    sudo systemctl daemon-reload
    sudo systemctl restart nginx
}

case "$1" in
    "nginx")
        restart_nginx
        ;;
    "gunicorn")
        restart_gunicorn
        ;;
    "all")
        restart_gunicorn
        restart_nginx
        ;;
    *)
        echo "Invalid argument. Use 'nginx', 'gunicorn', or 'all'"
        exit 1
        ;;
esac
