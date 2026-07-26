#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${CETECH_IMMUTABLE_RELEASE:-0}" == "1" ]]; then
  : "${WP_ROOT:?WP_ROOT is required}"

  if [[ ! -f "${WP_ROOT}/wp-settings.php" ]]; then
    echo "Immutable WordPress release is missing wp-settings.php" >&2
    exit 1
  fi

  if [[ ! -f "${WP_ROOT}/wp-config.php" ]]; then
    echo "Immutable WordPress release is missing wp-config.php" >&2
    exit 1
  fi

  exec "$@"
fi

: "${WP_ROOT:?WP_ROOT is required}"

if [[ "${WP_ROOT}" != /var/www/html* ]]; then
  echo "Unsafe local WP_ROOT: ${WP_ROOT}" >&2
  exit 1
fi

mkdir -p "${WP_ROOT}"

if [[ ! -f "${WP_ROOT}/wp-settings.php" ]]; then
  echo "Initializing local WordPress in ${WP_ROOT}"

  rsync -a \
    --delete \
    --exclude='wp-content/' \
    /usr/src/wordpress/ \
    "${WP_ROOT}/"
fi

install \
  -o www-data \
  -g www-data \
  -m 0640 \
  /opt/cetech/wp-config.php \
  "${WP_ROOT}/wp-config.php"

mkdir -p \
  "${WP_ROOT}/wp-content" \
  "${WP_ROOT}/wp-content/uploads" \
  "${WP_ROOT}/wp-content/cache" \
  "${WP_ROOT}/wp-content/upgrade" \
  "${WP_ROOT}/wp-content/mu-plugins" \
  "${WP_ROOT}/wp-content/plugins" \
  "${WP_ROOT}/wp-content/themes"

rsync -a \
  --ignore-existing \
  /opt/cetech/wp-content/ \
  "${WP_ROOT}/wp-content/"

chown -R www-data:www-data \
  "${WP_ROOT}/wp-content/uploads" \
  "${WP_ROOT}/wp-content/cache" \
  "${WP_ROOT}/wp-content/upgrade"

exec "$@"
