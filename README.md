# Django Deployment [WIP]
A framework for creating Django projects and easily deploying them on linux servers. Mostly follows [Michal Karzynski's advice](https://michal.karzynski.pl/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/).

This framework assumes you will develop your django project and edit your database on a local machine and then push the changes to the server periodically via a repository hosted on GitHub. 

## Features
- Automated Server Configuration and App Deployment
-- Handles Linux user creation, PostgreSQL, Nginx, and Python env Installation (if you're not using PostgreSQL, you'll have to tweak a few things)
-- Creates, configures, and Loads Data into database
-- Creates and configures Gunicorn + Nginx services
-- Database and Static File update scripts

## Getting Started 

## Deploying your Django Project

## Updating your Server's Database or Static Files

1. Make your local changes to the database or static files
2. Navigate in your command line to the root directory of the django project, e.g., if you are in the root of this repo, `cd django`

Repo/ \
-- deployment/ \
---- templates/ \
---- db.json \
---- deploy.sh \
---- ... \
-- django/ <-- cd to this directory \
---- your-django-project/ \
------ __init__.py \
------ asgi.py \
------ ... \
---- your-django-app/ \
---- manage.py \
---- ... \
-- static/ \
-- requirements.txt \
-- .env 

2. If you made changes to the database models, run `python manage.py makemigrations` and `python manage.py migrate`, if you haven't already
3. If you made changes to the content of the database, run

    ```python manage.py dumpdata --exclude auth --exclude contenttypes --exclude admin --exclude sessions --natural-primary --natural-foreign --indent 2 > ../deployment/db.json```
   
- This will create or overwrite a json file in the deployment folder called `db.json`
- If you're overwriting, make sure you have a backup of this file first, either locally or on GitHub
- If for some reason you want to include auth, admin, or sessions tables, then remove the "--exclude" flags for those table groups
4. Commit and push your changes, making sure to include the new migrations and/or db.json file, or, if you modified static files, 
5. On your server, navigate to the root of the repository and run `bash deployment/update.sh`

## TODO
- getting started instructions
- automated updates (db migrations, data inserts, and static collection + reloading)

## Updates
- 10-19-2024: Installation and Deployment Setup Scripts
- 10-16-2024: Initial
