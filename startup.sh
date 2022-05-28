#!/bin/bash
# Start Tabby

# Get Variables
read -p "Enter a path to store your configuration files for tabby (mandatory): " TABBY_PATH
echo ''
read -p "Enter a password for the database (leave blank to generate one at random): " DB_PASSWORD
echo ''
id
read -p "Enter your UID and GID separated by a space (optional, use the values above): " PUID PGID
echo ''
read -p "Enter you timezone (optional, ex. America/New_York): " TZ
echo ''
read -p "Enter a version for Tabby (if none is set latest will be used):" VERSION

# Check if TABBY_PATH is set; if not error and exit
[[ -z $TABBY_PATH ]] && echo -e "\nCan't start container without a path for appdata\nAborting...\n" && exit
# Check if DB_PASSWORD is set; if not generate a random one
[[ -z $DB_PASSWORD ]] && echo -e '\nDatabase Password not set\nGenerating one at random\n' && DB_PASSWORD=$(echo $RANDOM | md5sum | head -c 25; echo)
# Check if PUID and PGID is set; if not notify user; if PUID is set then it will use the same value for PGID
[[ -z $PUID ]] && echo -e "\nUID and GID left empty\nIt's suggested to input these as they help stop permissions errors with the database\nContinuing anyway..\n" || [[ -z $PGI ]] && echo -e '\nGID left empty\nDefaulting to same as UID\n' && PGID=$PUID
# Check if VERSION is set; if not use latest
[[ -z $VERSION ]] && echo -e '\nVersion not set\nDefaulting to latest' && VERSION=latest

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
  -e TZ=${TZ}
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
