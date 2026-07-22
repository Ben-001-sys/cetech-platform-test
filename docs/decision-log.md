# Decision log

## Stage: Repository validation blocker isolation

- Problem: GitHub Actions `repository-validation` is failing because tracked files exist under `wp-content/uploads/`.
- Root Cause: The repository currently tracked three `uploads/.gitkeep` placeholders, and the workflow explicitly rejects any tracked `wp-content/uploads/` path.
- Solution: Remove the upload placeholder files from the repository index and stop re-including them in `.gitignore` so the repository policy matches the CI validator.
- Files changed: `.gitignore`, `apps/blog-en/wp-content/uploads/.gitkeep`, `apps/corporate/wp-content/uploads/.gitkeep`, `apps/store-gh/wp-content/uploads/.gitkeep`
- Commit SHA: `63fdcdf`
- Result: Verified locally with the same predicate used in CI; the forbidden-files check now reports `No forbidden tracked files detected.`
