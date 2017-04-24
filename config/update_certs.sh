#!/bin/bash
#
# Newtonsystems Ltd.
# James Tarball
#
# A simple update certificates sript for nginx HTTPS
#
#
# FUTURE: Support emailing errors (possibly a service)
#         to give beautiful/consistent support emails
TEMP_PROXY_CONF=/tmp/reverse_proxy.conf
NGINX_CONF=/etc/nginx/conf.d/reverse_proxy.conf
NGINX_MAIN_CONF=/etc/nginx/nginx.conf
TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

create_reload_nginx_conf() {
    # Create nginx configuration based on .erb 
    # and then check is valid, finally move into 
    # place if successful
    erb https_enable=$1 set_dhparam=$2 $APP_DIR/config/reverse_proxy.erb > $TEMP_PROXY_CONF
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [WARNING]: ERB command failed. Failed to create NGINX configuration. This shouldnt happen ..."
        exit 1
    fi

    nginx -tc $APP_DIR/config/default_test.conf
    if [ $? -eq 0 ]; then
        echo "$TIMESTAMP  [INFO] Tested NGINX configuration from erb template"
    else
        echo "$TIMESTAMP  [ERROR] NGINX configuration check failed. NGINX configuration cannot be created."
        exit 1
    fi;

    echo "[INFO] Moving nginx configuration into place"
    cp $TEMP_PROXY_CONF $NGINX_CONF
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [ERROR] Failed to copy NGINX to location ($TEMP_PROXY_CONF -> $NGINX_CONF)"
    fi

    echo "[INFO] Retesting configuration and reloading NGINX ..."
    nginx -tc $NGINX_MAIN_CONF
    if [ $? -eq 0 ]; then
        echo "$TIMESTAMP  [INFO] Tested final NGINX configuration from erb template"
    else
        echo "$TIMESTAMP  [ERROR] NGINX final configuration check failed. NGINX configuration cannot be created."
        rm $NGINX_CONF
        exit 1
    fi;

    nginx -s reload
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [ERROR]: NGINX reload command failed. Failed to create nginx configuration. This shouldnt happen ..."
        rm $NGINX_CONF
        exit 1
    fi
}


# https://letsencrypt.org/docs/staging-environment/
if [ -z "$DOMAIN_NAME" ]; then
    echo "$TIMESTAMP  [ERROR] The environment variable DOMAIN_NAME needs to be set."
    exit 1
fi


[[ -d /etc/letsencrypt/live/$DOMAIN_NAME ]] && certs_set=TRUE
[[ -f /etc/pki/nginx/dhparams.pem ]] && dhparams_set=TRUE
[[ -f $NGINX_CONF ]] && conf_set=TRUE

# Renew if configuration has been set up
# else setup up config by creating certs/keys
if [[ $certs_set = TRUE && $dhparams_set = TRUE && $conf_set = TRUE ]]; then
    echo "$TIMESTAMP  [INFO] Attempting renew of certs"
    certbot renew --post-hook "/usr/sbin/nginx -s reload"
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [ERROR] Certbot command failed. Renew failed."
        exit 1
    fi

else
    echo "$TIMESTAMP  [RUN] Creating template for the first time ..."
    create_reload_nginx_conf FALSE FALSE

    echo "$TIMESTAMP  [RUN] Creating Certificates for the first time ..."
    certbot certonly --keep --agree-tos --email $EMAIL_ADMIN --webroot -w /usr/share/nginx/html --text -d $DOMAIN_NAME
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [ERROR] Certbot command failed. Failed certs creation."
        if [ $MATTERMOST_WEBHOOK_URL != "None" ]; then
            MESSAGE="Certbot Failed to renew certs on $DOMAIN_NAME [$HOSTNAME]."
            TAIL_LAST=$(tail -n 10 /var/log/app/renewal.log)
            curl -i -X POST -d 'payload={"attachments": [{
                "fallback": "The attachment isnt supported.",
                "title": "ERROR",
                "color": "#9C1A22",
                "pretext": "Renewal.log",
                "mrkdwn": false,
                "text": "'"$TAIL_LAST"'"
            }], "text": "'"$MESSAGE"'"}' $MATTERMOST_WEBHOOK_URL
        fi
        exit 1
    fi

    echo "$TIMESTAMP  [RUN] Creating dhparams.pem for the first time"
    mkdir -p /etc/pki/nginx
    cd /etc/pki/nginx && openssl dhparam -out dhparams.pem 2048
    if [ $? -ne 0 ]; then
        echo "$TIMESTAMP  [ERROR] Creating dhparams.pem command failed."
        exit 1
    fi

    create_reload_nginx_conf TRUE TRUE

    echo "$TIMESTAMP  [SUCCESS] HTTPs Reverse Proxy has been set up correctly"
    echo "${TIMESTAMP}  [SUCCESS]  Check your SSL ratings at: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN_NAME&latest"
fi



