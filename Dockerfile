FROM php:8.3-fpm-alpine

ARG TABBY_VERSION=1.2.2

ENV TABBY_SMTP_HOST=
ENV TABBY_SMTP_PORT=465
ENV TABBY_SMTP_USER=
ENV TABBY_SMTP_PASS=
ENV TABBY_SMTP_AUTH_METHOD=login
ENV TABBY_SMTP_USE_TLS=on
ENV TABBY_SMTP_USE_STARTTLS=off

RUN apk add --no-cache \
        nginx \
        msmtp \
        git \
        libpq \
    && apk add --no-cache --virtual .build-deps libpq-dev \
    && docker-php-ext-install pdo_mysql pdo_pgsql \
    && apk del .build-deps \
    && mkdir -p /defaults \
    && git clone https://github.com/bertvandepoel/tabby.git /defaults/tabby \
    && cd /defaults/tabby && git checkout v${TABBY_VERSION} \
    && rm -rf /defaults/tabby/.git \
    && apk del git

COPY rootfs /

RUN chmod +x /defaults/init.sh \
    && ln -sf /usr/bin/msmtp /usr/sbin/sendmail \
    && mkdir -p /run/nginx /var/www

CMD ["/bin/sh", "/defaults/init.sh"]

EXPOSE 80
VOLUME /config
