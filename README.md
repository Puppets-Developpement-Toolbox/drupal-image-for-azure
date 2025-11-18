Azure base docker image for Drupal
=================================

This repository contains a Dockerfile for building a Drupal image optimized for deployment on Microsoft Azure. The image is based on the official Drupal's PHP-Apache image and includes necessary extensions and configurations for running Drupal efficiently.

## Features
- secure apache for production
- enable upload progress php's extension
- load secrets from keyvault in environment on entrypoint
- preconfigure and enable ssh service
- install and start cron service
- add deploy script (maintenance, dump, updb, cr, cim and rollback)
- contains azure pipeline template


## Environment variables

Required env :
- **APP_VERSION** (required): The version of the Drupal application to be deployed. Used to flag deployement process and run it once per version
- **KEYVAULT** : if set, the name of the Azure Key Vault to fetch secrets from and add them to environment variables
- **MANAGED_IDENTITY_CLIENT_ID** : if set, the client id of the user assigned managed identity to use for fetching secrets from Key Vault

Setted env :
- **DB_SSL**: this variable contains the absolute path to the ssl certificate for database connection

## Deploy pipeline

// to complete
