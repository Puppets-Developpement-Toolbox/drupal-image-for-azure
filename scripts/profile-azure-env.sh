
if [ -f /etc/environment ]; then
  set -a
  . /etc/environment
  set +a
fi
