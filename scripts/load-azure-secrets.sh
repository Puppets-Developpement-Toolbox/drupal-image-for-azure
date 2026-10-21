#!/bin/bash

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/keyvault-loaded
set -ex

# load secrets from keyvault
if [[ "${KEYVAULT}" && ! -f $ONCE_FLAG ]]; then

  # login to az
  if [ "${MANAGED_IDENTITY_CLIENT_ID}" ]; then
    az login --identity --client-id $MANAGED_IDENTITY_CLIENT_ID
  else
    az login --identity --allow-no-subscriptions
  fi

  # query keyvault to list secret id
  SECRETS=$(az keyvault secret list --vault-name $KEYVAULT -o tsv --query '[].id')

  if [ -z "$SECRETS" ]; then
      echo "No secrets found."
      exit 0
  fi

  for SECRET_ID in $SECRETS
  do
    # Use the secret value (here we're just echoing it, but you'd typically use it in your application)
    echo "Retrieved secret: $SECRET_ID"
    SECRET_VALUE=$(az keyvault secret show  --id $SECRET_ID --query "value" -o tsv | sed -e 's/"/\\"/')
    ENV_NAME=$(az keyvault secret show  --id $SECRET_ID --query "name" -o tsv | tr - _)
    echo "$ENV_NAME=\"$SECRET_VALUE\"" >> $BASEPATH/.env
  done
fi

# save other env
if [ ! -f $ONCE_FLAG ]; then
  # printenv | sed -e 's/=/="/' -e 's/$/"/' | grep -v "_=" >> $BASEPATH/.env
  touch $ONCE_FLAG
fi
