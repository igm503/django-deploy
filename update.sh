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

cd "$REPO_ROOT/django"

echo "Collecting static files..."
sudo -u "$LINUX_USER" ../venv/bin/python manage.py collectstatic --noinput

echo "Making database migrations..."
sudo -u "$LINUX_USER" ../venv/bin/python manage.py makemigrations

echo "Applying database migrations..."
sudo -u "$LINUX_USER" ../venv/bin/python manage.py migrate

echo "Loading db.json into database..."
if [ -f "$REPO_ROOT/db.json" ]; then
    sudo -u "$LINUX_USER" ../venv/bin/python manage.py loaddata "$REPO_ROOT/db.json"
else
    echo "db.json not found. Skipping loading."
fi

echo "Restarting gunicorn service..."
sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user restart $DJANGO_PROJECT_NAME.service
