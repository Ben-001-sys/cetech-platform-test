# Repeated errors log

## 1. Attempted shell path change

- Command: `cd /h/BEN/Development/CETECH; git status --short --branch; git pull --ff-only`
- Result: Failed immediately because the shell session is PowerShell and the path was supplied using a Linux-style `/h/...` path.
- Reason: The workspace path is Windows-backed; the path must be expressed as `H:\BEN\Development\CETECH` in PowerShell.
- Should it ever be rerun? Yes, but only once the path is corrected.
- Condition: Re-run using PowerShell `Set-Location 'H:\BEN\Development\CETECH'` followed by the intended Git commands.

## 2. Repository-validation rule matched placeholders

- Command: `git ls-files | Select-String '(?i)(^|/)wp-content/uploads/|\.gitkeep$'`
- Result: Success; it listed the tracked `uploads/.gitkeep` placeholders in the three WordPress app directories.
- Reason: This confirmed the exact files making the repository-validation job fail.
- Should it ever be rerun? Yes, but only after the repository-only fix is applied to verify the rule no longer matches.
- Condition: Re-run after removing the tracked upload placeholders from the index.

## 3. Trivy image failures

- Command: Trivy-local image scan after the Dockerfile change.
- Result: The image build now refreshes OS packages and no longer stores WordPress secrets in Dockerfile `ARG` / `ENV` metadata, so the prior secret scan trigger is removed.
- Reason: That is an image security issue, not a repository validation issue.
- Should it ever be rerun? Yes, after the image is rebuilt and scanned in CI.
- Condition: Re-run once the updated image is pushed or the workflow reaches the Trivy scan step again.
