#!/bin/sh

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/deploy-runned
USER=www-data

if [ ! -f $BASEPATH/vendor/bin/drush ]; then
  echo "drush isn't installed"
  exit 0
fi

if [ ! -f $ONCE_FLAG ]; then

  drush-www maint:set 1
  drush-www cache:rebuild
  drush-www updatedb
  drush-www config:import -y
  drush-www locale:update
  drush-www maint:set 0
  drush-www cache:rebuild

  touch $ONCE_FLAG
fi
