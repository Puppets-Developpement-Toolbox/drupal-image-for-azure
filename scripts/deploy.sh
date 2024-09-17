#!/bin/sh

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/deploy-runned
USER=www-data

if [ ! -f $BASEPATH/vendor/bin/drush ]; then
  echo "drush isn't installed"
  exit 0
fi

if [ ! -f $ONCE_FLAG ]; then

  drush-www config:import -y
  drush-www locale:update
  drush-www cache:rebuild
  drush-www maint:set 0

  touch $ONCE_FLAG
fi