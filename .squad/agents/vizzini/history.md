# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Architecture document available at `docs/architecture.md`. Test strategy should cover: SWA routing rules, Entra ID auth endpoints, blob upload SAS token validation, 30-day lifecycle cleanup (GitHub Actions cron). See architecture doc for full API and data model design.

- **2026-05-11:** P0 smoke test run against live photo app (https://blue-hill-07daee510.7.azurestaticapps.net). 13 of 15 tests passed. Two failures filed in `.squad/decisions/inbox/vizzini-p0-smoke-failures.md`:
  1. **CRITICAL — /admin unprotected:** `staticwebapp.config.json` missing `allowedRoles: ["authenticated"]` on the `/admin` route. SWA serves full dashboard HTML to unauthenticated users (200). Fix: add the route auth rule to the SWA config. API endpoints all correctly return 401.
  2. **HIGH — Rate limiting not working:** In-memory rate limiter never triggers 429 in practice. Azure Functions Consumption plan routes requests across multiple instances; each has its own counter so no single instance ever accumulates 5 hits from a client. Fix: move rate-limit counter to Azure Table Storage or accept the risk.
  - Note: `curl -o /dev/null` fails on Windows (exit code 23); always use `-o NUL` for Windows PowerShell test scripts.
  - SWA built-in auth confirmed working: `/.auth/login/aad` → 302 to Microsoft identity; `/.auth/me` → 200 with null principal when unauthenticated.
- **2026-05-11 (post-deploy):** P0 smoke test failures documented in `.squad/decisions.md`. Both issues escalated for team remediation — /admin auth enforcement and rate-limiting persistence required before all 15 tests can pass. Inigo tasked with implementing fixes.
- **2026-05-11T13:18:46.291-05:00:** Reviewed `C:\Users\jspai\.source\GitHub\raininggraces-photos` for QA issue creation. Useful test anchors: `api/helpers/auth.js` (`requireAdmin`, `ADMIN_EMAILS`, `userDetails` fallback), `api/helpers/storage.js` (Table Storage-backed rate limits, 15-minute upload SAS, 1-hour read SAS, album/photo cleanup), `staticwebapp.config.json` (`/admin` requires `authenticated`, `/api/share/*` anonymous), `src/assets/js/share.js` (gallery stays hidden until verify succeeds), and `.github/workflows/cleanup-expired.yml` (daily cleanup uses `PUBLIC_APP_BASE_URL` + `CLEANUP_API_KEY`). The existing test plan was found in the main repo at `docs/test-plan.md`, not in `raininggraces-photos\docs\test-plan.md`. Created five tracking issues in `x3nc0n/raininggraces-photos`: auth/security, upload/admin CRUD, share/download, retention/cleanup, and edge/error handling.
- **2026-05-11T18:25:43Z (Scribe post-spawn):** Test issue staging complete. Five issues (#1–#5) created in `x3nc0n/raininggraces-photos`. P0 smoke test failures archived to `decisions.md` (/admin unprotected CRITICAL, rate limiter HIGH). Team dependencies: Inigo fix /admin auth enforcement + rate-limit persistence; Vizzini re-run smoke tests after fixes. Test suite ready for execution once P0 blockers resolved.
- **2026-05-11T20:18:24Z (Security hardening complete):** Updated test plan issues #1–#5 with comments reflecting all completed security fixes: plaintext password removal, POST download body pattern, health endpoint sanitization, error response sanitization, and cleanup logging. All P0 blockers resolved by Inigo and Westley. Ready to re-run smoke test suite (13/15 → 15/15 expected).
