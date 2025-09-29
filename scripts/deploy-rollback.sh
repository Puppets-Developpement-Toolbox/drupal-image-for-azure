#!/bin/sh

set -e

BASEPATH=/opt/drupal

if [ -f $BASEPATH/premep.sql ]; then
    drush-www sql:query --file={$BASEPATH}/premep.sql
fi
