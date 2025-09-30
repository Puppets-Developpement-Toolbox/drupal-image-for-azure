#!/bin/bash

set -e

BASEPATH=/opt/drupal
USER=www-data

temp=$(mktemp)
echo "$BASEPATH/vendor/bin/drush $@" > $temp
chown $USER $temp

if [ "$(whoami)" == $USER ]
then
  export HOME=/opt/drupal
  bash $temp
else
  su $USER -s /bin/bash -c "bash $temp"
fi

rm $temp
