# Adapted from https://github.com/EverythingMe/redash/blob/c9e74104b13aa4ad2f2d9aee2275f6aa70c387f7/setup/bootstrap.sh

FROM debian:wheezy

ENV REDASH_BASE_PATH /opt/redash
ENV FILES_BASE_URL https://raw.githubusercontent.com/EverythingMe/redash/docs_setup/setup/files/

# Base packages
RUN apt-get update && apt-get install -y \
  python-pip \
  python-dev \
  nginx \
  curl \
  build-essential \
  pwgen
RUN pip install -U setuptools

# redash user
RUN useradd -ms /bin/bash redash
USER redash
WORKDIR /home/redash

# PostgreSQL in a different container

# Redis in a different container

# Directories
mkdir /opt/redash
mkdir /opt/redash/logs

# Default config file

# Install latest version
ENV REDASH_VERSION 0.7.1.b1015
ENV LATEST_URL https://github.com/EverythingMe/redash/releases/download/v${REDASH_VERSION}/redash.$REDASH_VERSION.tar.gz
ENV VERSION_DIR /opt/redash/redash.$REDASH_VERSION
ENV REDASH_TARBALL /tmp/redash.tar.gz

# TODO: .env file should point to postgres/redis containers
RUN wget $LATEST_URL -O $REDASH_TARBALL \
  && mkdir $VERSION_DIR \
  && tar -C $VERSION_DIR -xvf $REDASH_TARBALL \
  && ln -nfs $VERSION_DIR /opt/redash/current \
  && ln -nfs /opt/redash/.env /opt/redash/current/.env

WORKDIR /opt/redash/current
RUN pip install -r requirements.txt

# Create database / tables
# https://github.com/EverythingMe/redash/blob/c9e74104b13aa4ad2f2d9aee2275f6aa70c387f7/setup/bootstrap.sh#L121-L152

# BigQuery dependencies:
RUN apt-get install -y libffi-dev libssl-dev

# MySQL dependencies:
RUN apt-get install -y libmysqlclient-dev

# Pip requirements for all data source types
WORKDIR /opt/redash/current
RUN pip install -r requirements_all_ds.txt

# Setup supervisord + sysv init startup script
RUN mkdir -p /opt/redash/supervisord
RUN pip install supervisor==3.1.2

# Get supervisord startup script
RUN wget -O /opt/redash/supervisord/supervisord.conf $FILES_BASE_URL"supervisord.conf"

RUN wget -O /etc/init.d/redash_supervisord $FILES_BASE_URL"redash_supervisord_init"
# TODO: add_service "redash_supervisord" https://github.com/EverythingMe/redash/blob/c9e74104b13aa4ad2f2d9aee2275f6aa70c387f7/setup/bootstrap.sh#L38-L57

# Nginx setup
RUN rm /etc/nginx/sites-enabled/default
RUN wget -O /etc/nginx/sites-available/redash $FILES_BASE_URL"nginx_redash_site"
RUN ln -nfs /etc/nginx/sites-available/redash /etc/nginx/sites-enabled/redash
RUN service nginx restart
