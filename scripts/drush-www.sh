#!/bin/bash

BASEPATH=/opt/drupal
USER=www-data


su -l $USER -s /bin/bash -c "php $BASEPATH/vendor/bin/drush $@"
