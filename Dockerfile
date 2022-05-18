FROM ubuntu/apache2:latest

ARG TABBY_VERSION=1.2.2
ARG PHP_VERSION=

RUN \
    echo 'Installing Build Dependencies' && \
    apt-get update && apt-get install -y \
    apt-utils \
    software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    echo 'Installing Runtime Packages' && \
    apt-get update && apt-get install -y \
    git \
    cron \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
    libapache2-mod-php${PHP_VERSION} \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-pgsql && \
    echo 'Prepare Environment' && \
    rm -r /etc/apache2/sites-enabled/* && \
    mkdir -p /defaults && \
    cp -r /etc/apache2 /defaults && \
    rm -r /etc/apache2 && \
    echo 'Clone Tabby' && \
    cd /defaults && git clone \
    https://github.com/bertvandepoel/tabby.git && \
    cd tabby && git checkout v${TABBY_VERSION} && \
    echo 'Remove Build Dependencies' && \
    apt-get purge -y \
    apt-utils \
    software-properties-common && \
    echo 'Updating Packages' && \
    apt-get update && apt-get upgrade -y && \
    apt-get autoremove -y

COPY rootfs /

RUN \
    echo 'Fix Permissions' && \
    chmod 755 /defaults/apache2/sites-enabled/tabby.conf && \
    chmod +x /defaults/init.sh

CMD bash /defaults/init.sh

EXPOSE 80
VOLUME /config