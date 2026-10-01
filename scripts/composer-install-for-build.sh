#! /bin/sh
set -e

# Azure DevOps leaves "$(GITHUB_TOKEN)" as a literal string when the variable is not defined
case "$GITHUB_TOKEN" in
  ""|'$(GITHUB_TOKEN)')
    echo "##vso[task.logissue type=error]GITHUB_TOKEN variable is not defined in the pipeline (required for composer private repos)." >&2
    exit 1
    ;;
esac

HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user) || HTTP_CODE=000

if [ "$HTTP_CODE" != "200" ]; then
  echo "##vso[task.logissue type=error]GITHUB_TOKEN is invalid or expired (GitHub API returned HTTP $HTTP_CODE)." >&2
  exit 1
fi

BASE_IMAGE="ghcr.io/puppets-developpement-toolbox/drupal-azure-base:deploy-multistep-drupal11"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --entrypoint composer \
  -e HOME=/tmp \
  -v "$PWD:/build" -w /build \
  -e COMPOSER_AUTH="{\"github-oauth\":{\"github.com\":\"$GITHUB_TOKEN\"}}" \
  "$BASE_IMAGE" \
  install --no-dev -o --no-progress --prefer-dist
