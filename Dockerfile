# Digest pinned so Dependabot opens a PR each time the upstream tag is rebuilt (PHP/Debian/Drupal patches)
FROM drupal:10-php8.3-apache-bookworm@sha256:5315b70f0abacf3c4a80f1b3acbb14e2a762e3b720679600cba8064b0899bf69

# rm drupal
RUN rm -rf /opt/drupal && mkdir /opt/drupal
WORKDIR /opt/drupal

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
COPY scripts/deploy-rollback.sh /usr/local/bin/drupal-deploy-rollback
COPY scripts/drush-www.sh /usr/local/bin/drush-www
COPY scripts/profile-azure-env.sh /usr/local/bin/profile-azure-env.sh
RUN chmod ugoa+x /usr/local/bin/docker-drupal-entrypoint \
    /usr/local/bin/load-azure-secrets \
    /usr/local/bin/drupal-deploy \
    /usr/local/bin/drush-www \
    /usr/local/bin/drupal-deploy-rollback

RUN mkdir /usr/local/azure
COPY scripts/deploy.php /usr/local/azure/deploy.php

# Start and enable SSH
RUN apt-get update
RUN apt-get install -y --no-install-recommends jq \
    cron dialog openssh-server git mariadb-client parallel
RUN echo "root:Docker!" | chpasswd
COPY ./config/sshd_config /etc/ssh/
EXPOSE 80 2222

# install az cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# prepare mysql ssl support
ENV DB_SSL=/usr/local/share/ca-certificates/azure-mysql.crt.pem
# Each download must succeed (-f) over verified HTTPS and be a valid certificate (openssl), else the build fails.
RUN set -e; \
    { curl -fsS https://cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem | openssl x509 -outform PEM; \
      curl -fsS https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem | openssl x509 -outform PEM; \
      curl -fsS "https://www.microsoft.com/pkiops/certs/Microsoft%20RSA%20Root%20Certificate%20Authority%202017.crt" | openssl x509 -inform DER -outform PEM; \
    } > "$DB_SSL"; \
    test "$(grep -c 'BEGIN CERTIFICATE' "$DB_SSL")" -eq 3

# schedule drupal cron
RUN echo "21 * * * * root drush-www cron  >> /var/log/cron.log 2>&1" >> /etc/crontab
RUN touch /var/log/cron.log

RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["docker-drupal-entrypoint"]
CMD ["apache2-foreground"]
