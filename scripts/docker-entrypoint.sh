#!/bin/sh
set -e

load-azure-secrets

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# if we start apache then start cron, ssh and launch deploy
if [ "${1#-}" != "$1" ] || [ "${1#apache2-foreground}" != "$1" ]; then

  if [ -z "$APP_VERSION" ]; then
    echo "APP_VERSION is not set"
    exit 1
  fi

  service ssh start
  service cron start

  ##################
  # prepare deploy #
  ##################
  BASEPATH=/opt/drupal

  if [ ! -f $BASEPATH/vendor/bin/drush ]; then
    # drush isn't installed, nothing to do
    echo "drush isn't installed"
    exit 0
  fi

  # get last deployed version
  if [ -f $BASEPATH/storage/private/deployed_version ]; then
    DEPLOYED_VERSION="$(cat $BASEPATH/storage/private/deployed_version)"
  fi

  if [ "$DEPLOYED_VERSION" != "$APP_VERSION" ]
  then
    # if env var exist htpasswd create
    if [ -n "$HTPASSWD" ]; then
      if [ ! -f $BASEPATH/config/.htpasswd ]; then
        touch $BASEPATH/config/.htpasswd
      fi
      echo "$HTPASSWD" >> $BASEPATH/config/.htpasswd

      # add rule in htpaccess
      HTACCESS="$BASEPATH/web/.htaccess"
      cat <<'EOF' >> "$HTACCESS"

      # BEGIN AUTH BASIC
      AuthUserFile /opt/drupal/config/.htpasswd
      AuthName "Accès reservé"
      AuthType Basic
      Require valid-user
      # END AUTH BASIC
      EOF
    fi
    # let php run the deploy script from http request
    cp /usr/local/azure/deploy.php $BASEPATH/web/deploy.php
  fi

fi

docker-php-entrypoint $@
