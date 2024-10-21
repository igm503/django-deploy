# Django Deployment
A framework for easily deploying PostgreSQL Django projects on Debian-based servers. Mostly follows [Michal Karzynski's advice](https://michal.karzynski.pl/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/).

This framework assumes you will develop your django project and edit your database locally and then push the changes to the server periodically, e.g. via GitHub.

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
This repo currently servers as a template. (In the future, I'll probably make it work as a submodule.) Before starting your new Django project,
1. Download this repo to your dev environment (don't clone it, or else you'll have to deal with my commit history)
2. Create your django project in a directory called ```django```:
```
mkdir django
django-admin startproject your-project-name django
```
3. Do your thing, making sure to keep your repository like this:

```
.
├── ...
├── deployment              
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
├── .env            
├── requirements.txt             
└── ...
```

## Deploying your Django Project
Once you're ready to deploy your project, 
1. ssh into or otherwise get root access on your server (see [above](#requirements) for the server requirements)
2. Clone your repository onto the server. It doesn't matter where.
```
root@your-server:~# git clone https://github.com/user/project.git
```
3. ```cd``` into the repository's root directory
4. Create and configure a ```.env``` file from the ```example.env``` template

   
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
6. Run the ```deployment/deploy.sh``` script as root
7. [Optional] If you want to use Certbot to get a certificate, run the ```deployment/certbot.sh``` script as root and answer the questions.
   
All together:
```
root@your-server:~# git clone https://github.com/user/project.git
root@your-server:~# cd project
root@your-server:~/project# ./deployment/deploy.sh

# [Optional] Get a certificate

# project/ has been moved to /home/$LINUX_USER/project by deploy.sh

root@your-server:~/project# cd /home/example_user/project
root@your-server:/home/example_user/project# ./deployment/certbot.sh
```

### Troubleshooting

Sometimes, the first time your run ```deployment/deploy.sh``` it will fail when creating the Gunicorn service. That's fine, just navigate to your project (it has been moved to your linux user's home dir) and run the script again. The script is mostly idempotent.

One way the deploy script isn't idempotent, however, is that it'll remove the Certbot certificate config from your nginx site config. If you rerun ```deployment/deploy.sh``` after running ```deployment/certbot.sh```, just run the certbot script again. Be sure to tell certbot to use the certificate you already have when prompted, unless for some reason you want it to generate a new certificate.

Sometimes, nginx won't connect to the Gunicorn server. In my experience, manually restarting nginx usually fixes this. 

## Updating your Server's Database or Static Files

If you've deployed your app but want to update the static files or database with changes that you've made locally, you can easily update the database and/or static file directory on your server as follows:

1. Make your local changes to the database or static files
2. Navigate in your command line to the root directory of the django project, i.e. `cd /path-to-your-repo/django`
3. If you made changes to the database models, run `python manage.py makemigrations` and `python manage.py migrate`, if you haven't already
4. If you made changes to the content of the database, run

    ```python manage.py dumpdata --exclude auth --exclude contenttypes --exclude admin --exclude sessions --natural-primary --natural-foreign --indent 2 > ../deployment/db.json```
   
   - This will create or overwrite a json file in the deployment folder called `db.json`
   - If you're overwriting, make sure you have a backup of this file first, either locally or on GitHub
   - If for some reason you want to include auth, admin, or sessions tables, then remove the "--exclude" flags for those table groups
5. Commit and push your changes, making sure to include the new migrations and/or db.json file, or, if you modified static files, 
6. On your server, navigate to the root of the repository and run `bash deployment/update.sh`

## TODO
- Repackage so that repo can be used as a submodule

## Updates
- 10-21-2024: Updated Deployent Setup Script; Update and Certificate Scripts
- 10-19-2024: Installation and Deployment Setup Scripts
- 10-16-2024: Initial Commit
