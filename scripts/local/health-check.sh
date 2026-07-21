#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ca="${repo_root}/environments/local/certs/cetech-local-ca.crt"

declare -A expected=(
  ["https://cetech.test/"]="CETECH Corporate"
  ["https://cetech.test/gh/"]="CETECH Ghana Store"
  ["https://cetech.test/en/"]="CETECH English Blog"
)

failed=0

for url in "${!expected[@]}"; do
  body="$(mktemp)"
  headers="$(mktemp)"

  status="$(
    curl \
      --cacert "${ca}" \
      --silent \
      --show-error \
      --location \
      --max-redirs 10 \
      --dump-header "${headers}" \
      --output "${body}" \
      --write-out '%{http_code}' \
      "${url}"
  )"

  if [[ "${status}" != "200" ]]; then
    echo "FAIL ${url}: HTTP ${status}" >&2
    failed=1
  else
    echo "PASS ${url}: HTTP 200"
  fi

  if grep -qiE \
    'main\.cetech\.test|gh\.cetech\.test|en\.cetech\.test' \
    "${headers}" "${body}"; then
    echo "FAIL ${url}: internal hostname leaked" >&2
    failed=1
  fi

  rm -f "${headers}" "${body}"
done

for path in \
  /wp-json/ \
  /gh/wp-json/ \
  /en/wp-json/
do
  status="$(
    curl \
      --cacert "${ca}" \
      --silent \
      --show-error \
      --output /dev/null \
      --write-out '%{http_code}' \
      "https://cetech.test${path}"
  )"

  if [[ "${status}" != "200" ]]; then
    echo "FAIL ${path}: REST API returned ${status}" >&2
    failed=1
  else
    echo "PASS ${path}: REST API HTTP 200"
  fi
done

exit "${failed}"
