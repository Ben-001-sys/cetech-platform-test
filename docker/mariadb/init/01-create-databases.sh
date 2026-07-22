#!/usr/bin/env bash

set -Eeuo pipefail


# ==================================================
# Required Environment Variables
# ==================================================

required=(
    CORPORATE_DB_NAME
    CORPORATE_DB_USER
    CORPORATE_DB_PASSWORD

    STORE_DB_NAME
    STORE_DB_USER
    STORE_DB_PASSWORD

    BLOG_DB_NAME
    BLOG_DB_USER
    BLOG_DB_PASSWORD
)

for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
        echo "Missing ${name}" >&2
        exit 1
    fi
done


# ==================================================
# Create Databases & Users
# ==================================================

mariadb \
    --protocol=socket \
    -uroot \
    -p"${MARIADB_ROOT_PASSWORD}" <<SQL

CREATE DATABASE IF NOT EXISTS \`${CORPORATE_DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${CORPORATE_DB_USER}'@'%'
    IDENTIFIED BY '${CORPORATE_DB_PASSWORD}';

GRANT ALL PRIVILEGES
    ON \`${CORPORATE_DB_NAME}\`.*
    TO '${CORPORATE_DB_USER}'@'%';


CREATE DATABASE IF NOT EXISTS \`${STORE_DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${STORE_DB_USER}'@'%'
    IDENTIFIED BY '${STORE_DB_PASSWORD}';

GRANT ALL PRIVILEGES
    ON \`${STORE_DB_NAME}\`.*
    TO '${STORE_DB_USER}'@'%';


CREATE DATABASE IF NOT EXISTS \`${BLOG_DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${BLOG_DB_USER}'@'%'
    IDENTIFIED BY '${BLOG_DB_PASSWORD}';

GRANT ALL PRIVILEGES
    ON \`${BLOG_DB_NAME}\`.*
    TO '${BLOG_DB_USER}'@'%';


FLUSH PRIVILEGES;

SQL