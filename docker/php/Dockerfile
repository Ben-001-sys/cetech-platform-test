# syntax=docker/dockerfile:1.7

ARG PHP_IMAGE
ARG WP_CLI_IMAGE

FROM ${WP_CLI_IMAGE} AS wpcli

FROM ${PHP_IMAGE} AS runtime

ARG WORDPRESS_VERSION
ARG PHPREDIS_VERSION=6.3.0
ARG APP_DIR
ARG APP_SLUG
ARG APP_PREFIX=""
ARG PHP_PROFILE=production

ARG FPM_MAX_CHILDREN=24
ARG FPM_START_SERVERS=6
ARG FPM_MIN_SPARE_SERVERS=4
ARG FPM_MAX_SPARE_SERVERS=10

ENV DEBIAN_FRONTEND=noninteractive \
    WORDPRESS_VERSION=${WORDPRESS_VERSION} \
    WP_CLI_ALLOW_ROOT=1 \
    CETECH_RELEASE_ROOT=/opt/cetech/release \
    PATH="/usr/local/bin:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      default-mysql-client \
      ghostscript \
      git \
      imagemagick \
      less \
      libavif-dev \
      libfcgi-bin \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libmagickwand-dev \
      libonig-dev \
      libpng-dev \
      libwebp-dev \
      libxml2-dev \
      libzip-dev \
      mariadb-client \
      msmtp \
      netcat-openbsd \
      procps \
      rsync \
      unzip \
      zlib1g-dev; \
    docker-php-ext-configure gd \
      --with-freetype \
      --with-jpeg \
      --with-webp \
      --with-avif; \
    docker-php-ext-install -j"$(nproc)" \
      bcmath \
      exif \
      gd \
      intl \
      mysqli \
      opcache \
      pcntl \
      pdo_mysql \
      soap \
      sockets \
      zip; \
    pecl install "redis-${PHPREDIS_VERSION}"; \
    docker-php-ext-enable redis; \
    pecl install imagick; \
    docker-php-ext-enable imagick; \
    rm -rf /var/lib/apt/lists/* /tmp/pear

COPY --from=wpcli /usr/local/bin/wp /usr/local/bin/wp

RUN set -eux; \
    rm -rf /usr/src/wordpress; \
    mkdir -p /usr/src/wordpress; \
    wp core download \
      --version="${WORDPRESS_VERSION}" \
      --path=/usr/src/wordpress \
      --locale=en_US \
      --skip-content \
      --force; \
    wp core verify-checksums \
      --version="${WORDPRESS_VERSION}" \
      --path=/usr/src/wordpress

COPY dependencies/ /opt/cetech/dependencies/
COPY docker/php/install-public-plugins.sh \
  /usr/local/bin/install-public-plugins

RUN set -eux; \
    chmod 0755 /usr/local/bin/install-public-plugins; \
    mkdir -p /opt/cetech/wp-content; \
    /usr/local/bin/install-public-plugins \
      "${APP_SLUG}" \
      "$([ "${PHP_PROFILE}" = "local" ] && echo 1 || echo 0)"

COPY apps/shared/wp-content/ \
  /opt/cetech/wp-content/

COPY ${APP_DIR}/wp-content/ \
  /opt/cetech/wp-content/

RUN set -eux; \
    if [ -f \
      /opt/cetech/wp-content/plugins/redis-cache/includes/object-cache.php \
    ]; then \
      cp \
        /opt/cetech/wp-content/plugins/redis-cache/includes/object-cache.php \
        /opt/cetech/wp-content/object-cache.php; \
    fi

COPY docker/php/wp-config.php \
  /opt/cetech/wp-config.php

COPY docker/php/entrypoint.sh \
  /usr/local/bin/cetech-entrypoint

COPY docker/php/mailpit-sendmail \
  /usr/local/bin/mailpit-sendmail

COPY docker/php/config/ \
  /opt/cetech/php-config/

RUN set -eux; \
    case "${PHP_PROFILE}" in \
      local) \
        cp \
          /opt/cetech/php-config/local/php.ini \
          /usr/local/etc/php/conf.d/10-cetech.ini; \
        cp \
          /opt/cetech/php-config/local/opcache.ini \
          /usr/local/etc/php/conf.d/20-opcache.ini; \
        cp \
          /opt/cetech/php-config/local/www.conf \
          /usr/local/etc/php-fpm.d/zz-cetech.conf; \
        ;; \
      production) \
        cp \
          /opt/cetech/php-config/production/php.ini \
          /usr/local/etc/php/conf.d/10-cetech.ini; \
        cp \
          /opt/cetech/php-config/production/opcache.ini \
          /usr/local/etc/php/conf.d/20-opcache.ini; \
        sed \
          -e "s/__MAX_CHILDREN__/${FPM_MAX_CHILDREN}/g" \
          -e "s/__START_SERVERS__/${FPM_START_SERVERS}/g" \
          -e "s/__MIN_SPARE_SERVERS__/${FPM_MIN_SPARE_SERVERS}/g" \
          -e "s/__MAX_SPARE_SERVERS__/${FPM_MAX_SPARE_SERVERS}/g" \
          /opt/cetech/php-config/production/www.conf.template \
          > /usr/local/etc/php-fpm.d/zz-cetech.conf; \
        ;; \
      *) \
        echo "Unsupported PHP_PROFILE=${PHP_PROFILE}" >&2; \
        exit 1; \
        ;; \
    esac; \
    chmod 0755 \
      /usr/local/bin/cetech-entrypoint \
      /usr/local/bin/mailpit-sendmail

ARG APP_PREFIX

RUN set -eux; \
    release_root="/opt/cetech/release${APP_PREFIX}"; \
    mkdir -p "${release_root}"; \
    rsync -a \
      --delete \
      --exclude='wp-content/' \
      /usr/src/wordpress/ \
      "${release_root}/"; \
    mkdir -p "${release_root}/wp-content"; \
    rsync -a \
      /opt/cetech/wp-content/ \
      "${release_root}/wp-content/"; \
    install \
      -m 0640 \
      /opt/cetech/wp-config.php \
      "${release_root}/wp-config.php"; \
    mkdir -p \
      "${release_root}/wp-content/uploads" \
      "${release_root}/wp-content/cache" \
      "${release_root}/wp-content/upgrade"; \
    find /opt/cetech/release \
      -type d \
      -exec chmod 0755 {} +; \
    find /opt/cetech/release \
      -type f \
      -exec chmod 0644 {} +; \
    chmod 0640 \
      "${release_root}/wp-config.php"; \
    chown -R root:root \
      /opt/cetech/release; \
    chown -R www-data:www-data \
      "${release_root}/wp-content/uploads" \
      "${release_root}/wp-content/cache" \
      "${release_root}/wp-content/upgrade"; \
    mkdir -p /var/run/php; \
    chown www-data:www-data /var/run/php

WORKDIR /opt/cetech/release

EXPOSE 9000

STOPSIGNAL SIGQUIT

HEALTHCHECK \
  --interval=15s \
  --timeout=5s \
  --start-period=30s \
  --retries=5 \
  CMD SCRIPT_NAME=/fpm-ping \
      SCRIPT_FILENAME=/fpm-ping \
      REQUEST_METHOD=GET \
      cgi-fcgi -bind -connect 127.0.0.1:9000 \
      | grep -q pong || exit 1

USER www-data:www-data

ENTRYPOINT ["cetech-entrypoint"]
CMD ["php-fpm", "-F"]
