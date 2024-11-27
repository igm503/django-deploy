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
    echo "Usage: $0 [nginx|gunicorn]"
    exit 1
fi

case "$1" in
    "nginx")
        sudo journalctl -u nginx.service -b
        ;;
    "gunicorn")
        sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) journalctl --user-unit $DJANGO_PROJECT_NAME.service -b
        ;;
    *)
        echo "Invalid argument. Use 'nginx' or 'gunicorn'"
        exit 1
        ;;
esac
