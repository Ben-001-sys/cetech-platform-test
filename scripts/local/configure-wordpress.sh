#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
env_file="${repo_root}/environments/local/.env"
compose_file="${repo_root}/compose.local.yml"

compose=(
  docker compose
  --env-file "${env_file}"
  -f "${compose_file}"
)

wp() {
  local service="$1"
  local path="$2"
  shift 2

  "${compose[@]}" exec -T \
    --user www-data \
    "${service}" \
    wp \
    --path="${path}" \
    "$@"
}

configure_site() {
  local service="$1"
  local path="$2"
  local comments="$3"

  wp "${service}" "${path}" \
    option update timezone_string Africa/Accra

  wp "${service}" "${path}" \
    option update date_format 'F j, Y'

  wp "${service}" "${path}" \
    option update time_format 'g:i a'

  wp "${service}" "${path}" \
    option update start_of_week 1

  wp "${service}" "${path}" \
    option update blog_public 0

  wp "${service}" "${path}" \
    option update default_ping_status closed

  wp "${service}" "${path}" \
    option update default_pingback_flag 0

  wp "${service}" "${path}" \
    option update default_comment_status "${comments}"

  wp "${service}" "${path}" \
    option update close_comments_for_old_posts 1

  wp "${service}" "${path}" \
    option update close_comments_days_old 30

  wp "${service}" "${path}" \
    option update comment_moderation 1

  wp "${service}" "${path}" \
    option update comment_registration 0

  wp "${service}" "${path}" \
    rewrite structure '/%postname%/' \
    --hard

  wp "${service}" "${path}" \
    rewrite flush \
    --hard

  wp "${service}" "${path}" \
    plugin activate redis-cache

  wp "${service}" "${path}" \
    redis enable

  wp "${service}" "${path}" \
    plugin activate query-monitor

  wp "${service}" "${path}" \
    core verify-checksums
}

configure_site \
  corporate-php \
  /var/www/html \
  closed

configure_site \
  store-php \
  /var/www/html/gh \
  closed

configure_site \
  blog-php \
  /var/www/html/en \
  open

echo "General WordPress configuration complete."
