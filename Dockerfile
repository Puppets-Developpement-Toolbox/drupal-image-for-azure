FROM drupal:10-php8.3-apache-bookworm

# rm drupal
RUN rm -rf /opt/drupal/* && rm -rf /opt/drupal/.*

# secure
RUN sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-enabled/security.conf
RUN sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-enabled/security.conf
RUN echo 'Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"' >> /etc/apache2/conf-enabled/security.conf
RUN a2enmod headers

# install php module + config
RUN pecl install uploadprogress apcu \
    && docker-php-ext-install mysqli \
    && docker-php-ext-enable mysqli uploadprogress apcu
COPY config/php.ini /usr/local/etc/php/conf.d/puppets-php.ini

# add homemade scripts
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-drupal-entrypoint
COPY scripts/load-azure-secrets.sh /usr/local/bin/load-azure-secrets
COPY scripts/deploy.sh /usr/local/bin/drupal-deploy
COPY scripts/drush-www.sh /usr/local/bin/drush-www
RUN chmod u+x /usr/local/bin/docker-drupal-entrypoint \
    /usr/local/bin/load-azure-secrets \
    /usr/local/bin/drupal-deploy \
    /usr/local/bin/drush-www

# Start and enable SSH
RUN apt-get update
RUN apt-get install -y --no-install-recommends jq \
    cron dialog openssh-server git mariadb-client
RUN echo "root:Docker!" | chpasswd
COPY ./config/sshd_config /etc/ssh/
EXPOSE 80 2222

# install az cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# prepare mysql ssl support
ENV DB_SSL=1
RUN curl https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem > DigiCertGlobalRootCA.crt.pem

# schedule drupal cron
RUN echo "21 * * * * root drush-www cron  >> /var/log/cron.log 2>&1" >> /etc/crontab
RUN touch /var/log/cron.log

RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["docker-drupal-entrypoint"]
CMD ["apache2-foreground"]
