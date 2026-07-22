#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
env_file="${repo_root}/environments/local/.env"
compose_file="${repo_root}/compose.local.yml"

set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

compose=(
  docker compose
  --env-file "${env_file}"
  -f "${compose_file}"
)

wait_for_wp_files() {
  local service="$1"
  local path="$2"

  for _ in $(seq 1 60); do
    if "${compose[@]}" exec -T "${service}" \
      test -f "${path}/wp-settings.php"; then
      return 0
    fi

    sleep 2
  done

  echo "WordPress files not ready for ${service}" >&2
  return 1
}

install_site() {
  local service="$1"
  local path="$2"
  local url="$3"
  local title="$4"
  local admin_user="$5"
  local admin_password="$6"
  local admin_email="$7"

  wait_for_wp_files "${service}" "${path}"

  if "${compose[@]}" exec -T \
      --user www-data \
      "${service}" \
      wp core is-installed \
      --path="${path}" \
      --skip-plugins \
      --skip-themes; then
    echo "${title} already installed."
    return 0
  fi

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp core install \
    --path="${path}" \
    --url="${url}" \
    --title="${title}" \
    --admin_user="${admin_user}" \
    --admin_password="${admin_password}" \
    --admin_email="${admin_email}" \
    --skip-email

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp option update blog_public 0 \
    --path="${path}"

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp rewrite structure '/%postname%/' \
    --hard \
    --path="${path}"

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp rewrite flush \
    --hard \
    --path="${path}"

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp core verify-checksums \
    --path="${path}"
}

install_site \
  corporate-php \
  /var/www/html \
  https://cetech.test \
  "CETECH Corporate" \
  "${CORPORATE_ADMIN_USER}" \
  "${CORPORATE_ADMIN_PASSWORD}" \
  "${CORPORATE_ADMIN_EMAIL}"

install_site \
  store-php \
  /var/www/html/gh \
  https://cetech.test/gh \
  "CETECH Ghana Store" \
  "${STORE_ADMIN_USER}" \
  "${STORE_ADMIN_PASSWORD}" \
  "${STORE_ADMIN_EMAIL}"

install_site \
  blog-php \
  /var/www/html/en \
  https://cetech.test/en \
  "CETECH English Blog" \
  "${BLOG_ADMIN_USER}" \
  "${BLOG_ADMIN_PASSWORD}" \
  "${BLOG_ADMIN_EMAIL}"

echo "All three local WordPress installations are ready."
