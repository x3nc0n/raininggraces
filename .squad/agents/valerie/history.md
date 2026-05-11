# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Architecture document available at `docs/architecture.md`. CI/CD requires two workflows: (1) SWA deploy for main Jekyll site, (2) separate deployment for photo app repo. See architecture doc for SWA Free tier limitations and GitHub Actions cron setup for 30-day photo cleanup.
- **2026-05-11:** `az staticwebapp users invite` requires `--domain` parameter (the SWA default hostname). The domain for swa-raininggraces-photos is `blue-hill-07daee510.7.azurestaticapps.net`. Invitation expiry is 7 days (168 hours) by default.
- **2026-05-11:** SWA app settings are stored encrypted — `az staticwebapp appsettings set` output shows `null` values for all keys by design (redacted). Use `az staticwebapp appsettings list` to verify keys are present (names visible, values redacted with WARNING).
- **2026-05-11:** The `az account set` is required before any resource operations if the CLI is pointed at a different subscription. The target subscription for this project is `7e1b60b8-d616-4396-9de2-fc917930d02e` (Spaid Family Core Infra LZ).
- **2026-05-11:** Confirmed all 4 expected app settings on swa-raininggraces-photos: ADMIN_EMAIL, AZURE_STORAGE_CONNECTION_STRING, CLEANUP_API_KEY, PUBLIC_APP_BASE_URL. AzureWebJobsStorage and FUNCTIONS_WORKER_RUNTIME are absent (correct).
- **2026-05-11:** cleanup-expired.yml in x3nc0n/raininggraces-photos is correctly wired — runs daily at 06:00 UTC, reads `vars.PUBLIC_APP_BASE_URL` (repo variable) and `secrets.CLEANUP_API_KEY`, POSTs to `/api/cleanup` with `x-cleanup-key` header.
- **2026-05-11 (post-deploy):** Admin invite completed — Robin successfully invited as admin on photo app SWA (invitation link expires May 18). CLEANUP_API_KEY generated and configured in both SWA app settings and GitHub Actions secret. All app settings verified correct on swa-raininggraces-photos. Cleanup workflow validation passed.
- **2026-05-11T13:18:46.291-05:00:** Photo app security review coverage: `staticwebapp.config.json`, all `api/*` functions, `src/assets/js/{admin,share}.js`, `.github/workflows/*.yml`, and `infra/modules/photo-platform.bicep`. Admin routes are protected, blob storage is private, SAS tokens are HTTPS-only and scoped (`cw` upload, `r` download).
- **2026-05-11T13:18:46.291-05:00:** Key security gaps in x3nc0n/raininggraces-photos: plaintext album passwords persisted in `api/helpers/storage.js` and exposed via `api/albums-password-get/index.js`; ZIP downloads send passwords in query strings via `src/assets/js/share.js` → `api/share-download/index.js`; anonymous health/error paths expose internal details in `api/health/index.js`, `api/helpers/auth.js`, and `.github/workflows/deploy.yml` is broader than least-privilege.
- **2026-05-11T18:25:43Z (Scribe post-spawn):** Security review complete. Five issues (#7–#10) + summary issue (#6) created in `x3nc0n/raininggraces-photos`. Findings archived to `decisions.md`. Team dependencies: Inigo remediate plaintext passwords, verbose errors; Valerie scope workflow permissions to least-privilege. All issues tagged security + priority. Deployment blocked until remediations complete.
- **2026-05-11T14:34:36.488-05:00 (Agent valerie-12):** Azure Functions timer trigger deployed successfully. Created `func-raininggraces-cleanup` Function App on Consumption plan (Node.js 24, latest post-EOL runtime). Timer function calls authenticated SWA `/api/cleanup` endpoint. Reused `straininggraces` storage account for `AzureWebJobsStorage`. Rotated `CLEANUP_API_KEY`. Removed `cleanup-expired.yml` GitHub Actions workflow. Live probe confirmed operational. Migrates cleanup from CI/CD cron to serverless timer — zero monthly cost, no logic duplication.
- **2026-05-11 (Agent valerie-lifecycle):** 45-day blob lifecycle policy applied to `straininggraces` storage account (`photos` container). Serves as automated backup retention mechanism beyond 30-day cleanup window. Cost control: prevents accidental eternal storage of uploaded photos.
