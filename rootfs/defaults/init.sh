#!/bin/bash
# Initialize tabby environment

mkdir -p /config

if [ ! "$(ls -A /config/apache2 2>/dev/null)" ]; then 
    cp -rf /defaults/apache2 /config
    echo "empty (directory or file)" 
fi

cp -rf /defaults/tabby /config
chown -R www-data:www-data /config/tabby

rm -rf /var/www/tabby /etc/apache2
ln -s /config/tabby /var/www
ln -s /config/apache2 /etc

service cron start
apachectl -D FOREGROUND