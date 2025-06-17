#!/bin/bash

set -e

BASEPATH=/opt/drupal
USER=www-data

temp=$(mktemp)
echo "$BASEPATH/vendor/bin/drush $@" > $temp
chown $USER $temp
su $USER -s /bin/bash -c "bash $temp"
rm $temp
