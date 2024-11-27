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

stop_gunicorn() {
    sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user stop $DJANGO_PROJECT_NAME.service
}

stop_nginx() {
    sudo systemctl stop nginx
}

case "$1" in
    "nginx")
        stop_nginx
        ;;
    "gunicorn")
        stop_gunicorn
        ;;
    "all")
        stop_nginx
        stop_gunicorn
        ;;
    *)
        echo "Invalid argument. Use 'nginx', 'gunicorn', or 'all'"
        exit 1
        ;;
esac
