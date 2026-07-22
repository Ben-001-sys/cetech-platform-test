# Decision log

## Stage: Repository validation blocker isolation

- Problem: GitHub Actions `repository-validation` is failing because tracked files exist under `wp-content/uploads/`.
- Root Cause: The repository currently tracked three `uploads/.gitkeep` placeholders, and the workflow explicitly rejects any tracked `wp-content/uploads/` path.
- Solution: Remove the upload placeholder files from the repository index and stop re-including them in `.gitignore` so the repository policy matches the CI validator.
- Files changed: `.gitignore`, `apps/blog-en/wp-content/uploads/.gitkeep`, `apps/corporate/wp-content/uploads/.gitkeep`, `apps/store-gh/wp-content/uploads/.gitkeep`
- Commit SHA: `63fdcdf`
- Result: Verified locally with the same predicate used in CI; the forbidden-files check now reports `No forbidden tracked files detected.`

## Stage: Runtime-only secret injection and image refresh

- Problem: Trivy flagged Dockerfile `ARG` / `ENV` metadata for WordPress secrets and reported OS package vulnerabilities in the image layer.
- Root Cause: The PHP image build embedded WordPress secret values into image metadata and did not refresh Debian packages before packaging the final image.
- Solution: Remove secret-bearing `ARG` and `ENV` entries from the Dockerfile, require the secrets at runtime through the container environment, and run `apt-get upgrade` during the image build so the final image includes current Debian security updates.
- Files changed: `docker/php/Dockerfile`, `docker/php/wp-config.php`
- Result: The Dockerfile no longer stores the secret values in image build metadata, and the image build now refreshes the OS package set before installing PHP extensions.
