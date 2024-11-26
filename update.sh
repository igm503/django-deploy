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

restart_gunicorn() {
    sudo -u "$LINUX_USER" XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user restart $DJANGO_PROJECT_NAME.service
}

cd "$REPO_ROOT/django"
source ../venv/bin/activate

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Making database migrations..."
python manage.py makemigrations

echo "Applying database migrations..."
python manage.py migrate

echo "Loading db.json into database..."
if [ -f "$REPO_ROOT/db.json" ]; then
    python manage.py loaddata "$REPO_ROOT/db.json"
else
    echo "db.json not found. Skipping loading."
fi

echo "Restarting gunicorn service..."
restart_gunicorn
