#!/bin/sh

set -e

BASEPATH=/opt/drupal

drush-www maint:set 1
drush-www sql:dump --gzip --result-file=$BASEPATH/premep.sql --structure-tables-list=cache,cache_*
drush-www cache:rebuild
drush-www updatedb
drush-www config:import -y
drush-www locale:update
drush-www maint:set 0
drush-www cache:rebuild

echo $APP_VERSION > $BASEPATH/storage/private/deployed_version

rm $BASEPATH/web/deploy.php
