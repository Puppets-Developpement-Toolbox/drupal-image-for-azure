deploy_call() {
  local action=$1
  local base_url=$2
  local max=5 delay=10 attempt=1

  until curl --no-progress-meter \
    "${base_url}/deploy.php?action=${action}" \
    2>&1 | tee deploy.log \
    && grep -q "DEPLOY OK" deploy.log; do

    [ $attempt -ge $max ] && echo "Échec après ${max} tentatives" && exit 1
    echo "Tentative ${attempt}/${max}, nouvel essai dans ${delay}s..."
    sleep $delay
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}
