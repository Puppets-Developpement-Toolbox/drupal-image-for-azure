#!/bin/bash

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/keyvault-loaded

if [ "${AZURE_ID}" ]; then 
  az login --identity --username $AZURE_ID
fi

# load secrets from keyvault
if [[ "${KEYVAULT}" && ! -f $ONCE_FLAG ]]; then

  secrets="$(az keyvault secret list \
    --vault-name $KEYVAULT \
    --query=[].name \
    -o tsv | xargs)"

  for secret in $secrets
  do
    value="$(az keyvault secret show \
      --vault-name $KEYVAULT \
      --name="$secret" \
      --query=value | xargs )"
    env_name="$(echo secret | tr - _)"
    echo "$env_name=$value" >> $BASEPATH/.env
  done

  touch $ONCE_FLAG
fi