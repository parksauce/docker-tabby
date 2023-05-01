#!/bin/bash
# Initialize tabby environment

mkdir -p /config

if [ ! "$(ls -A /config/apache2 2>/dev/null)" ]; then 
    cp -rf /defaults/apache2 /config
    echo "empty (directory or file)" 
fi

if [[ $TABBY_SMTP_AUTH_METHOD = 'LOGIN' ]]; then
    # Convert plain text password into base64
    TABBY_SMTP_PASS=$(echo $TABBY_SMTP_PASS | base64)
fi

# Copy tabby defaults back to config folder and fix permissions
cp -rf /defaults/tabby /config
chown -R www-data:www-data /config/tabby

# Update sSMTP configuration
cp -rf /defaults/ssmtp /etc
sed -i "s|smtp_host|$TABBY_SMTP_HOST|g" /etc/ssmtp/ssmtp.conf
sed -i "s|smtp_port|$TABBY_SMTP_PORT|g" /etc/ssmtp/ssmtp.conf
sed -i "s|smtp_user|$TABBY_SMTP_USER|g" /etc/ssmtp/ssmtp.conf
sed -i "s|smtp_pass|$TABBY_SMTP_PASS|g" /etc/ssmtp/ssmtp.conf
sed -i "s|auth_method|$TABBY_SMTP_AUTH_METHOD|g" /etc/ssmtp/ssmtp.conf
sed -i "s|use_tls|$TABBY_SMTP_USE_TLS|g" /etc/ssmtp/ssmtp.conf
sed -i "s|use_starttls|$TABBY_SMTP_USE_STARTTLS|g" /etc/ssmtp/ssmtp.conf

# Create/redo Symbolic links
rm -rf /var/www/tabby /etc/apache2
ln -s /config/tabby /var/www
ln -s /config/apache2 /etc

# Start cron service & run apache2
service cron start
apachectl -D FOREGROUND &

# Set up trap to catch SIGTERM signal and stop Apache2
trap "echo 'Stopping Apache2'; apachectl -k graceful-stop; exit 0" SIGTERM

# Keep container running indefinitely
sleep infinity