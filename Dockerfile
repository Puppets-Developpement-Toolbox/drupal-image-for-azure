FROM drupal:10-php8.3-apache-bookworm

COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-drupal-entrypoint
COPY scripts/load-azure-secrets.sh /usr/local/bin/
COPY scripts/deploy.sh /usr/local/bin/drupal-deploy

# Start and enable SSH
RUN apt-get update \
    && apt-get install -y --no-install-recommends cron \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd \
    && chmod u+x /usr/local/bin/docker-drupal-entrypoint \
    && chmod u+x /usr/local/bin/load-azure-secrets \
    && chmod u+x /usr/local/bin/drupal-deploy
    
COPY ./config/sshd_config /etc/ssh/

EXPOSE 80 2222

RUN curl https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem > DigiCertGlobalRootCA.crt.pem

RUN echo "21 * * * * www-data php /opt/drupal/vendor/bin/drush cron  >> /var/log/cron.log 2>&1" > /etc/cron.d/drupal


ENTRYPOINT [ "docker-drupal-entrypoint" ] 