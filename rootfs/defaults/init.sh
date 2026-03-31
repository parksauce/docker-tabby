#!/bin/sh
set -euo pipefail

mkdir -p /config

# Copy tabby app to config and fix permissions
cp -rf /defaults/tabby /config
chown -R www-data:www-data /config/tabby

# Create web root symlink
rm -rf /var/www/tabby
ln -s /config/tabby /var/www/tabby

# Convert auth method to lowercase (msmtp expects lowercase)
AUTH_METHOD=$(echo "${TABBY_SMTP_AUTH_METHOD}" | tr '[:upper:]' '[:lower:]')

# Convert Yes/No/True/False to on/off for msmtp tls settings
yes_to_on() {
    local val
    val=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ "$val" == "yes" || "$val" == "true" || "$val" == "on" ]]; then
        echo "on"
    else
        echo "off"
    fi
}
TLS_VAL=$(yes_to_on "${TABBY_SMTP_USE_TLS}")
STARTTLS_VAL=$(yes_to_on "${TABBY_SMTP_USE_STARTTLS}")

# Write msmtp configuration
cp -f /defaults/msmtp/msmtprc /etc/msmtprc
sed -i "s|smtp_host|${TABBY_SMTP_HOST}|g" /etc/msmtprc
sed -i "s|smtp_port|${TABBY_SMTP_PORT}|g" /etc/msmtprc
sed -i "s|smtp_user|${TABBY_SMTP_USER}|g" /etc/msmtprc
sed -i "s|smtp_pass|${TABBY_SMTP_PASS}|g" /etc/msmtprc
sed -i "s|auth_method|${AUTH_METHOD}|g" /etc/msmtprc
sed -i "s|use_tls|${TLS_VAL}|g" /etc/msmtprc
sed -i "s|use_starttls|${STARTTLS_VAL}|g" /etc/msmtprc
chown www-data:www-data /etc/msmtprc
chmod 600 /etc/msmtprc

# Start cron
crond

# Start PHP-FPM in background
php-fpm &

# Start nginx in foreground (keeps container alive, receives SIGTERM)
exec nginx -g 'daemon off;'
