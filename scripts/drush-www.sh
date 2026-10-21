#!/bin/bash

set -e

BASEPATH=/opt/drupal
USER=www-data

quote() { for i in "${@}"; do echo ${i@Q}; done; }

temp=$(mktemp)
drush_params=$(quote "$@")
echo "#!/bin/bash" > $temp
echo "set -e" >> $temp
echo "$BASEPATH/vendor/bin/drush $(echo $drush_params)" >> $temp
chown $USER $temp

if [ "$(whoami)" == $USER ]
then
  export HOME=/opt/drupal
  bash $temp
else
  su $USER -s /bin/bash -c "bash $temp"
fi

rm $temp
