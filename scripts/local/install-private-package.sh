#!/usr/bin/env bash
set -Eeuo pipefail

site="${1:?Site is required}"
type="${2:?Type is required: plugin or theme}"
archive="${3:?Archive path is required}"
expected_sha="${4:?Expected SHA-256 is required}"

case "${site}" in
  corporate|store-gh|blog-en)
    ;;
  *)
    echo "Unsupported site: ${site}" >&2
    exit 1
    ;;
esac

case "${type}" in
  plugin)
    destination="apps/${site}/wp-content/plugins"
    ;;
  theme)
    destination="apps/${site}/wp-content/themes"
    ;;
  *)
    echo "Unsupported type: ${type}" >&2
    exit 1
    ;;
esac

actual_sha="$(sha256sum "${archive}" | awk '{print $1}')"

if [[ "${actual_sha}" != "${expected_sha}" ]]; then
  echo "Checksum mismatch." >&2
  echo "Expected: ${expected_sha}" >&2
  echo "Actual:   ${actual_sha}" >&2
  exit 1
fi

temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT

unzip -q "${archive}" -d "${temporary_directory}"

top_level_count="$(
  find "${temporary_directory}" \
    -mindepth 1 \
    -maxdepth 1 \
    | wc -l
)"

if [[ "${top_level_count}" -ne 1 ]]; then
  echo "Archive must contain one top-level package directory." >&2
  exit 1
fi

package_directory="$(
  find "${temporary_directory}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d
)"

package_name="$(basename "${package_directory}")"

rm -rf "${destination:?}/${package_name}"

rsync -a \
  "${package_directory}/" \
  "${destination}/${package_name}/"

find "${destination}/${package_name}" \
  -type d \
  -exec chmod 0755 {} +

find "${destination}/${package_name}" \
  -type f \
  -exec chmod 0644 {} +

echo "Installed ${package_name} into ${destination}"
