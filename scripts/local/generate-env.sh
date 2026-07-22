#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
target="${repo_root}/environments/local/.env"

if [[ -e "${target}" ]]; then
    echo "Refusing to overwrite ${target}" >&2
    echo "Move or delete it deliberately before regenerating." >&2
    exit 1
fi

random_secret() {
    openssl rand -base64 48 | tr -d '\n'
}

wordpress_salt() {
    openssl rand -base64 64 | tr -d '\n'
}

cat > "${target}" <<EOF
COMPOSE_PROJECT_NAME=cetech
CETECH_ENV=local

CETECH_PUBLIC_HOST=cetech.test
CETECH_PUBLIC_SCHEME=https

TRAEFIK_VERSION=3.7.1
NGINX_VERSION=1.30.4
MARIADB_VERSION=11.8.8
VALKEY_VERSION=9.1.0-alpine3.23
MAILPIT_VERSION=v1.30.4

WORDPRESS_VERSION=7.0.2

PHP_IMAGE=php:8.4.22-fpm-bookworm@sha256:66cf4b823e8dcde762ffa705b8589d592d709e0705ce6fdcd832d9a7ea4ed0f3

WP_CLI_IMAGE=wordpress:cli-2.12.0-php8.4

PHPREDIS_VERSION=6.3.0


#######################################
# MariaDB
#######################################

MARIADB_ROOT_PASSWORD=$(random_secret)


#######################################
# Corporate WordPress
#######################################

CORPORATE_DB_NAME=cetech_corporate
CORPORATE_DB_USER=wp_corporate
CORPORATE_DB_PASSWORD=$(random_secret)

CORPORATE_VALKEY_PASSWORD=$(random_secret)


CORPORATE_AUTH_KEY=$(wordpress_salt)
CORPORATE_SECURE_AUTH_KEY=$(wordpress_salt)
CORPORATE_LOGGED_IN_KEY=$(wordpress_salt)
CORPORATE_NONCE_KEY=$(wordpress_salt)

CORPORATE_AUTH_SALT=$(wordpress_salt)
CORPORATE_SECURE_AUTH_SALT=$(wordpress_salt)
CORPORATE_LOGGED_IN_SALT=$(wordpress_salt)
CORPORATE_NONCE_SALT=$(wordpress_salt)


#######################################
# Store WordPress
#######################################

STORE_DB_NAME=cetech_store_gh
STORE_DB_USER=wp_store_gh
STORE_DB_PASSWORD=$(random_secret)

STORE_VALKEY_PASSWORD=$(random_secret)


STORE_AUTH_KEY=$(wordpress_salt)
STORE_SECURE_AUTH_KEY=$(wordpress_salt)
STORE_LOGGED_IN_KEY=$(wordpress_salt)
STORE_NONCE_KEY=$(wordpress_salt)

STORE_AUTH_SALT=$(wordpress_salt)
STORE_SECURE_AUTH_SALT=$(wordpress_salt)
STORE_LOGGED_IN_SALT=$(wordpress_salt)
STORE_NONCE_SALT=$(wordpress_salt)


#######################################
# Blog WordPress
#######################################

BLOG_DB_NAME=cetech_blog_en
BLOG_DB_USER=wp_blog_en
BLOG_DB_PASSWORD=$(random_secret)

BLOG_VALKEY_PASSWORD=$(random_secret)


BLOG_AUTH_KEY=$(wordpress_salt)
BLOG_SECURE_AUTH_KEY=$(wordpress_salt)
BLOG_LOGGED_IN_KEY=$(wordpress_salt)
BLOG_NONCE_KEY=$(wordpress_salt)

BLOG_AUTH_SALT=$(wordpress_salt)
BLOG_SECURE_AUTH_SALT=$(wordpress_salt)
BLOG_LOGGED_IN_SALT=$(wordpress_salt)
BLOG_NONCE_SALT=$(wordpress_salt)


#######################################
# Admin Users
#######################################

CORPORATE_ADMIN_USER=cetech_corporate_admin
CORPORATE_ADMIN_PASSWORD=$(random_secret)
CORPORATE_ADMIN_EMAIL=corporate-admin@example.test


STORE_ADMIN_USER=cetech_store_admin
STORE_ADMIN_PASSWORD=$(random_secret)
STORE_ADMIN_EMAIL=store-admin@example.test


BLOG_ADMIN_USER=cetech_blog_admin
BLOG_ADMIN_PASSWORD=$(random_secret)
BLOG_ADMIN_EMAIL=blog-admin@example.test

EOF


chmod 0600 "${target}"


echo "Created ${target}"

echo "Permissions:"
stat -c '%A %a %n' "${target}"