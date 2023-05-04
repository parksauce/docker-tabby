#!/bin/bash
# Start Tabby

# Get Variables
read -ep "Enter a path to store your configuration files for tabby: " TABBY_PATH
echo ''
read -ep "Enter a password for the database (leave blank to generate one at random): " DB_PASSWORD
echo ''
id
read -ep "Enter your UID and GID separated by a space (optional, use the values above): " PUID PGID
echo ''
read -ep "Enter you timezone (optional, ex. America/New_York): " TZ
echo ''
read -ep "Enter a version for Tabby (if none is set latest will be used): " VERSION

# Get Mail server variables
echo -e '\n\n'
echo -e '\nMoving on to mail server configuration'
echo ''
read -ep "Enter your mail server's host. (ex. mail.example.com): " TABBY_SMTP_HOST
echo ''
read -ep "Enter you mail server's port. Typically, 465 or 587. (default: 465): " TABBY_SMTP_PORT
echo ''
read -ep "Enter your SMTP server's authentication method. Typically, PLAIN, LOGIN, CRAM-MD5. Any of those options should be entered in plane text and will be encoded on launch, any other methods should be hashed manually. (default: LOGIN): " TABBY_SMTP_AUTH_METHOD
echo ''
read -ep "Enter your SMTP server's user. (ex. user@example.com): " TABBY_SMTP_USER
echo ''
read -ep "Enter your SMTP user's password. (ex. MyPassword): " TABBY_SMTP_PASS
echo ''
read -ep "Enter Yes or No to use TLS. (default: Yes): " TABBY_SMTP_USE_TLS
echo ''
read -ep "Enter Yes or No to use STARTTLS. (default: No): " TABBY_SMTP_USE_STARTTLS



# Check if TABBY_PATH is set; if not error and exit
[[ -z $TABBY_PATH ]] && echo -e "\nCan't start container without a path for appdata\nAborting...\n" && exit
# Check for SMTP Host variable and warn
[[ -z $TABBY_SMTP_HOST ]] && echo -e "\nYou might want to specify a host or else you won't be able to send emails to an external SMTP server.\n"
# Check if DB_PASSWORD is set; if not generate a random one
[[ -z $DB_PASSWORD ]] && echo -e '\nDatabase Password not set\nGenerating one at random\n' && DB_PASSWORD=$(echo $RANDOM | md5sum | head -c 25; echo) && sleep 2
# Check if PUID and PGID is set; if not notify user; if PUID is set then it will use the same value for PGID
if [[ -z $PUID ]]; then echo -e "\nUID and GID left empty\nIt's suggested to input these as they help stop permissions errors with the database\nContinuing anyway..\n"; elif [[ -z $PGID ]]; then echo -e '\nGID left empty\nDefaulting to same as UID\n' && PGID=$PUID; fi && sleep 2
# Check if VERSION is set; if not use latest
[[ -z $VERSION ]] && echo -e '\nVersion not set\nDefaulting to latest' && VERSION=latest  && sleep 2

# Check if TABBY_SMTP_PORT is set; if not set default
[[ -z $TABBY_SMTP_PORT ]] && TABBY_SMTP_PORT=465
# Check if TABBY_SMTP_USE_TLS is set; if not set default
[[ -z $TABBY_SMTP_USE_TLS ]] && TABBY_SMTP_USE_TLS=Yes
# Check if TABBY_SMTP_USE_STARTTLS is set; if not set default
[[ -z $TABBY_SMTP_USE_STARTTLS ]] && TABBY_SMTP_USE_STARTTLS=No

# Create network for tabby, this is necessary if you don't want to expose the database port
# This may error if the network is already created but it doesn't cause any issues with the script
docker network create tabby

mkdir -p $TABBY_PATH

echo -e '\nPulling Containers'
docker pull -q parksauce/tabby
docker pull -q linuxserver/mariadb

echo -e '\nStarting Tabby'
docker run -d \
  --name=tabby \
  --network=tabby \
  -p 8010:80 \
  -e TZ=${TZ} \
  -e TABBY_SMTP_USER=${TABBY_SMTP_USER} \
  -e TABBY_SMTP_PASS=${TABBY_SMTP_PASS} \
  -e TABBY_SMTP_HOST=${TABBY_SMTP_HOST} \
  -e TABBY_SMTP_PORT=${TABBY_SMTP_PORT} \
  -e TABBY_SMTP_AUTH_METHOD=${TABBY_SMTP_AUTH_METHOD} \
  -e TABBY_SMTP_USE_TLS=${TABBY_SMTP_USE_TLS} \
  -e TABBY_SMTP_USE_STARTTLS=${TABBY_SMTP_USE_STARTTLS} \
  -v ${TABBY_PATH}/config:/config \
  --restart unless-stopped \
  parksauce/tabby:$VERSION

echo -e '\nStarting Tabby-DB'
docker run -d \
  --name=tabby-db \
  --network=tabby \
  -e PUID=${PUID} \
  -e PGID=${PGID} \
  -e MYSQL_ROOT_PASSWORD=${DB_PASSWORD} \
  -e TZ=${TZ} \
  -e MYSQL_DATABASE=tabby \
  -e MYSQL_USER=tabby \
  -e MYSQL_PASSWORD=${DB_PASSWORD} \
  -v ${TABBY_PATH}/db:/config \
  --restart unless-stopped \
  linuxserver/mariadb

echo -e '\n\nTabby should now be up and running, start by going to http://<HOST_IP>:8010'
echo 'Now fill in the installation form, be sure to use tabby-db as the hostname for the database'
echo 'The name of the database and user are both tabby'
echo "Your database password is: $DB_PASSWORD"
echo -e '\nEnjoy!\n'

exit
