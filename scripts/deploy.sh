#!/bin/sh

set -e
set -x

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/deploy-runned
USER=www-data

if [ ! -f $BASEPATH/vendor/bin/drush ]; then
  echo "drush isn't installed"
  exit 0
fi

if [ ! -f $ONCE_FLAG ]; then

  PRIVATE_PATH=$(drush-www ev 'print_r\(Drupal\\Core\\Site\\Settings::get\(\"file_private_path\"\)\);')
  drush-www sql:dump --gzip --result-file=$PRIVATE_PATH/premep.sql --structure-tables-list=cache,cache_*
  drush-www maint:set 1
  drush-www cache:rebuild
  drush-www updatedb
  drush-www config:import -y
  drush-www locale:update
  drush-www maint:set 0
  drush-www cache:rebuild

  touch $ONCE_FLAG
fi
