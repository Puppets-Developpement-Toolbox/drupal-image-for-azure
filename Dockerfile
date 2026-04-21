FROM php:8.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    curl \
    jq \
    cron \
    openssh-server \
    mariadb-client \
    parallel \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    ca-certificates \
    gnupg \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        intl \
        gd \
        zip \
        opcache \
        xml \
    && a2enmod rewrite headers expires \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install apcu uploadprogress \
    && docker-php-ext-enable apcu uploadprogress \
    && rm -rf /tmp/pear ~/.pearrc

RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
 && sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf \
 && sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf

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
 && chown -R www-data:www-data /opt/drupal \
 && chmod -R 755 /opt/drupal

WORKDIR /opt/drupal

# SSH
RUN echo "root:Docker!" | chpasswd
COPY ./config/sshd_config /etc/ssh/sshd_config

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache

# MySQL SSL
ENV DB_SSL=/usr/local/share/ca-certificates/azure-mysql.crt.pem

RUN mkdir -p /usr/local/share/ca-certificates \
    && curl -o /usr/local/share/ca-certificates/azure-mysql.crt.pem \
    https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem

RUN touch /var/log/cron.log \
 && echo "21 * * * * www-data drush cron >> /var/log/cron.log 2>&1" >> /etc/crontab

RUN mkdir -p /var/run/sshd \
 && echo "root:Docker!" | chpasswd

EXPOSE 80 2222

USER www-data

ENTRYPOINT ["docker-drupal-entrypoint"]

CMD ["apache2-foreground"]
