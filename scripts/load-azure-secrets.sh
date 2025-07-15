#!/bin/bash

BASEPATH=/opt/drupal
ONCE_FLAG=$BASEPATH/keyvault-loaded
set -ex

# load secrets from keyvault
if [[ "${KEYVAULT}" && ! -f $ONCE_FLAG ]]; then

  # Use managed identity to get an access token
  MI_API_VERSION="2019-08-01"
  ACCESS_TOKEN="$(curl -H "X-IDENTITY-HEADER: $IDENTITY_HEADER" -H 'Metadata: true' "$IDENTITY_ENDPOINT?api-version=$MI_API_VERSION&resource=https%3A%2F%2Fvault.azure.net" | jq -r .access_token)"

  if [ -z "$ACCESS_TOKEN" ]; then
      echo "Failed to obtain access token. Ensure managed identity is configured correctly."
      exit 1
  fi

  # Retrieve the secrets from Key Vault
  SECRET_API_VERSION="2016-10-01"
  SECRETS_API_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "https://$KEYVAULT.vault.azure.net/secrets?api-version=$SECRET_API_VERSION")
  SECRETS_API_VALUE=$(echo $SECRETS_API_RESPONSE | jq -r .value)

  if [ -z "$SECRETS_API_VALUE" ]; then
      echo "Failed to obtain secrets from api."
      echo $SECRETS_API_RESPONSE | jq -r .error.message
      exit 1
  fi
  
  SECRETS=$(echo $SECRETS_API_VALUE | jq -r '.[].id')

  if [ -z "$SECRETS" ]; then
      echo "No secrets found."
      exit 0
  fi

  SECRET_PREFIX="https://$KEYVAULT.vault.azure.net/secrets/"
  for SECRET_ID in $SECRETS
  do 
    # Use the secret value (here we're just echoing it, but you'd typically use it in your application)
    echo "Retrieved secret: $SECRET_ID"
    SECRET_VALUE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$SECRET_ID?api-version=$SECRET_API_VERSION" | jq -r .value)
    ENV_NAME="$(echo ${SECRET_ID#*$SECRET_PREFIX} | tr - _)"
    echo "$ENV_NAME=\"$SECRET_VALUE\"" >> $BASEPATH/.env
  done
fi

# save other env
if [ ! -f $ONCE_FLAG ]; then
  printenv | sed -e 's/=/="/' -e 's/$/"/' | grep -v "_=" >> $BASEPATH/.env
  touch $ONCE_FLAG
fi
