#!/usr/bin/env bash
# Smoke test of the built image, run by publish.yml before any push to the registry.
# Usage: .github/smoke-test.sh <image>
# Local run: docker build -t drupal-azure:smoke . && .github/smoke-test.sh drupal-azure:smoke
set -euo pipefail

IMAGE="${1:?usage: $0 <image>}"
NAME="smoke-$$"
PORT=8080
DOCROOT="$(mktemp -d)"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$DOCROOT"
}
trap cleanup EXIT

fail() { echo "SMOKE FAIL: $*" >&2; exit 1; }

echo "== 1. Custom entrypoint + PHP extensions"
# Goes through docker-drupal-entrypoint (load-azure-secrets, env export) on the non-Apache path.
MODULES="$(docker run --rm "$IMAGE" php -m)"
for ext in mysqli apcu uploadprogress pdo_mysql gd opcache; do
  grep -qix "$ext" <<<"$MODULES" || grep -qix "zend $ext" <<<"$MODULES" || fail "PHP extension '$ext' missing"
done
docker run --rm "$IMAGE" php -v | head -1

echo "== 2. Tools used by deploy scripts and cron"
docker run --rm --entrypoint sh "$IMAGE" -c \
  'for b in az jq git mysql crontab sshd parallel drupal-deploy drupal-deploy-rollback drush-www load-azure-secrets; do
     command -v "$b" >/dev/null || { echo "missing: $b"; exit 1; }
   done' || fail "binary missing"

echo "== 3. Apache serves PHP + hardening headers"
# The image ships without Drupal code: serve a probe file from the Drupal docroot.
mkdir -p "$DOCROOT/web"
echo '<?php echo "SMOKE OK ", PHP_VERSION;' > "$DOCROOT/web/index.php"
chmod -R a+rX "$DOCROOT"
docker run -d --name "$NAME" -p "$PORT:80" \
  -v "$DOCROOT:/opt/drupal:ro" \
  --entrypoint docker-php-entrypoint "$IMAGE" apache2-foreground >/dev/null

for _ in $(seq 1 30); do
  curl -fsS -o /dev/null "http://localhost:$PORT/" 2>/dev/null && break
  sleep 1
done

BODY="$(curl -sS "http://localhost:$PORT/")" || { docker logs "$NAME" >&2; fail "Apache not reachable"; }
HEADERS="$(curl -sS -I "http://localhost:$PORT/")"
grep -q "SMOKE OK" <<<"$BODY" || { docker logs "$NAME" >&2; fail "PHP not executed: $BODY"; }
grep -qi '^HTTP/[0-9.]* 200' <<<"$HEADERS" || fail "expected HTTP 200"
grep -qi '^Strict-Transport-Security:' <<<"$HEADERS" || fail "HSTS header missing"
grep -qiE '^Server: Apache\s*$' <<<"$HEADERS" || fail "Server header leaks version: $(grep -i '^Server:' <<<"$HEADERS")"

echo "SMOKE OK: $BODY"
