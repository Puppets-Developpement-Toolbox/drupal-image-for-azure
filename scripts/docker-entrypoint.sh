#!/bin/sh
set -e

load-azure-secrets

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# if we start apache then start cron, ssh and launch deploy
if [ "${1#-}" != "$1" ] || [ "${1#apache2-foreground}" != "$1" ]; then
  service ssh start
  service cron start
  drupal-deploy
fi

docker-php-entrypoint $@
