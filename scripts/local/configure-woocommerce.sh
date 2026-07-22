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

wp_store() {
  "${compose[@]}" exec -T \
    --user www-data \
    store-php \
    wp \
    --path=/var/www/html/gh \
    "$@"
}

wp_store plugin activate woocommerce

wp_store eval '
if ( class_exists( "WC_Install" ) ) {
	WC_Install::create_pages();
}
'

wp_store option update woocommerce_default_country GH
wp_store option update woocommerce_currency GHS
wp_store option update woocommerce_currency_pos left
wp_store option update woocommerce_price_thousand_sep ','
wp_store option update woocommerce_price_decimal_sep '.'
wp_store option update woocommerce_price_num_decimals 2

wp_store option update woocommerce_weight_unit kg
wp_store option update woocommerce_dimension_unit cm

wp_store option update woocommerce_manage_stock yes
wp_store option update woocommerce_hold_stock_minutes 60
wp_store option update woocommerce_notify_low_stock yes
wp_store option update woocommerce_notify_no_stock yes
wp_store option update woocommerce_notify_low_stock_amount 2
wp_store option update woocommerce_notify_no_stock_amount 0

wp_store option update woocommerce_enable_guest_checkout yes
wp_store option update woocommerce_enable_checkout_login_reminder yes
wp_store option update woocommerce_enable_signup_and_login_from_checkout yes
wp_store option update woocommerce_enable_myaccount_registration yes
wp_store option update woocommerce_registration_generate_username yes
wp_store option update woocommerce_registration_generate_password yes

wp_store option update woocommerce_enable_ajax_add_to_cart yes
wp_store option update woocommerce_cart_redirect_after_add no

wp_store option update woocommerce_allow_tracking no
wp_store option update woocommerce_demo_store no

# Local development starts without invented tax rules.
# Import the validated current CETECH production tax configuration separately.
wp_store option update woocommerce_calc_taxes no

wp_store option update woocommerce_enable_reviews yes
wp_store option update woocommerce_review_rating_verification_required yes
wp_store option update woocommerce_review_rating_verification_label yes
wp_store option update woocommerce_enable_review_rating yes

wp_store option update woocommerce_downloads_grant_access_after_payment yes
wp_store option update woocommerce_downloads_require_login no
wp_store option update woocommerce_file_download_method xsendfile

wp_store eval '
$gateways = array(
	"woocommerce_bacs_settings",
	"woocommerce_cheque_settings",
	"woocommerce_cod_settings",
);

foreach ( $gateways as $option_name ) {
	$settings = get_option( $option_name, array() );

	if ( ! is_array( $settings ) ) {
		$settings = array();
	}

	$settings["enabled"] = "no";
	update_option( $option_name, $settings, false );
}
'

wp_store rewrite flush --hard

echo "WooCommerce baseline configuration complete."
