#!/bin/sh

set -e

if [ "$#" -ne 1 ]; then
  echo "Usage: ./deploy.sh <arg>"
  echo "Deployment split from arg"
  exit 1
fi

ACTION=$1

BASEPATH=/opt/drupal

if [ "$ACTION" = "maint1" ]; then
    drush-www maint:set 1
fi
if [ "$ACTION" = "dump" ]; then
    # Pour éviter le timeout de Azure
    drush-www sql:dump --gzip --result-file=$BASEPATH/storage/premep.sql --structure-tables-list=cache,cache_* &
    DRUSH_PID=$!

    # Keepalive pendant que drush tourne évite le timeout
    while kill -0 $DRUSH_PID 2>/dev/null; do
        echo "... dumping"
        sleep 5
    done

    # Récupérer le code de retour de drush
    wait $DRUSH_PID
fi
if [ "$ACTION" = "updb" ]; then
    drush-www updatedb
fi
if [ "$ACTION" = "cim" ]; then
    drush-www config:import -y
fi
if [ "$ACTION" = "localupd" ]; then
    drush-www locale:update &
    DRUSH_PID=$!
    while kill -0 $DRUSH_PID 2>/dev/null; do
        echo "... locale update running"
        sleep 5
    done
    wait $DRUSH_PID
fi
if [ "$ACTION" = "maint0" ]; then
    drush-www maint:set 0
fi
if [ "$ACTION" = "cr" ]; then
    drush-www cache:rebuild
fi

if [ "$ACTION" = "ver" ]; then
    echo $APP_VERSION > $BASEPATH/storage/private/deployed_version
fi

if [ "$ACTION" = "rm" ]; then
    rm $BASEPATH/web/deploy.php
fi

echo "$ACTION-$APP_VERSION" > $BASEPATH/storage/private/deployed_version
