#!/usr/bin/env bash
set -Eeuo pipefail

app_slug="${1:?Application slug is required}"
install_dev_tools="${2:-0}"

wordpress_path="${WP_ROOT:-/var/www/html}"
dependency_root="/opt/cetech/dependencies"
wp_cli_cache_dir="${WP_CLI_CACHE_DIR:-/tmp/.wp-cli-cache}"

export HOME="${HOME:-/tmp}"
export WP_CLI_CACHE_DIR="${wp_cli_cache_dir}"
export WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
export WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wordpress}"
export WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
export WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"
export WORDPRESS_TABLE_PREFIX="${WORDPRESS_TABLE_PREFIX:-wp_}"
export WORDPRESS_AUTH_KEY="${WORDPRESS_AUTH_KEY:-dev-auth-key}"
export WORDPRESS_SECURE_AUTH_KEY="${WORDPRESS_SECURE_AUTH_KEY:-dev-secure-auth-key}"
export WORDPRESS_LOGGED_IN_KEY="${WORDPRESS_LOGGED_IN_KEY:-dev-logged-in-key}"
export WORDPRESS_NONCE_KEY="${WORDPRESS_NONCE_KEY:-dev-nonce-key}"
export WORDPRESS_AUTH_SALT="${WORDPRESS_AUTH_SALT:-dev-auth-salt}"
export WORDPRESS_SECURE_AUTH_SALT="${WORDPRESS_SECURE_AUTH_SALT:-dev-secure-auth-salt}"
export WORDPRESS_LOGGED_IN_SALT="${WORDPRESS_LOGGED_IN_SALT:-dev-logged-in-salt}"
export WORDPRESS_NONCE_SALT="${WORDPRESS_NONCE_SALT:-dev-nonce-salt}"
export WORDPRESS_HOME="${WORDPRESS_HOME:-http://localhost}"
export WORDPRESS_SITEURL="${WORDPRESS_SITEURL:-http://localhost}"
export WORDPRESS_COOKIE_PATH="${WORDPRESS_COOKIE_PATH:-/}"
export WORDPRESS_SITE_COOKIE_PATH="${WORDPRESS_SITE_COOKIE_PATH:-/}"
export WORDPRESS_ENVIRONMENT_TYPE="${WORDPRESS_ENVIRONMENT_TYPE:-local}"
export WORDPRESS_DEBUG="${WORDPRESS_DEBUG:-false}"
export WORDPRESS_DEBUG_DISPLAY="${WORDPRESS_DEBUG_DISPLAY:-false}"
export WORDPRESS_DEBUG_LOG="${WORDPRESS_DEBUG_LOG:-true}"
export WORDPRESS_SCRIPT_DEBUG="${WORDPRESS_SCRIPT_DEBUG:-false}"
export WORDPRESS_DISABLE_AUTO_UPDATES="${WORDPRESS_DISABLE_AUTO_UPDATES:-true}"
export WORDPRESS_MEMORY_LIMIT="${WORDPRESS_MEMORY_LIMIT:-256M}"
export WORDPRESS_MAX_MEMORY_LIMIT="${WORDPRESS_MAX_MEMORY_LIMIT:-512M}"
export WORDPRESS_VALKEY_HOST="${WORDPRESS_VALKEY_HOST:-valkey}"
export WORDPRESS_VALKEY_PORT="${WORDPRESS_VALKEY_PORT:-6379}"
export WORDPRESS_VALKEY_PASSWORD="${WORDPRESS_VALKEY_PASSWORD:-valkey}"
export WORDPRESS_VALKEY_PREFIX="${WORDPRESS_VALKEY_PREFIX:-cetech:local:wp:}"
export WORDPRESS_CACHE_KEY_SALT="${WORDPRESS_CACHE_KEY_SALT:-cetech:local:wp:}"

install_manifest() {
  local manifest="$1"

  if [[ ! -f "${manifest}" ]]; then
    return 0
  fi

  while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
    local line="${raw_line#\#*}"
    line="$(printf '%s' "${line}" | xargs)"

    if [[ -z "${line}" ]]; then
      continue
    fi

    IFS='|' read -r slug version <<< "${line}"
    slug="$(printf '%s' "${slug:-}" | xargs)"
    version="$(printf '%s' "${version:-}" | xargs)"

    if [[ -z "${slug}" ]]; then
      continue
    fi

    if [[ -z "${version}" ]]; then
      echo "Missing version for ${slug} in ${manifest}" >&2
      continue
    fi

    if wp plugin is-installed "${slug}" --path="${wordpress_path}" >/dev/null 2>&1; then
      echo "Plugin ${slug} already installed"
      continue
    fi

    echo "Installing ${slug} ${version}"

    if ! wp plugin install "${slug}" \
      --version="${version}" \
      --force \
      --path="${wordpress_path}" \
      --skip-plugins \
      --skip-themes; then
      echo "Warning: failed to install ${slug} ${version}; continuing" >&2
      continue
    fi
  done < "${manifest}"
}

mkdir -p \
  "${wordpress_path}/wp-content/plugins" \
  /opt/cetech/wp-content/plugins \
  "${wp_cli_cache_dir}"

install_manifest \
  "${dependency_root}/common-public.lock"

install_manifest \
  "${dependency_root}/${app_slug}-public.lock"

if [[ "${install_dev_tools}" == "1" ]]; then
  install_manifest \
    "${dependency_root}/local-development.lock"
fi

rsync -a \
  "${wordpress_path}/wp-content/plugins/" \
  /opt/cetech/wp-content/plugins/

find /opt/cetech/wp-content/plugins \
  -type d \
  -exec chmod 0755 {} +

find /opt/cetech/wp-content/plugins \
  -type f \
  -exec chmod 0644 {} +

chown -R www-data:www-data \
  /opt/cetech/wp-content/plugins
