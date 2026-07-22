#!/bin/sh

set -eu

: "${VALKEY_PASSWORD:?VALKEY_PASSWORD is required}"
: "${VALKEY_MAXMEMORY:?VALKEY_MAXMEMORY is required}"

cp /etc/valkey/valkey.conf.template /tmp/valkey.conf

sed -i \
    -e "s|\${VALKEY_PASSWORD}|${VALKEY_PASSWORD}|g" \
    -e "s|\${VALKEY_MAXMEMORY}|${VALKEY_MAXMEMORY}|g" \
    /tmp/valkey.conf

exec valkey-server /tmp/valkey.conf