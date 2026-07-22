#!/usr/bin/env bash
set -Eeuo pipefail

target="${1:-/tmp/cetech-ci.env}"

secret() {
  openssl rand -hex 32
}

cat > "${target}" <<EOF
COMPOSE_PROJECT_NAME=cetech-ci
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

MARIADB_ROOT_PASSWORD=$(secret)

CORPORATE_DB_NAME=cetech_corporate
CORPORATE_DB_USER=wp_corporate
CORPORATE_DB_PASSWORD=$(secret)

STORE_DB_NAME=cetech_store_gh
STORE_DB_USER=wp_store_gh
STORE_DB_PASSWORD=$(secret)

BLOG_DB_NAME=cetech_blog_en
BLOG_DB_USER=wp_blog_en
BLOG_DB_PASSWORD=$(secret)

CORPORATE_VALKEY_PASSWORD=$(secret)
STORE_VALKEY_PASSWORD=$(secret)
BLOG_VALKEY_PASSWORD=$(secret)

CORPORATE_AUTH_KEY=$(secret)
CORPORATE_SECURE_AUTH_KEY=$(secret)
CORPORATE_LOGGED_IN_KEY=$(secret)
CORPORATE_NONCE_KEY=$(secret)
CORPORATE_AUTH_SALT=$(secret)
CORPORATE_SECURE_AUTH_SALT=$(secret)
CORPORATE_LOGGED_IN_SALT=$(secret)
CORPORATE_NONCE_SALT=$(secret)

STORE_AUTH_KEY=$(secret)
STORE_SECURE_AUTH_KEY=$(secret)
STORE_LOGGED_IN_KEY=$(secret)
STORE_NONCE_KEY=$(secret)
STORE_AUTH_SALT=$(secret)
STORE_SECURE_AUTH_SALT=$(secret)
STORE_LOGGED_IN_SALT=$(secret)
STORE_NONCE_SALT=$(secret)

BLOG_AUTH_KEY=$(secret)
BLOG_SECURE_AUTH_KEY=$(secret)
BLOG_LOGGED_IN_KEY=$(secret)
BLOG_NONCE_KEY=$(secret)
BLOG_AUTH_SALT=$(secret)
BLOG_SECURE_AUTH_SALT=$(secret)
BLOG_LOGGED_IN_SALT=$(secret)
BLOG_NONCE_SALT=$(secret)

CORPORATE_ADMIN_USER=ci_corporate
CORPORATE_ADMIN_PASSWORD=$(secret)
CORPORATE_ADMIN_EMAIL=ci-corporate@example.invalid

STORE_ADMIN_USER=ci_store
STORE_ADMIN_PASSWORD=$(secret)
STORE_ADMIN_EMAIL=ci-store@example.invalid

BLOG_ADMIN_USER=ci_blog
BLOG_ADMIN_PASSWORD=$(secret)
BLOG_ADMIN_EMAIL=ci-blog@example.invalid
EOF

chmod 0600 "${target}"
echo "${target}"
