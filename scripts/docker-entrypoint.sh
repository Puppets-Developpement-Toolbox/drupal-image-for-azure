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


  # if env var exist htpasswd create
  if [ -n "$HTTP_ACCESS_USER" ] && [ -n "$HTTP_ACCESS_PASS" ]; then
    htpasswd -b -c "$BASEPATH/.htpasswd" $HTTP_ACCESS_USER $HTTP_ACCESS_PASS

    # add rule in htpaccess
    HTACCESS="$BASEPATH/web/.htaccess"
    cat <<'EOF' >> "$HTACCESS"
# BEGIN AUTH BASIC
AuthUserFile /opt/drupal/.htpasswd
AuthName "Accès reservé"
AuthType Basic
SetEnvIf Request_URI "^/deploy\.php" deploy
Require valid-user
Require env deploy
# END AUTH BASIC
EOF

  fi



  # get last deployed version
  if [ -f $BASEPATH/storage/private/deployed_version ]; then
    DEPLOYED_VERSION="$(cat $BASEPATH/storage/private/deployed_version)"
  fi

  if [ "$DEPLOYED_VERSION" != "$APP_VERSION" ]
  then
    # let php run the deploy script from http request
    cp /usr/local/azure/deploy.php $BASEPATH/web/deploy.php
  fi

fi

docker-php-entrypoint $@
