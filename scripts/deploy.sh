#!/bin/sh

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/deploy-runned

if [ ! -f $BASEPATH/vendor/bin/drush ]; then
  echo "drush isn't installed"
  exit 0
fi

if [ ! -f $ONCE_FLAG ]; then

  BASEPATH=/opt/drupal
  USER=www-data

  su -l $USER -s /bin/bash -c "php $BASEPATH/vendor/bin/drush config:import -y"
  su -l $USER -s /bin/bash -c "php $BASEPATH/vendor/bin/drush locale:update"
  su -l $USER -s /bin/bash -c "php $BASEPATH/vendor/bin/drush cache:rebuild"
  su -l $USER -s /bin/bash -c "php $BASEPATH/vendor/bin/drush maint:set 0"

  touch $ONCE_FLAG
fi