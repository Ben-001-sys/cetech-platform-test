<?php
/**
 * Runtime bootstrap helpers for the CETECH WordPress container image.
 *
 * @package CETECH
 */

declare(strict_types=1);

/**
 * Read an environment variable with an optional fallback value.
 *
 * @param string      $name     Environment variable name.
 * @param string|null $fallback Optional fallback value.
 *
 * @return string
 *
 * @throws RuntimeException If the environment variable is missing and no fallback is available.
 */
function cetech_env( string $name, ?string $fallback = null ): string {
	$value = getenv( $name );

	if ( false === $value || '' === $value ) {
		if ( null !== $fallback ) {
			return $fallback;
		}

		throw new RuntimeException(
			sprintf( 'Required environment variable %s is missing.', esc_html( $name ) )
		);
	}

	return $value;
}

/**
 * Read a required environment variable.
 *
 * @param string $name Environment variable name.
 *
 * @return string
 *
 * @throws RuntimeException If the environment variable is missing.
 */
function cetech_env_required( string $name ): string {
	$value = getenv( $name );

	if ( false === $value || '' === $value ) {
		throw new RuntimeException(
			sprintf( 'Required environment variable %s is missing.', esc_html( $name ) )
		);
	}

	return $value;
}

/**
 * Read a boolean environment value.
 *
 * @param string $name     Environment variable name.
 * @param bool   $fallback Default value.
 *
 * @return bool
 */
function cetech_env_bool( string $name, bool $fallback = false ): bool {
	$value = getenv( $name );

	if ( false === $value || '' === $value ) {
		return $fallback;
	}

	return filter_var( $value, FILTER_VALIDATE_BOOL );
}


/*
|--------------------------------------------------------------------------
| Database Configuration
|--------------------------------------------------------------------------
*/

define( 'DB_NAME', cetech_env( 'WORDPRESS_DB_NAME', 'wordpress' ) );
define( 'DB_USER', cetech_env( 'WORDPRESS_DB_USER', 'wordpress' ) );
define( 'DB_PASSWORD', cetech_env( 'WORDPRESS_DB_PASSWORD', 'wordpress' ) );
define( 'DB_HOST', cetech_env( 'WORDPRESS_DB_HOST', 'mariadb:3306' ) );

define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// phpcs:disable WordPress.WP.GlobalVariablesOverride.Prohibited
$table_prefix = cetech_env( 'WORDPRESS_TABLE_PREFIX', 'wp_' );
// phpcs:enable WordPress.WP.GlobalVariablesOverride.Prohibited


/*
|--------------------------------------------------------------------------
| WordPress Authentication Keys & Salts
|--------------------------------------------------------------------------
*/

define( 'AUTH_KEY', cetech_env_required( 'WORDPRESS_AUTH_KEY' ) );
define( 'SECURE_AUTH_KEY', cetech_env_required( 'WORDPRESS_SECURE_AUTH_KEY' ) );
define( 'LOGGED_IN_KEY', cetech_env_required( 'WORDPRESS_LOGGED_IN_KEY' ) );
define( 'NONCE_KEY', cetech_env_required( 'WORDPRESS_NONCE_KEY' ) );

define( 'AUTH_SALT', cetech_env_required( 'WORDPRESS_AUTH_SALT' ) );
define( 'SECURE_AUTH_SALT', cetech_env_required( 'WORDPRESS_SECURE_AUTH_SALT' ) );
define( 'LOGGED_IN_SALT', cetech_env_required( 'WORDPRESS_LOGGED_IN_SALT' ) );
define( 'NONCE_SALT', cetech_env_required( 'WORDPRESS_NONCE_SALT' ) );


/*
|--------------------------------------------------------------------------
| Site Configuration
|--------------------------------------------------------------------------
*/

define( 'WP_HOME', cetech_env( 'WORDPRESS_HOME', 'http://localhost' ) );
define( 'WP_SITEURL', cetech_env( 'WORDPRESS_SITEURL', 'http://localhost' ) );

define( 'COOKIEPATH', cetech_env( 'WORDPRESS_COOKIE_PATH', '/' ) );
define( 'SITECOOKIEPATH', cetech_env( 'WORDPRESS_SITE_COOKIE_PATH', '/' ) );
define( 'COOKIE_DOMAIN', false );


/*
|--------------------------------------------------------------------------
| Environment & Debugging
|--------------------------------------------------------------------------
*/

$environment_type = cetech_env(
	'WORDPRESS_ENVIRONMENT_TYPE',
	'production'
);

define( 'WP_ENVIRONMENT_TYPE', $environment_type );

define( 'WP_DEBUG', cetech_env_bool( 'WORDPRESS_DEBUG', false ) );
define(
	'WP_DEBUG_DISPLAY',
	cetech_env_bool( 'WORDPRESS_DEBUG_DISPLAY', false )
);
define( 'WP_DEBUG_LOG', cetech_env_bool( 'WORDPRESS_DEBUG_LOG', true ) );
define(
	'SCRIPT_DEBUG',
	cetech_env_bool( 'WORDPRESS_SCRIPT_DEBUG', false )
);

define( 'DISABLE_WP_CRON', true );
define( 'WP_CRON_LOCK_TIMEOUT', 60 );

define( 'DISALLOW_FILE_EDIT', true );

$managed_environment = in_array(
	$environment_type,
	array( 'staging', 'production' ),
	true
);

define(
	'DISALLOW_FILE_MODS',
	cetech_env_bool(
		'WORDPRESS_DISALLOW_FILE_MODS',
		$managed_environment
	)
);

define(
	'AUTOMATIC_UPDATER_DISABLED',
	cetech_env_bool(
		'WORDPRESS_DISABLE_AUTO_UPDATES',
		$managed_environment
	)
);


/*
|--------------------------------------------------------------------------
| Memory & Performance
|--------------------------------------------------------------------------
*/

define(
	'WP_MEMORY_LIMIT',
	cetech_env( 'WORDPRESS_MEMORY_LIMIT', '256M' )
);

define(
	'WP_MAX_MEMORY_LIMIT',
	cetech_env( 'WORDPRESS_MAX_MEMORY_LIMIT', '512M' )
);

define( 'WP_POST_REVISIONS', 20 );
define( 'AUTOSAVE_INTERVAL', 120 );
define( 'EMPTY_TRASH_DAYS', 14 );



define(
	'WP_AUTO_UPDATE_CORE',
	cetech_env_bool( 'WORDPRESS_AUTO_UPDATE_CORE', false )
);

define(
	'CORE_UPGRADE_SKIP_NEW_BUNDLED',
	true
);

define(
	'IMAGE_EDIT_OVERWRITE',
	false
);

define(
	'MEDIA_TRASH',
	true
);

define(
	'WP_HTTP_BLOCK_EXTERNAL',
	cetech_env_bool( 'WORDPRESS_BLOCK_EXTERNAL_HTTP', false )
);


/*
|--------------------------------------------------------------------------
| Security & File Management
|--------------------------------------------------------------------------
*/

define(
	'FS_METHOD',
	cetech_env( 'WORDPRESS_FS_METHOD', 'direct' )
);

define( 'FORCE_SSL_ADMIN', true );


/*
|--------------------------------------------------------------------------
| Cache Configuration
|--------------------------------------------------------------------------
*/

define( 'WP_CACHE', true );

define( 'WP_REDIS_CLIENT', 'phpredis' );

define(
	'WP_REDIS_HOST',
	cetech_env( 'WORDPRESS_VALKEY_HOST' )
);

define(
	'WP_REDIS_PORT',
	(int) cetech_env( 'WORDPRESS_VALKEY_PORT', '6379' )
);

define(
	'WP_REDIS_PASSWORD',
	cetech_env_required( 'WORDPRESS_VALKEY_PASSWORD' )
);

define(
	'WP_REDIS_PREFIX',
	cetech_env( 'WORDPRESS_VALKEY_PREFIX', 'cetech:local:wp:' )
);

define(
	'WP_CACHE_KEY_SALT',
	cetech_env( 'WORDPRESS_CACHE_KEY_SALT', 'cetech:local:wp:' )
);


define( 'WP_REDIS_TIMEOUT', 1.0 );
define( 'WP_REDIS_READ_TIMEOUT', 1.0 );
define( 'WP_REDIS_RETRY_INTERVAL', 100 );
define( 'WP_REDIS_MAXTTL', 86400 * 7 );
define( 'WP_REDIS_DISABLED', false );


/*
|--------------------------------------------------------------------------
| HTTP Configuration
|--------------------------------------------------------------------------
*/

if ( cetech_env_bool( 'WORDPRESS_BLOCK_EXTERNAL_HTTP', false ) ) {
	define(
		'WP_ACCESSIBLE_HOSTS',
		cetech_env(
			'WORDPRESS_ACCESSIBLE_HOSTS',
			'api.wordpress.org,downloads.wordpress.org'
		)
	);
}

define( 'WP_HTTP_TIMEOUT', 15 );


/*
|--------------------------------------------------------------------------
| Reverse Proxy / HTTPS Support
|--------------------------------------------------------------------------
*/

if (
	isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) &&
	str_contains(
		strtolower( (string) $_SERVER['HTTP_X_FORWARDED_PROTO'] ),
		'https'
	)
) {
	$_SERVER['HTTPS']       = 'on';
	$_SERVER['SERVER_PORT'] = '443';
}


if ( isset( $_SERVER['HTTP_X_FORWARDED_HOST'] ) ) {
	$forwarded_hosts = explode(
		',',
		(string) $_SERVER['HTTP_X_FORWARDED_HOST']
	);

	$_SERVER['HTTP_HOST'] = trim( $forwarded_hosts[0] );
}


/*
|--------------------------------------------------------------------------
| WordPress Bootstrap
|--------------------------------------------------------------------------
*/

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
