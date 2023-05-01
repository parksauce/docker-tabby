FROM ubuntu/apache2:2.4-22.04_edge

ARG TABBY_VERSION=1.2.2
ARG PHP_VERSION=

ENV TABBY_SMTP_HOST=
ENV TABBY_SMTP_PORT=465 
ENV TABBY_SMTP_USER=
ENV TABBY_SMTP_PASS=
ENV TABBY_SMTP_AUTH_METHOD=LOGIN
ENV TABBY_SMTP_USE_TLS=Yes
ENV TABBY_SMTP_USE_STARTTLS=No

RUN \
    echo 'Installing Build Dependencies' && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    apt-utils \
    software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y

RUN \
    echo 'Installing Runtime Packages' && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cron \
    ssmtp \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
    libapache2-mod-php${PHP_VERSION} \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-pgsql \
    openssl \
    xxd 

RUN \
    echo 'Prepare Environment' && \
    rm -r /etc/apache2/sites-enabled/* && \
    mkdir -p /defaults && \
    cp -r /etc/apache2 /defaults && \
    rm -r /etc/apache2

RUN \
    echo 'Clone Tabby' && \
    cd /defaults && git clone \
    https://github.com/bertvandepoel/tabby.git && \
    cd tabby && git checkout v${TABBY_VERSION}

RUN \
    echo 'Remove Build Dependencies' && \
    apt-get purge -y \
    git \
    apt-utils \
    software-properties-common

RUN \
    echo 'Updating Packages' && \
    apt-get update && apt-get upgrade -y && \
    apt-get autoremove -y

COPY rootfs /

RUN \
    echo 'Enable rewrite module' && \
    ln -sf /defaults/apache2/mods-available/rewrite.load /defaults/apache2/mods-enabled

RUN \
    echo 'Fix Permissions' && \
    chmod +x /defaults/init.sh && \
    echo 'Create sSMTP symbolic link to sendmail' && \
    ln -sf /usr/sbin/ssmtp /usr/sbin/sendmail

CMD bash /defaults/init.sh

EXPOSE 80
VOLUME /config