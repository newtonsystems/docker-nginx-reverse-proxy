#
# Newtonsystems Ltd.
#
# Nginx Reverse Proxy with HTTPs support
#
# We use supervisor to run mutliple processes
From debian:jessie

MAINTAINER James Tarball <james.tarball@newtonsystems.co.uk>

ENV NGINX_VERSION 1.10.3-1~jessie

# DNS name for server (must be valid and you must own it)
ENV DOMAIN_NAME example.com

ENV APP_DIR /app
# Email for letsencrypt
ENV EMAIL_ADMIN james.tarball@newtonsystems.co.uk
# Use environment variables instead of link name
ENV USE_ENVS_FOR_WEBSERVER FALSE
# Port for the Web Server
ENV WEB_SERVER_PORT 8080
# Enforce http to redirect to https
ENV ENFORCE_HTTPS TRUE
# URL Webhook for Mattermost when there is an error in cert renewal
ENV MATTERMOST_WEBHOOK_URL None

# Basic stuff...
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list \
    && echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

# Packages
# TODO: Can we remove some of the nginx modules?
RUN apt-get -yq update && apt-get -yq install \
        sudo \
        build-essential \
        vim \
        curl \
        python-dev \
        python \
        python-pip \
		ca-certificates \
		nginx=${NGINX_VERSION} \
		gettext-base \
		certbot -t jessie-backports \
		supervisor \
		cron \
		ruby \
		ruby-dev \
		wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $APP_DIR
RUN mkdir -p $APP_DIR/logs

# Need newer ruby (above 2.2.0) so we can add variables to erb cli commands
RUN mkdir -p /tmp/ruby-build && \
    cd /tmp/ruby-build && \
    wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz && \
    tar xvfz ruby-2.3.0.tar.gz && \
    cd ruby-2.3.0 && \
    ./configure && \
    make && \
    sudo make install && \
    sudo make clean

# In order to have environment variables passed to supervisord we 
# need a newer version of supervisor ( > 3.0)
RUN pip install --upgrade supervisor

COPY config/supervisord.conf /etc/supervisor/supervisord.conf
COPY config/ $APP_DIR/config/

# Set up Cron 
RUN crontab $APP_DIR/config/crontab
RUN chmod +x $APP_DIR/config/update_certs.sh

# Set up Nginx
# Remove default NGINX config
RUN rm /etc/nginx/conf.d/default.conf

# Set up Application log files 
# (Creates links to /var/log because it is nice)
RUN touch $APP_DIR/logs/renewal.log
RUN ln -sf $APP_DIR/logs /var/log/app


EXPOSE 80 443

# Must pass all docker environment variables to Supervisor
CMD env | grep _ >> /etc/environment && /usr/bin/supervisord
