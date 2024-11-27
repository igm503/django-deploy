# Django Deployment
A tool for easily deploying PostgreSQL Django projects on Debian-based servers. Mostly follows [Michal Karzynski's advice](https://michal.karzynski.pl/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/).

Assumes you will develop your django project and edit your database locally and then push the changes to the server periodically, e.g. via GitHub.

## Warning
Please don't use this with anything important or fragile if you're not basically ok with it breaking. No guarantees here about safety.

## Features
- Automated Server Configuration
  - Linux user creation
  - PostgreSQL, Nginx, and Python env installation
- Django Project Deployment
  - Creates, configures, and Loads Data into your database
  - Creates and configures Gunicorn + Nginx services
  - HTTPS certificate installation via [Certbot](https://certbot.eff.org/)
- Easy Database and Static File Updating

## Requirements
- Linux Server with a Debian-based distro (needs to use APT)
- You use PostgreSQL for your database (if you're not using PostgreSQL, you'll have to tweak a few things)
- You're ok using nginx + Gunicorn to serve your app
- Some repository structure constraints (see [below](#getting-started))

## Getting Started 
This repo is meant to be used as a submodule. It requires your repository to be structured as follows:
```
.
├── ...
├── django                      # your django project
│   ├── your-project-name/
│   │   └── ...
│   ├── app1/
│   │   └── ...
│   ├── manage.py           
│   └── ...
├── static/                     # this is where your static files will be collected when deployed
│   └── ...
├── requirements.txt            # your project's requirements
└── ...
```
If that's the case, then you can add this repo as submodule to the root of your repository:
```
cd /path/to/your/repo && git submodule add https://github.com/igm503/django-deploy
```
The resulting structure will be:
```
.
├── ...
├── django-deploy               # the new submodule
│   ├── templates/
│   │   └── ...         
│   ├── certbot.sh             
│   ├── deploy.sh             
│   ├── update.sh            
│   └── ...
├── django                      # your django project
│   ├── your-project-name/
│   │   └── ...
│   ├── app1/
│   │   └── ...
│   ├── manage.py           
│   └── ...
├── static/                     # this is where your static files will be collected when deployed
│   └── ...
├── requirements.txt            # your project's requirements
└── ...
```
Now do whatever you want, provided that you keep the specified directories organized in the same way. 

## Deploying your Django Project
Once you're ready to deploy your project, 
1. ssh into or otherwise get root access on your server (see [above](#requirements) for the server requirements)
2. Clone your repository onto the server. It doesn't matter where.
```
root@your-server:~# git clone https://github.com/user/project.git
```
3. ```cd``` into the repository's root directory
4. Initialize the django-deploy submodule:
```
root@your-server:~/project# git submodule update --init
```
4. Create and configure a ```django-deploy/.env``` file from the ```django-deploy/example.env``` template

   
     ```
     DJANGO_PROJECT_NAME=...   # The name you used when creating your django project
     DJANGO_SECRET_KEY=...     # You can get one [here](https://djecrety.ir/) if you want
     LINUX_USER=...            # Name of the linux user to create to run the server
     LINUX_GROUP=...           # Name of the group of the linux user
     LINUX_USER_HOME=...       # Home dir of the linux user. Don't change from default unless you want to do something weird
     REPO_ROOT=...             # Where to move your repository to. Don't change from default unless you want to do something weird
     DOMAIN_NAME=...           # Your domain. This is to configure Django to allow traffic using this hostname
     DB_NAME=...               # Name of the PostgreSQL database to create for your app. Make sure it's a valid name
     DB_USER=...               # Name of the PostgreSQL user to create
     DB_PASS=...               # Password for the PostgreSQL user
     DB_HOST=...               # Don't change this unless you already have a database server running on a different machine
     DB_PORT=...               # Don't change this unless you already have a database server running on a different port
     ```
6. Run the ```django-deploy/deploy.sh``` script as root
   - [What exactly will this do?](#what-does-deploy.sh-do-)
7. [Optional] If you want to use Certbot to get a certificate, run the ```django-deploy/certbot.sh``` script as root and answer the questions.
   
All together:
```
root@your-server:~# git clone https://github.com/user/project.git
root@your-server:~# cd project
root@your-server:~/project# git submodule update --init
root@your-server:~/project# ./django-deploy/deploy.sh

# [Optional] Get a certificate

# project/ has been moved to /home/$LINUX_USER/project by deploy.sh

root@your-server:~/project# cd /home/example_user/project
root@your-server:/home/example_user/project# ./django-deploy/certbot.sh
```

### Troubleshooting

Sometimes, the first time your run ```django-deploy/deploy.sh``` it will fail when creating the Gunicorn service. That's fine, just navigate to your project (it has been moved to your linux user's home dir) and run the script again. The script is mostly idempotent.

One way the deploy script isn't idempotent, however, is that it'll remove the Certbot certificate config from your nginx site config. If you rerun ```deployment/deploy.sh``` after running ```deployment/certbot.sh```, just run the certbot script again. Be sure to tell certbot to use the certificate you already have when prompted, unless for some reason you want it to generate a new certificate.

Sometimes, nginx won't connect to the Gunicorn server. In my experience, manually restarting nginx usually fixes this. 

## Restarting or Checking the Status of your Web Server

The deployment script will create nginx and gunicorn services to run your web server. The gunicorn service is owned by the user you specify in the ```django-deploy/.env``` file. As a result, checking the status or restarting the gunicorn service can be annoying if you aren't logged in as that user. 

To check the status of the nginx and gunicorn services more easily, you can run the ```django-deploy/status.sh``` script as root with the argument of the service you want to check:
```
# Check the status of the gunicorn service
root@your-server:/path/to/your/repo# ./django-deploy/status.sh gunicorn

# Check the status of the nginx service
root@your-server:/path/to/your/repo# ./django-deploy/status.sh nginx
```
To restart the services, run the ```django-deploy/restart.sh``` script as root, with the argument of the service you want to restart:
```
# Restart the gunicorn service
root@your-server:/path/to/your/repo# ./django-deploy/restart.sh gunicorn

# Restart the nginx service
root@your-server:/path/to/your/repo# ./django-deploy/restart.sh nginx

# Restart both services
root@your-server:/path/to/your/repo# ./django-deploy/restart.sh all
```

## Updating your Server's Database or Static Files

If you've deployed your app but want to update the static files or database with changes that you've made locally, you can easily update the database and/or static file directory on your server as follows:

1. Make your local changes to the database or static files
2. Navigate in your command line to the root directory of the django project, i.e. `cd /path-to-your-repo/django`
3. If you made changes to the database models, run `python manage.py makemigrations` and `python manage.py migrate`, if you haven't already
4. If you made changes to the content of the database, run

    ```
   python manage.py dumpdata --exclude auth --exclude contenttypes --exclude admin --exclude sessions --natural-primary --natural-foreign --indent 2 > ../db.json
    ```
   
   - This will create or overwrite a json file in the repo root dir called `db.json`
   - If you're overwriting, make sure you have a backup of this file first, either locally or on GitHub
   - If for some reason you want to include ```auth```, ```admin```, or ```sessions``` tables, then remove the ```--exclude``` flags for those table groups
6. Commit and push your changes, making sure to include the new migrations and/or db.json file, or, if you modified static files, 
7. On your server, navigate to the root of the repository and run the `django-deploy/update.sh` script as root.
```
root@your-server:/path/to/your/repo# ./django-deploy/update.sh
```

## Uninstalling your Web Server

If you want to uninstall your web server, run the ```django-deploy/uninstall.sh``` script as root:
```
root@your-server:/path/to/your/repo# ./django-deploy/uninstall.sh
```
You will be prompted for confirmation before uninstalling, and have the option to only undo certain parts of the installation process.

## What Does deploy.sh Do to Your Server?

1. **System User Configuration**
   - Creates a system group (DJANGO_GROUP) if it doesn't exist
   - Creates a system user (DJANGO_USER) if it doesn't exist
   - Creates the user's home directory

2. **System Dependencies**
   - Updates package lists
   - Installs system packages:
     - Python 3
     - Python virtual environment
     - PostgreSQL
     - Nginx

3. **Repository Setup**
   - Moves your repository to the specified root directory (/home/DJANGO_USER/DJANGO_PROJECT_NAME)
   - Sets repo owner to the new system user (DJANGO_USER)

4. **Database Configuration**
   - Creates PostgreSQL user if it doesn't exist
   - Creates database with specified name
   - Assigns database ownership to the created user

5. **Python Environment**
   - Creates a new Python virtual environment
   - Upgrades pip to latest version
   - Installs dependencies from:
     - requirements.txt in this submodule
     - requirements.txt in the root of your repository

6. **Django Settings**
   - Moves a deployment-specific settings file (```templates/settings_django_deploy.py```) into your django project

7. **Gunicorn Setup**
   - Creates Gunicorn start script from template (```templates/gunicorn_start.sh.template```)
   - Creates a socket directory if it doesn't exist (```/REPO_ROOT/run```)
   - Generates systemd unit file for Gunicorn from template (```templates/django-gunicorn.service.template```)
   - Enables and starts the service

8. **Nginx Configuration**
   - Creates log directory if it doesn't exist (```REPO_ROOT/logs```)
   - Generates Nginx configuration from template (```templates/django-nginx.conf.template```)
   - Sets up site configuration in sites-available/sites-enabled
   - Restarts Nginx service

9. **Django Configuration**
    - Collects static files (places them in ```REPO_ROOT/static```)
    - Runs DB migrations
    - Loads data from ```REPO_ROOT/db.json``` if it exists
    - Restarts Gunicorn

## Notes
- The script uses environment variables extensively for configuration
- Includes error checking and idempotency (can be run multiple times safely)
- Automatically handles service restarts and system user setup

## Updates
- 11-26-2024: Repackaged to be used as a submodule. Added instructions for restart and status scripts
- 10-21-2024: Updated Deployent Setup Script; Update and Certificate Scripts
- 10-19-2024: Installation and Deployment Setup Scripts
- 10-16-2024: Initial Commit
