# IaC Fix Decisions — 2026-05-11

**Author:** Valerie  
**Date:** 2026-05-11

## Decisions Made

### 1. `PUBLIC_APP_BASE_URL` is the canonical variable name for the photo app base URL

The Bicep templates in `infra/modules/photo-platform.bicep` use `PUBLIC_APP_BASE_URL` as both the SWA app setting and the Azure Functions app setting. The GitHub Actions repository variable for the cleanup workflow should match this name. All references to `PHOTO_APP_BASE_URL` (README, cleanup-expired.yml, provision-azure.yml) have been updated to `PUBLIC_APP_BASE_URL`.

**Impact:** Anyone who already configured `PHOTO_APP_BASE_URL` as a repository variable in `x3nc0n/raininggraces-photos` must rename it to `PUBLIC_APP_BASE_URL` before the cleanup workflow will succeed.

### 2. Deploy to Azure buttons should point to the default branch

The "Deploy to Azure" button URL in `raininggraces` README was pointing to `azure-migration`. Updated to `master` so the button is valid after the PR merges. Going forward, ARM template URLs in READMEs should always reference `master` (main site) or `main` (photo app) — never a feature branch.

### 3. `azuredeploy.json` must be regenerated after Bicep changes

The `azuredeploy.json` in `raininggraces-photos` was already committed (added in the initial IaC commit). It was confirmed to be in sync with the Bicep templates. Going forward, any changes to `infra/main.bicep` or its modules require re-running `az bicep build --file infra/main.bicep --outfile azuredeploy.json` and committing the updated ARM JSON.
