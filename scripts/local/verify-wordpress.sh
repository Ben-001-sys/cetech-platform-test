#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
env_file="${repo_root}/environments/local/.env"
compose_file="${repo_root}/compose.local.yml"
ca="${repo_root}/environments/local/certs/cetech-local-ca.crt"

compose=(
  docker compose
  --env-file "${env_file}"
  -f "${compose_file}"
)

verify_wp() {
  local service="$1"
  local path="$2"
  local expected_home="$3"

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp core verify-checksums \
    --path="${path}"

  actual_home="$(
    "${compose[@]}" exec -T \
      --user www-data \
      "${service}" \
      wp option get home \
      --path="${path}"
  )"

  if [[ "${actual_home}" != "${expected_home}" ]]; then
    echo "Unexpected home URL: ${actual_home}" >&2
    return 1
  fi

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp redis status \
    --path="${path}" \
    | grep -q 'Connected'
}

verify_wp \
  corporate-php \
  /var/www/html \
  https://cetech.test

verify_wp \
  store-php \
  /var/www/html/gh \
  https://cetech.test/gh

verify_wp \
  blog-php \
  /var/www/html/en \
  https://cetech.test/en

"${compose[@]}" exec -T \
  --user www-data \
  store-php \
  wp plugin is-active woocommerce \
  --path=/var/www/html/gh

"${compose[@]}" exec -T \
  --user www-data \
  store-php \
  wp wc hpos status \
  --path=/var/www/html/gh

for path in \
  /wp-json/ \
  /gh/wp-json/ \
  /en/wp-json/ \
  /wp-json/cetech/v1/health \
  /gh/wp-json/cetech/v1/health \
  /en/wp-json/cetech/v1/health
do
  status="$(
    curl \
      --cacert "${ca}" \
      --silent \
      --show-error \
      --output /dev/null \
      --write-out '%{http_code}' \
      "https://cetech.test${path}"
  )"

  if [[ "${status}" != "200" ]]; then
    echo "${path} returned ${status}" >&2
    exit 1
  fi
done

echo "WordPress and WooCommerce verification passed."