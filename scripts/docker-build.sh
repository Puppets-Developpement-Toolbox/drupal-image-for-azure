#! /bin/bash

APP_VERSION=$(git rev-parse HEAD)
docker build -t drupal-azure-base:$APP_VERSION .
