<?php
/**
 * Child theme bootstrap for CETECH store.
 *
 * @package CETECH
 */

declare(strict_types=1);

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action(
	'wp_enqueue_scripts',
	static function (): void {
		wp_enqueue_style(
			'cetech-store-child',
			get_stylesheet_uri(),
			array(),
			wp_get_theme()->get( 'Version' )
		);
	}
);
