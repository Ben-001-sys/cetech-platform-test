<?php
/**
 * Plugin Name: CETECH Platform Runtime
 * Description: Shared runtime safeguards for CETECH WordPress installations.
 * Version: 1.0.0
 * Author: CETECH
 *
 * @package CETECH
 */

declare(strict_types=1); 

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Read a boolean environment value.
 *
 * @param string $name Environment variable name.
 * @param bool   $fallback Default value.
 *
 * @return bool
 */
function cetech_runtime_env_bool(
	string $name,
	bool $fallback = false
): bool {
	$value = getenv( $name );

	if ( false === $value || '' === $value ) {
		return $fallback;
	}

	return filter_var( $value, FILTER_VALIDATE_BOOL );
}

/**
 * XML-RPC remains disabled unless explicitly required and tested.
 */
add_filter(
	'xmlrpc_enabled',
	static fn (): bool =>
		cetech_runtime_env_bool( 'CETECH_ENABLE_XMLRPC', false )
);

add_filter(
	'wp_headers',
	static function ( array $headers ): array {
		unset( $headers['X-Pingback'] );

		return $headers;
	}
);

/**
 * Remove passive software-version disclosure.
 */
remove_action( 'wp_head', 'wp_generator' );
add_filter( 'the_generator', '__return_empty_string' );

/**
 * Disable pingback methods independently of the XML-RPC general filter.
 */
add_filter(
	'xmlrpc_methods',
	static function ( array $methods ): array {
		unset( $methods['pingback.ping'] );
		unset( $methods['pingback.extensions.getPingbacks'] );

		return $methods;
	}
);

/**
 * Minimal application-readiness endpoint.
 *
 * It confirms that WordPress completed bootstrap and reached its database.
 * It intentionally returns no version, path, credentials or infrastructure data.
 */
add_action(
	'rest_api_init',
	static function (): void {
		register_rest_route(
			'cetech/v1',
			'/health',
			array(
				'methods'             => 'GET',
				'permission_callback' => '__return_true',
				'callback'            => static function (): WP_REST_Response {
					return new WP_REST_Response(
						array(
							'status' => 'ok',
							'site'   => sanitize_key(
								(string) getenv( 'CETECH_SITE_ID' )
							),
						),
						200
					);
				},
			)
		);
	}
);

/**
 * Prevent outbound requests to link-local/cloud metadata addresses.
 */
add_filter(
	'http_request_host_is_external',
	static function (
		bool $external,
		string $host
	): bool {
		$blocked_hosts = array(
			'169.254.169.254',
			'metadata.google.internal',
			'metadata',
			'instance-data',
			'100.100.100.200',
		);

		if ( in_array( strtolower( $host ), $blocked_hosts, true ) ) {
			return false;
		}

		return $external;
	},
	10,
	2
);

/**
 * Display the environment only to administrators.
 */
add_action(
	'admin_bar_menu',
	static function ( WP_Admin_Bar $admin_bar ): void {
		if ( ! current_user_can( 'manage_options' ) ) {
			return;
		}

		$environment = wp_get_environment_type();

		if ( 'production' === $environment ) {
			return;
		}

		$admin_bar->add_node(
			array(
				'id'    => 'cetech-environment',
				'title' => sprintf(
					'CETECH: %s',
					esc_html( strtoupper( $environment ) )
				),
			)
		);
	},
	100
);
