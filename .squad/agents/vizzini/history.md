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
