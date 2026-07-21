#!/usr/bin/env bash

set -Eeuo pipefail


# ==================================================
# Validate Environment
# ==================================================

: "${WP_ROOT:?WP_ROOT is required}"

if [[ "${WP_ROOT}" != /var/www/html* ]]; then
	echo "Unsafe WP_ROOT: ${WP_ROOT}" >&2
	exit 1
fi


# ==================================================
# Initialize WordPress Core
# ==================================================

mkdir -p "${WP_ROOT}"

if [[ ! -f "${WP_ROOT}/wp-settings.php" ]]; then
	echo "Initializing WordPress ${WORDPRESS_VERSION} in ${WP_ROOT}"

	rsync -a \
		--delete \
		--exclude='wp-content/' \
		/usr/src/wordpress/ \
		"${WP_ROOT}/"
fi


# ==================================================
# Install WordPress Configuration
# ==================================================

install \
	-o www-data \
	-g www-data \
	-m 0640 \
	/opt/cetech/wp-config.php \
	"${WP_ROOT}/wp-config.php"


# ==================================================
# Create WordPress Directory Structure
# ==================================================

mkdir -p \
	"${WP_ROOT}/wp-content" \
	"${WP_ROOT}/wp-content/uploads" \
	"${WP_ROOT}/wp-content/cache" \
	"${WP_ROOT}/wp-content/upgrade" \
	"${WP_ROOT}/wp-content/mu-plugins" \
	"${WP_ROOT}/wp-content/plugins" \
	"${WP_ROOT}/wp-content/themes"


# ==================================================
# Copy Custom WordPress Content
# ==================================================

if [[ -d /opt/cetech/wp-content ]]; then
	rsync -a \
		--ignore-existing \
		/opt/cetech/wp-content/ \
		"${WP_ROOT}/wp-content/"
fi


# ==================================================
# Install Public Plugins
# ==================================================

if [[ -x /usr/local/bin/install-public-plugins ]]; then
	/usr/local/bin/install-public-plugins \
		"${CETECH_SITE_ID:-${APP_SLUG:-corporate}}" \
		"${INSTALL_DEV_TOOLS:-0}"
fi


# ==================================================
# Set WordPress Permissions
# ==================================================

chown -R www-data:www-data \
	"${WP_ROOT}/wp-content/uploads" \
	"${WP_ROOT}/wp-content/cache" \
	"${WP_ROOT}/wp-content/upgrade"


find "${WP_ROOT}/wp-content/uploads" \
	-type d \
	-exec chmod 0755 {} +

find "${WP_ROOT}/wp-content/uploads" \
	-type f \
	-exec chmod 0644 {} +


# ==================================================
# Start PHP-FPM / Container Process
# ==================================================

if [[ "${1:-}" == "php-fpm" ]]; then
	exec "$@"
fi

exec "$@"