#!/bin/sh
set -e

load-azure-secrets

if [ ! -f /etc/azure-env.sh ]; then
  # Retrieve the environment variables to propagate them in cron, drush-www and the SSH session.
  # `export -p` quotes values safely ($, ", \ ...). Not written to /etc/environment:
  # pam_env (su, cron, sshd) reads that file without unescaping and corrupts the values.
  export -p | grep -vE '^export (PATH|HOME|HOSTNAME|TERM|SHLVL|PWD|OLDPWD|USER|LOGNAME|_)=' > /etc/azure-env.sh
  chown root:www-data /etc/azure-env.sh
  chmod 640 /etc/azure-env.sh
  ln -sf /usr/local/bin/profile-azure-env.sh /etc/profile.d/azure-env.sh
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



  # get last deployed step
  if [ -f $BASEPATH/storage/private/deployed_step ]; then
    DEPLOYED_STEP="$(cat $BASEPATH/storage/private/deployed_step)"
  fi

  if [ "$DEPLOYED_STEP" != "rm-$APP_VERSION" ]
  then
    # let php run the deploy script from http request
    cp /usr/local/azure/deploy.php $BASEPATH/web/deploy.php
  fi

fi

docker-php-entrypoint $@
