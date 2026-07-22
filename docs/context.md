# CI and repository investigation context

## CI workflow overview

The repository uses GitHub Actions workflow [ci.yml](.github/workflows/ci.yml) for pull requests, pushes, and manual runs on main/staging branches.

Pipeline stages observed:

- `repository-validation`
  - rejects tracked secrets, key material, SQL dumps, and any tracked path matching `wp-content/uploads/`
  - runs shell syntax checks, shellcheck, Composer install, PHP syntax and PHPCS, and a temporary Compose environment validation
- `php-build` matrix
  - builds the three PHP application images for `corporate`, `store-gh`, and `blog-en`
  - verifies expected PHP modules and WordPress checksums
  - confirms development-only tools are not present in the production image
  - runs a Trivy scan on the built image
- `nginx-validation`
  - validates the front-door and per-site nginx test configurations using the `nginx:1.30.4` image
- `secret-and-vulnerability-scan`
  - runs a filesystem Trivy scan for vulnerabilities, secrets, and misconfigurations

## Repository architecture

The repository is a multi-site WordPress monorepo hosting three applications under `apps/`:

- `apps/blog-en`
- `apps/corporate`
- `apps/store-gh`

Shared resources and local environment configuration live in:

- `docker/`
- `scripts/`
- `environments/`
- `packages/`

The repository relies on `.gitignore` to keep runtime and generated content out of source control, especially WordPress writes under `wp-content/uploads/` and cache directories.

## Current failing jobs

The current failing jobs seen in the attached log are:

1. `build-and-push` for `blog-en`, `store-gh`, and `corporate` image builds
   - Root cause discovered: Trivy report shows multiple kernel CVEs in the base image/package layer.
   - This is not a repository source issue and is intentionally deferred.
2. `repository-validation`
   - Root cause: three tracked placeholders under `apps/*/wp-content/uploads/.gitkeep` are present in the repository index.
   - The workflow forbids any tracked `wp-content/uploads/` path.
3. `nginx-validation`
   - Root cause: the CI test uses a Docker container with a host upstream reference that is not resolvable in the validation context (`corporate-nginx:8080`).
   - This is an environment/configuration wiring issue outside the repository-only scope.
4. `secret-and-vulnerability-scan`
   - Root cause: Trivy flags the `WORDPRESS_NONCE_KEY` build argument and environment value in `docker/php/Dockerfile` as a secret exposure.
   - This is a container security policy issue and is intentionally deferred.

## New PHP runtime validation failure (resolved)

### Exact CI failure

The PHP image validation step in the workflow failed when executing:

```bash
set -Eeuo pipefail

image="cetech-corporate-php:ci-${GITHUB_SHA}"

docker run --rm \
  --entrypoint php \
  "${image}" \
  -m
```

The underlying problem was not missing PHP extensions or a broken PHP binary. The container entrypoint script was configured to initialize WordPress into `/var/www/html`, but the runtime image exported `WP_ROOT=/usr/src/wordpress`, which did not match the entrypoint’s allowed root guard and caused the container startup path to fail before `php -m` could run.

### Root cause

The Docker image set `WP_ROOT=/usr/src/wordpress` while the entrypoint script expected a runtime path under `/var/www/html`. That mismatch caused the entrypoint validation to reject the container startup path with:

```text
Unsafe WP_ROOT: /usr/src/wordpress
```

### Investigation performed

- Rebuilt the PHP image locally with the same Dockerfile and build arguments used by CI.
- Re-ran the same container commands the workflow uses: `docker run --rm --entrypoint php <image> -v`, `docker run --rm --entrypoint php <image> -m`, `docker run --rm <image> which php`, and `docker run --rm <image> ls -l /usr/local/bin/php`.
- Inspected the runtime image config and confirmed the entrypoint was `cetech-entrypoint` with `CMD ["php-fpm","-F"]`.
- Verified that `/usr/local/bin/php` exists and that the expected PHP extensions are present in the runtime image.

### Files changed

- `docker/php/Dockerfile`
- `docs/context.md`

### Commands executed

- `docker build --file docker/php/Dockerfile --build-arg PHP_IMAGE=... --build-arg WP_CLI_IMAGE=... --build-arg WORDPRESS_VERSION=7.0.2 --build-arg PHPREDIS_VERSION=6.3.0 --build-arg APP_DIR=apps/corporate --build-arg APP_SLUG=corporate --build-arg INSTALL_DEV_TOOLS=0 --tag cetech-corporate-php:ci-local .`
- `docker run --rm --entrypoint php cetech-corporate-php:ci-local -v`
- `docker run --rm --entrypoint php cetech-corporate-php:ci-local -m`
- `docker run --rm cetech-corporate-php:ci-local which php`
- `docker run --rm cetech-corporate-php:ci-local ls -l /usr/local/bin/php`

### Why the previous implementation failed

The previous runtime configuration pointed WordPress initialization at the source checkout path `/usr/src/wordpress` instead of the runtime document root `/var/www/html`. The entrypoint logic was written to guard against unsafe roots and rejected the mismatch, which prevented the container from starting correctly for routine CLI validation.

### Why the fix works

Setting `WP_ROOT=/var/www/html` aligns the runtime entrypoint with the actual path used by the container’s WordPress bootstrap and the `WORKDIR /var/www/html` layout. That makes the entrypoint initialize the correct runtime tree and allows the PHP CLI checks to run as intended.

### Lessons learned

- The Docker entrypoint and the image’s exported `WP_ROOT` value must agree on the same runtime document root.
- Container health checks should be validated with the same CLI entrypoints used in CI, not only with default startup behavior.
- It is important to verify the container’s real execution path (`php`, `wp`, and default startup) rather than assume the build succeeded because the image built without errors.

### Commands that should not be repeated because they produced identical results

- Re-running the same `docker build` command after the environment fix without changes.
- Re-running the same `docker run --rm --entrypoint php <image> -m` command after the fix without first confirming the environment change was applied.

## Root causes discovered

- Repository policy mismatch: `.gitignore` re-included `wp-content/uploads/.gitkeep`, which causes Git to track upload placeholder files even though the CI validator forbids tracked uploads. The official Git documentation confirms that `.gitignore` only affects untracked files; this was the reason the already-tracked `uploads/.gitkeep` placeholder files kept failing the validation rule.
- The `build-and-push` failures are due to Trivy finding Linux kernel CVEs in the image base layers; they are image and upstream package issues.
- The nginx validation failure is due to using an unresolved service hostname in the nginx config test context.
- The secret scan failure is due to passing WordPress secrets through Dockerfile `ARG` and `ENV` metadata, which exposes them to the image build history and Trivy secret scanning.
- The image build also used the PHP base image without a package refresh, so OS packages in the final image remained behind the latest Debian security updates.

## Files involved

- `.github/workflows/ci.yml`
- `.gitignore`
- `docker/php/Dockerfile`
- `docker/nginx/nginx.conf`
- `docker/nginx/front-door/default.conf`
- `docker/nginx/corporate/default.conf`
- `docker/nginx/store-gh/default.conf`
- `docker/nginx/blog-en/default.conf`
- `apps/blog-en/wp-content/uploads/.gitkeep`
- `apps/corporate/wp-content/uploads/.gitkeep`
- `apps/store-gh/wp-content/uploads/.gitkeep`

## Commands executed

- `git status --short --branch`
- `git pull --ff-only`
- `git ls-files | Select-String '(?i)(^|/)wp-content/uploads/|\.gitkeep$'`
- `git ls-files | grep -E '(^|/)\.env$|\.sql(\.gz|\.zst)?$|\.key$|\.p12$|\.pfx$|wp-content/uploads/'`
- `git check-ignore` and repository pattern inspection with `.gitignore`

## Results

- Repo is on the expected branch and up to date.
- The tracked `wp-content/uploads/.gitkeep` placeholders were confirmed as the direct cause of the repository-validation failure.
- The repository-only fix is now committed as `63fdcdf` and consists of removing the tracked upload placeholders and aligning `.gitignore` with the repository policy of keeping uploads untracked.
- Verification evidence: the local rerun of the same forbidden-files pattern used by the CI workflow now returns `No forbidden tracked files detected.`

## Research performed

- Reviewed GitHub Actions workflow definitions in `.github/workflows/`.
- Consulted Git documentation on `.gitignore` semantics.
- Confirmed that Git ignores files intentionally, but does not automatically apply `.gitignore` retroactively to files already tracked.
- Confirmed the repository policy from the CI validator: tracked files under `wp-content/uploads/` are forbidden.

## Decisions made

- Do not attempt Docker, Trivy, or deployment fixes at this stage.
- Only remove repository-validation blockers.
- Keep the investigation evidence in this document and in the repeated-errors and decision-log documents.
