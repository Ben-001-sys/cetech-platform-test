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
#
# The bind-mounted WordPress content tree is already present in local
# development. Skip the runtime rsync unless the destination tree is
# still empty so store-specific uploads/plugins/themes don't cause a
# slow or repeated startup gate before PHP-FPM is ready.
#
# ==================================================

if [[ -d /opt/cetech/wp-content ]]; then
	if ! find "${WP_ROOT}/wp-content" -mindepth 1 -print -quit | grep -q .; then
		rsync -a \
			--ignore-existing \
			/opt/cetech/wp-content/ \
			"${WP_ROOT}/wp-content/"
	fi
fi


# ==================================================
# Install Public Plugins
# ==================================================
#
# Public plugin installation is performed during image build so the
# runtime container can start without re-issuing network-dependent
# WP-CLI installs on every compose restart. Re-running that step here
# can keep PHP-FPM from becoming ready and cause the Compose health
# gate to fail unexpectedly.
#
# ==================================================


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