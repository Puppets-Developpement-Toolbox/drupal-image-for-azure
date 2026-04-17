FROM php:8.3-cli-alpine

RUN rm -rf /opt/drupal && mkdir -p /opt/drupal
WORKDIR /opt/drupal

# Install Apache + runtime deps
RUN apk add --no-cache \
    apache2 \
    apache2-ssl \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    libzip \
    icu-libs \
    libxml2 \
    oniguruma \
    curl \
    gettext \
    jq \
    openssh \
    git \
    mariadb-client \
    parallel

# Install PHP extensions
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    icu-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    libxml2-dev

RUN pecl install uploadprogress apcu \
    && docker-php-ext-install mysqli opcache intl gd zip \
    && docker-php-ext-enable uploadprogress apcu

RUN apk del .build-deps

# Apache config for Drupal
RUN sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' \
    /etc/apache2/httpd.conf \
 && sed -i 's/AllowOverride None/AllowOverride All/' \
    /etc/apache2/httpd.conf

# Security headers
RUN echo "ServerTokens Prod" >> /etc/apache2/httpd.conf \
 && echo "ServerSignature Off" >> /etc/apache2/httpd.conf \
 && echo 'Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"' >> /etc/apache2/httpd.conf

# Enable modules
RUN echo "LoadModule headers_module modules/mod_headers.so" >> /etc/apache2/httpd.conf \
 && echo "LoadModule expires_module modules/mod_expires.so" >> /etc/apache2/httpd.conf

# PHP config
COPY config/php.ini /usr/local/etc/php/conf.d/puppets-php.ini

# Scripts
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-drupal-entrypoint
COPY scripts/load-azure-secrets.sh /usr/local/bin/load-azure-secrets
COPY scripts/deploy.sh /usr/local/bin/drupal-deploy
COPY scripts/deploy-rollback.sh /usr/local/bin/drupal-deploy-rollback
COPY scripts/drush-www.sh /usr/local/bin/drush-www
COPY scripts/profile-azure-env.sh /usr/local/bin/profile-azure-env.sh

RUN chmod +x /usr/local/bin/*

# Azure deploy
RUN mkdir -p /usr/local/azure
COPY scripts/deploy.php /usr/local/azure/deploy.php

# Permissions Drupal
RUN mkdir -p /opt/drupal/sites/default/files \
 && chown -R apache:apache /opt/drupal \
 && chmod -R 755 /opt/drupal

# SSH
RUN echo "root:Docker!" | chpasswd
COPY ./config/sshd_config /etc/ssh/sshd_config

EXPOSE 80 2222

# Azure CLI Alpine install
RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev

RUN pip3 install --no-cache-dir azure-cli --break-system-packages

# MySQL SSL
ENV DB_SSL=/usr/local/share/ca-certificates/azure-mysql.crt.pem

RUN mkdir -p /usr/local/share/ca-certificates \
 && curl -o /usr/local/share/ca-certificates/azure-mysql.crt.pem \
    https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem

# Cron Drupal
RUN echo "21 * * * * apache drush-www cron >> /var/log/cron.log 2>&1" >> /etc/crontabs/root \
 && touch /var/log/cron.log

# Apache run dir
RUN mkdir -p /run/apache2

USER apache

ENTRYPOINT ["docker-drupal-entrypoint"]

CMD ["/usr/sbin/httpd","-D","FOREGROUND"]
