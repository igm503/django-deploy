#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Load environment variables
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    echo "✓ Loaded environment variables from $ENV_FILE"
else
    echo "✗ Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo "Starting uninstallation for $DJANGO_PROJECT_NAME"

# Function to handle step confirmation
confirm_step() {
    local step_name="$1"
    echo -e "\nPreparing to $step_name"
    read -p "Continue with this step? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping $step_name"
        return 1
    fi
    return 0
}

# Function to check and report status
report_status() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
    else
        echo "✗ $1"
    fi
}

# Initial confirmation
read -p "This will remove the Django application, database, and associated services. Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 1
fi

# 1. Check and remove Nginx configuration
if confirm_step "remove Nginx configuration"; then
    echo "Checking Nginx configuration..."
    nginx_changes_made=false
    if [ -f "/etc/nginx/sites-enabled/$DJANGO_PROJECT_NAME" ]; then
        sudo rm -f "/etc/nginx/sites-enabled/$DJANGO_PROJECT_NAME"
        echo "✓ Removed Nginx enabled site configuration"
        nginx_changes_made=true
    else
        echo "ℹ Nginx enabled site configuration not found"
    fi

    if [ -f "/etc/nginx/sites-available/$DJANGO_PROJECT_NAME" ]; then
        sudo rm -f "/etc/nginx/sites-available/$DJANGO_PROJECT_NAME"
        echo "✓ Removed Nginx available site configuration"
        nginx_changes_made=true
    else
        echo "ℹ Nginx available site configuration not found"
    fi

    if [ "$nginx_changes_made" = true ]; then
        sudo systemctl restart nginx
        report_status "Restarted Nginx service"
    fi
fi

# 2. Check and remove Gunicorn service
if confirm_step "remove Gunicorn service"; then
    echo "Checking Gunicorn service..."
    if id "$LINUX_USER" &>/dev/null; then
        # Try to stop and disable the service
        sudo -u $LINUX_USER XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user stop $DJANGO_PROJECT_NAME.service 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✓ Stopped Gunicorn service"
        else
            echo "ℹ Gunicorn service was not running"
        fi

        sudo -u $LINUX_USER XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user disable $DJANGO_PROJECT_NAME.service 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✓ Disabled Gunicorn service"
        else
            echo "ℹ Gunicorn service was not enabled"
        fi

        SYSTEMD_DIR="/home/$LINUX_USER/.config/systemd/user"
        if [ -f "$SYSTEMD_DIR/$DJANGO_PROJECT_NAME.service" ]; then
            rm -f "$SYSTEMD_DIR/$DJANGO_PROJECT_NAME.service"
            echo "✓ Removed Gunicorn service file"
            sudo -u $LINUX_USER XDG_RUNTIME_DIR=/run/user/$(id -u $LINUX_USER) systemctl --user daemon-reload
            echo "✓ Reloaded systemd daemon"
        else
            echo "ℹ Gunicorn service file not found"
        fi
    else
        echo "ℹ Linux user not found, skipping Gunicorn service removal"
    fi
fi

# 3. Check and remove database
if confirm_step "remove database and database user"; then
    echo "Checking database..."
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
        echo "✓ Removed database: $DB_NAME"
    else
        echo "ℹ Database $DB_NAME not found"
    fi

    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
        echo "✓ Removed database user: $DB_USER"
    else
        echo "ℹ Database user $DB_USER not found"
    fi
fi

# 4. Check and remove repository
if confirm_step "remove repository directory"; then
    echo "Checking repository..."
    if [ -d "$REPO_ROOT" ]; then
        rm -rf "$REPO_ROOT"
        echo "✓ Removed repository directory: $REPO_ROOT"
    else
        echo "ℹ Repository directory not found: $REPO_ROOT"
    fi
fi

# 5. Check and remove user and group
if confirm_step "remove system user and group"; then
    echo "Checking system user and group..."
    if id "$LINUX_USER" &>/dev/null; then
        # Disable user login
        sudo loginctl disable-linger $LINUX_USER 2>/dev/null
        echo "✓ Disabled user login for $LINUX_USER"

        # Kill all processes owned by the user
        pkill -u "$LINUX_USER" 2>/dev/null
        echo "✓ Terminated all processes for user $LINUX_USER"

        # Remove user
        sudo userdel -r "$LINUX_USER" 2>/dev/null
        echo "✓ Removed user: $LINUX_USER"
    else
        echo "ℹ User $LINUX_USER not found"
    fi

    if getent group "$LINUX_GROUP" > /dev/null 2>&1; then
        sudo groupdel "$LINUX_GROUP" 2>/dev/null
        echo "✓ Removed group: $LINUX_GROUP"
    else
        echo "ℹ Group $LINUX_GROUP not found"
    fi
fi

# Final cleanup check
if confirm_step "remove user home directory"; then
    if [ -d "$LINUX_USER_HOME" ]; then
        rm -rf "$LINUX_USER_HOME"
        echo "✓ Removed user home directory: $LINUX_USER_HOME"
    else
        echo "ℹ User home directory not found: $LINUX_USER_HOME"
    fi
fi

echo -e "\nUninstallation complete. See logs above for records of failed steps."
echo "The following packages, which might have been installed by the deploy script, are still installed on the system:"
echo "   - python3"
echo "   - python3-venv"
echo "   - postgresql"
echo "   - nginx"
