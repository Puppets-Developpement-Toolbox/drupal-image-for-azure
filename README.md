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
- contains rules for .htaccess and htpasswd
- contains condition for deploy a HotFix rapidely with fastDeploy
- contains condition for keep the project in maintenance with keepInMaint


## Environment variables

Required env :
- **APP_VERSION** (required): The version of the Drupal application to be deployed. Used to flag deployement process and run it once per version
- **KEYVAULT** : if set, the name of the Azure Key Vault to fetch secrets from and add them to environment variables
- **MANAGED_IDENTITY_CLIENT_ID** : if set, the client id of the user assigned managed identity to use for fetching secrets from Key Vault
- **HTTP_ACCESS_USER and HTTP_ACCESS_PASS** : if both are defined, authentification rules are added to .htaccess file and .htpasswd is added to the Drupal application

Setted env :
- **DB_SSL**: this variable contains the absolute path to the ssl certificate for database connection

## Deploy pipeline

// to complete

## Test image

 Use scripts docker-build.sh from the project : 
- cd myprojectToAzure 
- ./script/docker-build.sh

 Pulling image azure-pipeline :
- docker pull azure-pipeline

 Instantiate the image in docker : 
- docker run [imageNAME] 

Now You can use the image and test it
