#!/usr/bin/env bash
set -Eeuo pipefail

hostname="${1:?Hostname is required}"
output="${2:?Output path is required}"
template="infrastructure/ovhcloud/cloud-init-base.yml"

public_key="$(cat "${SSH_PUBLIC_KEY_PATH}")"

sed \
  -e "s/__HOSTNAME__/${hostname}/g" \
  -e "s|__SSH_PUBLIC_KEY__|${public_key}|g" \
  "${template}" \
  > "${output}"

chmod 0600 "${output}"
