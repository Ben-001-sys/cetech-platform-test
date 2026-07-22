#!/usr/bin/env bash
set -Eeuo pipefail

release_number="${1:-1}"
today="$(date -u +%Y.%m.%d)"
tag="v${today}.${release_number}"

if [[ ! "${release_number}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Release number must be a positive integer." >&2
  exit 1
fi

git fetch origin --prune

if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "Releases must be created from main." >&2
  exit 1
fi

git pull --ff-only origin main

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean." >&2
  exit 1
fi

if git rev-parse "${tag}" >/dev/null 2>&1; then
  echo "Tag ${tag} already exists." >&2
  exit 1
fi

git tag \
  --sign \
  --annotate "${tag}" \
  --message "CETECH production release ${tag}"

git push origin "${tag}"

echo "Created ${tag} at $(git rev-parse HEAD)"
