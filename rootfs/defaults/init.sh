#!/bin/bash
# Initialize tabby environment

mkdir -p /config

if [ -n "$(find /config/apache2 -prune -empty 2>/dev/null)" ]
then
    cp -rf /defaults/apache2 /config
  echo "empty (directory or file)"
else
  echo "contains files (or does not exist)"
fi

cp -rf /defaults/tabby /config

chown -R www-data:www-data /config/tabby

ln -s /config/tabby /var/www
ln -s /config/apache2 /etc

service cron start
apachectl -D FOREGROUND