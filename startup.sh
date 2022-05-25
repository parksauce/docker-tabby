#!/bin/bash
# Start Tabby

# Get Necessary Variables
read -p "Enter a password for the database (leave blank to generate one at random): " DB_PASSWORD
echo ''
read -p "Enter you timezone (ex. America/New_York): " TZ
echo ''
read -p "Enter your UID and GID separated by a space (run 'id' to get these values): " PUID PGID
echo ''
read -p "Enter a path to store your configuration files for tabby: " TABBY_PATH

# Check if DB_PASSWORD is set if not generate a random one
if [[ -z "$DB_PASSWORD" ]]; then
  DB_PASSWORD=$(echo $RANDOM | md5sum | head -c 25; echo)
fi

# Check if TABBY_PATH is set if not error and exit
if [[ -z "$TABBY_PATH" ]]; then
  echo ''
  echo "Can't start container without a path for appdata"
  echo 'Aborting...'
  exit
fi

# Check if PUID and PGID is set, if not notify user; if PUID is set then it will use the same value for PGID
if [[ -z "$PUID" ]]; then
  echo ''
  echo "UID and GID left empty"
  echo "It's suggested to input these as they help stop permissions errors"
  echo 'Continuing anyway...'
  echo ''
elif [[ -z "$PGID" ]]; then
  echo ''
  echo "GID left empty"
  echo 'Defaulting to same as UID'
  PGID=$PUID
  echo ''
fi

# Create network for tabby, this is necessary if you don't want to expose the database port
# This may error if the network is already created but it doesn't cause any issues with the script
docker network create tabby

mkdir -p $TABBY_PATH

echo 'Pulling Containers'
docker pull -q parksauce/tabby
docker pull -q linuxserver/mariadb
echo ''

echo 'Starting Tabby'
docker run -d \
  --name=tabby \
  --network=tabby \
  -p 8010:80 \
  -e TZ=${TZ}
  -v ${TABBY_PATH}/config:/config \
  --restart unless-stopped \
  parksauce/tabby
echo ''

echo 'Starting Tabby-DB'
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

echo ''
echo ''
echo 'Tabby should now be up and running, start by going to http://<HOST_IP>:8010'
echo 'Now fill in the installation form, be sure to use tabby-db as the hostname for the database'
echo 'The name of the database and user are both tabby'
echo "Your database password is: $DB_PASSWORD"
echo ''
echo 'Enjoy!'

exit
