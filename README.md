# Documentation Also Available at [Park Sauce Docs](https://docs.parksauce.io)

# Goals
- Rebase the image from ubuntu to alpine to support more architectures
- Switch to NGINX as the webserver
- Add PUID and PGID environment variables

# Known Issues
- Emails not sending - this is because Tabby currently uses sendmail to send emails, however, from my research sendmail isn't robust enough to allow authentication to external email server's. Moreover, implementing an email server into this container is simply out of the scope for this project. I am looking around to see if there is anything that can accept sendmail requests and proxy those to an external email server. I am by no means a software developer and my specialties focus more on running and managing containers rather than anything software related. If anyone would like to help out with this project or has any suggestions I am all ears.

# Requirements
- Docker
- An internet connection
- Optional:
	- Docker Compose

# Credits
All credits to Tabby goes to the devs at [https://github.com/bertvandepoel/tabby](https://github.com/bertvandepoel/tabby). 

# Quick Start
This is the fastest way to get the service up and running, it will take you through a semi interactive startup to initialize the environment with a database. It will also give you some steps to connect tabby to the database. Use the code below to deploy tabby on your system, for production envrionments I recommend using [docker compose](#docker-compose).
```bash
# Copy the startup script to your computer
wget https://raw.githubusercontent.com/parksauce/tabby/main/startup.sh

# Run the script and follow the prompts
./startup.sh
```
Now you can access the container from `http://HOST_IP:8010`

# Advanced Configuration
This section covers a more in-depth guide on deploying Tabby on your server.

## Docker CLI
First create a network to connect both of the services to.
```bash
docker network create tabby-backend
```
Run the following command to start Tabby
```bash
docker run -d \
  --name=tabby \
  --network=tabby-backend \
  -p 8010:80 \
  --restart unless-stopped \
  parksauce/tabby
```
Then run this command to start the database
```bash
docker run -d \
  --name=mariadb \
  --network=tabby-backend \
  -e PUID=1000 \ # Run 'id' in your terminal to get this value
  -e PGID=1000 \ # Run 'id' in your terminal to get this value
  -e MYSQL_ROOT_PASSWORD=ROOT_ACCESS_PASSWORD \
  -e TZ=America/New_York \
  -e MYSQL_DATABASE=tabby \
  -e MYSQL_USER=tabby \
  -e MYSQL_PASSWORD=tabby \
  -v path_to_data:/config \
  --restart unless-stopped \
  linuxserver/mariadb
```

<br/>

## Docker Compose
Create a file named `docker-compose.yml` and then run `docker-compose pull && docker-compose up -d`
```bash
version: '3'
services:

  tabby:
    image: parksauce/tabby
    container_name: tabby
    ports:
      - 8010:80
    restart: unless-stopped
    
  db:
    image: linuxserver/mariadb
    container_name: tabby-db
    environment:
      - PUID=1000 # Run 'id' in your terminal to get this value
      - PGID=1000 # Run 'id' in your terminal to get this value
      - MYSQL_ROOT_PASSWORD=ROOT_ACCESS_PASSWORD
      - TZ=America/New_York
      - MYSQL_DATABASE=tabby
      - MYSQL_USER=tabby
      - MYSQL_PASSWORD=tabby
    volumes:
      - ./db:/config
    restart: unless-stopped
    
  #db:
  #  image: postgres
  #  container_name: tabby-db
  #  networks:
  #    - backend
  #  environment:
  #    - POSTGRES_DB=tabby
  #    - POSTGRES_USER=tabby
  #    - POSTGRES_PASSWORD=tabby
  #  volumes:
  #    - ./db:/var/lib/postgresql/data
  #  restart: unless-stopped

```

# Build
This section covers building the container.

<br/>

## Basic Build
This will clone the repo to your environment, then it will move to the `tabby` directory and build the container and name it tabby. By default the container uses Tabby version 1.2.2 which may become out of date at some point. Look into the [Advanced Build](#advanced-build) to change the version of Tabby while building the container.
```bash
git clone https://github.com/parksauce/tabby.git
cd tabby && docker build -t tabby .
```

<br/>

## Advanced Build
When building the container you are capable of using a few different build parameters to change the version of both Tabby and PHP in the container. You can use the below command as a template for whatever builds you want.

<br/>

### Clone Repo
First clone the repo and move to the `tabby` directory

```bash
git clone https://github.com/parksauce/tabby.git && cd tabby 
```

### Building the Container
We support a few different build arguments when building the container. Check [build arguments](#build-arguments) for more information. Below is an example to build the container for Tabby version 1.2.2 using the latest version of PHP.
```bash
docker build --build-arg TABBY_VERSION=1.2.2 -t tabby .
```
#### Build Arguments
The table below shows the different arguments we support
|  Argument | Function  |
|:---------:|:---------:|
| TABBY_VERSION | Changes the version of Tabby |
| PHP_VERSION|Change the version of PHP|

## License
This project is licensed under the AGPL license - see the [LICENSE](https://github.com/parksauce/tabby/blob/main/LICENSE) file for details.
