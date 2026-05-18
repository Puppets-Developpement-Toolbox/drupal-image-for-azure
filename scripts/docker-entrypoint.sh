#!/bin/sh
set -e

load-azure-secrets

if [ ! -f /etc/profile.d/azure-env.sh ]; then
  # Retrieve the environment variables to propagate them in cron and the SSH session.
  printenv | \
    grep -vE '^(PATH|HOME|HOSTNAME|TERM|SHLVL|PWD|_)=' | \
    sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' \
    >> /etc/environment
  ln -s /usr/local/bin/profile-azure-env.sh /etc/profile.d/azure-env.sh
fi



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

    if [ -n "$HTTP_ACCESS_PAIEMENT" ]; then
        # add rule in htaccess with paiement method for test
        HTACCESS="$BASEPATH/web/.htaccess"
        cat <<'EOF' >> "$HTACCESS"
# BEGIN AUTH BASIC
AuthUserFile /opt/drupal/.htpasswd
AuthName "Accès reservé"
AuthType Basic
SetEnvIf Request_URI "^/deploy\.php" deploy
SetEnvIf Request_URI "^/fr/payment/notify/payzen" payzen_ipn
SetEnvIf Request_URI "^/en/payment/notify/payzen" payzen_ipn
SetEnvIf Remote_Addr "^194\.50\.38\." payzen_ip

Require valid-user
Require env deploy
Require env payzen_ipn payzen_ip
# END AUTH BASIC
EOF
    else
        # add rule in htaccess simple
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
  fi



  # get last deployed version
  if [ -f $BASEPATH/storage/private/deployed_version ]; then
    DEPLOYED_VERSION="$(cat $BASEPATH/storage/private/deployed_version)"
  fi

  if [ "$DEPLOYED_VERSION" != "rm-$APP_VERSION" ]
  then
    # let php run the deploy script from http request
    cp /usr/local/azure/deploy.php $BASEPATH/web/deploy.php
  fi

fi

docker-php-entrypoint $@
