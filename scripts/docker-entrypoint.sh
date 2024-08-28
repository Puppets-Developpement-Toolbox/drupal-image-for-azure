#!/bin/sh
set -e
# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

echo "Starting SSH service ..."
service ssh start

echo "Starting CRON service ..."
service cron start

echo "Loading azure secrets ..."
bash load-secrets.sh

echo "Run deploy tasks ..."
bash deploy.sh

echo "Starting Apache server ..."
apache2-foreground