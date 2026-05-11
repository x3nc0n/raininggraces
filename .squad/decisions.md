# Squad Decisions

## Active Decisions

### 2026-05-10: Azure Architecture for Raining Graces (APPROVED)

**Author:** Westley  
**Date:** 2026-05-10

Designed full architecture for migrating Jekyll site from Netlify to Azure Static Web Apps (Free) and a new photo sharing app. Total estimated cost: ~$0.04/month.

**Key Decisions:**
1. Two Azure SWA Free tier apps — main site + photo app ($0/month each)
2. SWA built-in Entra ID auth over custom MSAL — zero code, zero maintenance
3. Azure Table Storage over Cosmos DB — included with Storage Account
4. Standard LRS storage — photos are temporary (30-day retention)
5. Separate repo (`raininggraces-photos`) for photo app
6. Direct-to-blob upload via SAS tokens
7. GitHub Actions cron for 30-day cleanup (SWA Free Functions don't support Timer triggers)
8. Keep DNS at current registrar
9. Central US region (South Central US not available for SWA Free)

**Impact:** All team members should read `docs/architecture.md`. Inigo/Fezzik: independent tracks. Valerie: two workflows needed. Vizzini: test SWA config and endpoints.

**Artifacts:** `docs/architecture.md` (full architecture with diagrams, cost tables, auth flows, data model, API design)

---

### 2026-05-10: Photo Expiration Policy

**By:** John Spaid (via Copilot)  
**Date:** 2026-05-10

Photos and share links should auto-expire and be deleted 30 days after upload. Cost is the #1 factor for this project — policy prevents ever-expanding blob storage usage.

---

### 2026-05-10T11:33:37-05:00: 30-Day Retention Directive

**By:** John Spaid (via Copilot)

Photos and share links should auto-expire and be deleted 30 days after upload. This keeps storage costs down by preventing ever-expanding blob storage usage.

**Why:** User request — captured for team memory. Cost is the #1 factor for this project.

---

### 2026-05-10T20:10:36-05:00: Skip Defender for Storage

**By:** John Spaid (via Copilot)

Defender for Storage is not needed. Robin's account has PHRMFA enabled, and even if malware were uploaded, only one person could download it. The risk doesn't justify the ~$10/mo cost.

**Why:** User request — captured for team memory

---

### 2026-05-10T13:05:12-05:00: Standardize Photo Share Route (Fezzik)

**Author:** Fezzik

Standardize public album links on `/share/{shareToken}` and have the API/helper-generated `shareUrl` values use that same route. Also keep a dedicated SWA rewrite rule for `/share/*` to serve `src/share/index.html`.

**Why:** This keeps generated share links, frontend routing, and Static Web Apps behavior aligned so families land directly in the password screen without a broken SPA fallback.

---

### 2026-05-10T13:05:12-05:00: Admin Email Guard (Inigo)

**Author:** Inigo

In addition to SWA's `authenticated` role checks, the photo API supports an `ADMIN_EMAIL` app setting. When set, admin endpoints reject authenticated callers whose principal email does not match the configured address.

**Why:** The architecture notes that Robin may be the only user in the tenant, but also recommends verifying the caller email for extra safety. Making this an app-setting guard keeps the default SWA flow simple while allowing a tighter production lock without code changes.

**Impact:** 
- Valerie should include `ADMIN_EMAIL` in deployment configuration for the photo app.
- Fezzik can rely on `401/403` responses for admin-only frontend flows.

---

### 2026-05-11T07:45:28-05:00: Azure IaC Bootstrap (Valerie)

**Author:** Valerie

Use subscription-scope Bicep plus manually triggered GitHub Actions OIDC workflows in both repos for provisioning, and treat SWA deployment-token secret setup as a documented bootstrap step after provisioning.

**Why:** This keeps Azure resource creation in CI/CD as requested, avoids manual portal provisioning, and respects GitHub's limitation that the default workflow token cannot create or update repository secrets.

---

### 2026-05-11: IaC Fix Decisions (Valerie)

**Author:** Valerie

#### 1. `PUBLIC_APP_BASE_URL` is the canonical variable name for the photo app base URL

The Bicep templates in `infra/modules/photo-platform.bicep` use `PUBLIC_APP_BASE_URL` as both the SWA app setting and the Azure Functions app setting. The GitHub Actions repository variable for the cleanup workflow should match this name. All references to `PHOTO_APP_BASE_URL` (README, cleanup-expired.yml, provision-azure.yml) have been updated to `PUBLIC_APP_BASE_URL`.

**Impact:** Anyone who already configured `PHOTO_APP_BASE_URL` as a repository variable in `x3nc0n/raininggraces-photos` must rename it to `PUBLIC_APP_BASE_URL` before the cleanup workflow will succeed.

#### 2. Deploy to Azure buttons should point to the default branch

The "Deploy to Azure" button URL in `raininggraces` README was pointing to `azure-migration`. Updated to `master` so the button is valid after the PR merges. Going forward, ARM template URLs in READMEs should always reference `master` (main site) or `main` (photo app) — never a feature branch.

#### 3. `azuredeploy.json` must be regenerated after Bicep changes

The `azuredeploy.json` in `raininggraces-photos` was already committed (added in the initial IaC commit). It was confirmed to be in sync with the Bicep templates. Going forward, any changes to `infra/main.bicep` or its modules require re-running `az bicep build --file infra/main.bicep --outfile azuredeploy.json` and committing the updated ARM JSON.

---

### 2026-05-11T11:15:42-05:00: `az staticwebapp users invite` Requires `--domain` Parameter (Valerie)

**Author:** Valerie  
**Severity:** Informational

The `az staticwebapp users invite` command requires a `--domain` argument even though the SWA default hostname is deterministic. Without it, the command fails with "ERROR: the following arguments are required: --domain".

**Resolution:** Always retrieve the hostname first, then pass it to the invite command:

```bash
DOMAIN=$(az staticwebapp show --name <name> --resource-group <rg> --query "defaultHostname" -o tsv)
az staticwebapp users invite ... --domain "$DOMAIN"
```

**Impact:** Any future IaC or runbook that invites users to an SWA must include this lookup step.

---

### 2026-05-11: P0 Smoke Test Failures (Vizzini)

**Author:** Vizzini (Tester)  
**Severity:** Two failures — one Critical, one High  
**Date:** 2026-05-11

Ran live smoke tests against photo app deployment. 13/15 tests passed. Two failures identified:

#### CRITICAL: /admin Serves HTML to Unauthenticated Users

**Test:** GET /admin with no auth cookie  
**Expected:** 302 redirect to `/.auth/login/aad` (or 401)  
**Actual:** 200 OK — full admin dashboard HTML returned

The SWA routing configuration in `staticwebapp.config.json` is not enforcing authentication on the `/admin` route. Any user who knows the URL gets the full dashboard HTML, including the create-album form, album list UI, and references to all API endpoints.

**Fix Required:** Add auth requirement on the `/admin` route:
```json
{
  "route": "/admin",
  "allowedRoles": ["authenticated"]
}
```

This causes SWA to redirect unauthenticated requests to `/.auth/login/aad` before serving any HTML.

#### HIGH: Rate Limiting Not Triggering

**Test:** 10 rapid POST requests to `/api/share/{token}/verify` with wrong password  
**Expected:** First 5 return 404, 6th+ return 429  
**Actual:** All 10 return 404 — 429 never observed

**Probable Cause:** Rate limiter is in-memory counter per function instance. Azure Functions Consumption plan spins up multiple instances under load. Sequential requests may hit different instances, each with a fresh counter.

**Risk:** Brute-force attack against share token can make unlimited password attempts.

**Recommended fixes:**
1. Use Azure Table Storage as persistent rate-limit counter (cross-instance)
2. Use Azure Cache for Redis (adds cost)
3. Rely on SWA's built-in per-route rate limiting if available
4. Document limitation and accept risk given low-value content

**Team Note:** Architectural decision needed (Inigo/Westley). Option 1 (Table Storage counter) is straightforward.

---

### 2026-05-10: Test Plan Complete (Vizzini)

**Author:** Vizzini (Tester)  
**Status:** Complete  

Created comprehensive test plan at `docs/test-plan.md` covering both workloads (Jekyll migration + photo app).

**Scope:**
- **148 test cases** organized by category and priority (P0–P3)
- **Main Site Migration (10 tests):** Jekyll build, html-proofer, SWA config, 404 handling, SSL/custom domain
- **Photo App API (13 tests):** Album CRUD, upload flow, share link verification, SAS token generation
- **Security (8 tests):** Auth enforcement, UUID unguessability, SAS expiry, blob privacy, cleanup API key validation
- **Rate Limiting (2 tests):** 5 attempts/minute/IP on verify endpoint
- **Cleanup & Retention (7 tests):** 30-day expiry, cleanup deletes only expired albums, blob lifecycle policy backup
- **Edge Cases (12 tests):** Empty albums, large files, special characters, concurrent uploads, missing data
- **Integration & Smoke (4 tests):** End-to-end workflows, independence of deployments
- **Performance (2 tests):** Large file upload speed, album list performance (P3)

**Success Criteria:**
- All 21 P0 tests (critical: build, auth, upload, cleanup, retention, end-to-end)
- 95% of 19 P1 tests (core functionality, admin workflows)
- Jekyll build + html-proofer validation
- SSL certificates valid at both domains

**Key Assumptions:**
1. Implementation follows architecture doc (Section 9 API design)
2. Rate limiting implemented as per architecture (in-memory counter, 5/min/IP)
3. 30-day retention strictly enforced (30 days from album creation → expiry)
4. SAS tokens: 15 min upload, 1 hour download (per architecture)
5. Cleanup runs daily via GitHub Actions cron
6. Blob lifecycle policy set to 31-day delete (backup)

---

### 2026-05-11T10:53:11.105-05:00: Normalize Azure Table entity keys in storage helper (Inigo)

**Author:** Inigo

`raininggraces-photos\api\helpers\storage.js` should treat Azure Table entity keys as mixed-case inputs:

- SDK responses from `@azure/data-tables` v13 use `partitionKey` and `rowKey`
- Locally constructed entities in this codebase still use `PartitionKey` and `RowKey` before persistence

Normalization helpers must therefore read both forms when deriving `albumId` and `photoId`.

**Why:** Album and photo IDs were being normalized as `undefined` after `listEntities()`/`getEntity()`, which broke upload and delete flows with false "Album not found" errors and silent delete failures.

**Impact:**
- `normalizeAlbumEntity()` and `normalizePhotoEntity()` need dual-case fallback logic
- Delete flows that depend on normalized IDs work again without changing API routes
- `confirmPhotoUploads()` remains compatible because SDK-fetched entities already carry camelCase keys for `updateEntity()`

---

### 2026-05-11T11:09:27.088-05:00: Upload confirm/CORS hardening (Inigo)

**Author:** Inigo

**Context:**
- Admin photo uploads were stopping after the first saved photo.
- Direct browser PUTs to Blob Storage use SAS URLs and require a successful CORS preflight.
- `confirmPhotoUploads` was doing a full-table-entity replace using the raw Azure Data Tables SDK response from `getEntity()`.

**Decision:**
1. Blob Storage CORS must allow both `PUT` and `OPTIONS` for the photo app SWA origin.
2. Photo confirmation updates should build an explicit replacement entity instead of spreading the raw SDK entity object.
3. Password endpoint investigation found the Azure Function route bindings and SWA `/api/albums*` rule were already correct; legacy albums without `passwordPlain` should continue returning 404 from GET until reset writes a new plaintext password.

**Why:**
- Browsers send an `OPTIONS` preflight for cross-origin SAS PUT uploads, so allowing only `PUT` is insufficient.
- Raw `getEntity()` responses can include SDK metadata that should not be sent back in a replace update.
- Preserving the 404 behavior for older albums keeps the admin UI contract intact while allowing reset to repair old records.

---

### 2026-05-11T13:18:46.291-05:00: Photo app release gates (Westley)

**Author:** Westley  
**Topic:** Photo app release gates

Treat two items as release-blocking for the live photo app on `photos.raininggraces.com`:

1. **Blob Storage CORS must allow the custom domain,** not just the SWA default hostname.
2. **The GitHub cleanup workflow must be fully wired** and manually validated end-to-end with `PUBLIC_APP_BASE_URL` set.

**Why:** These are not polish items. They are core operational controls for the app's two promises: Robin can upload photos from the live hostname, and photos expire automatically after 30 days to keep costs contained.

**Evidence:**
- Live blob preflight from `https://photos.raininggraces.com` returns `403`, while the default SWA hostname returns `200`.
- `raininggraces-photos/.github/workflows/cleanup-expired.yml` requires `PUBLIC_APP_BASE_URL`, and the repo currently has no GitHub variables configured.

**Team Impact:**
- **Inigo / Fezzik:** Keep upload/share flows aligned with the custom-domain path, not just the default hostname.
- **Valerie:** Fix IaC + workflow configuration drift so reprovisioning preserves both CORS and cleanup wiring.
- **Vizzini:** Re-run smoke tests on custom-domain upload and manual cleanup execution after fixes land.

---

### 2026-05-11T14:34:36.488-05:00: Move retention cleanup from GitHub Actions to Azure Functions Timer (Valerie)

**Decision:** Use a dedicated Azure Function App on the Consumption plan in `centralus` for the 30-day album retention schedule.

- Keep the cleanup implementation dead simple by having the timer function call the existing authenticated SWA endpoint at `POST /api/cleanup` instead of duplicating storage deletion logic.
- Reuse the existing `straininggraces` storage account for `AzureWebJobsStorage` and store only `CLEANUP_API_KEY` plus `CLEANUP_ENDPOINT` in the Function App.
- Deploy the Function App on the latest supported Azure Functions Node.js runtime because Azure Functions no longer accepts Node.js 20 after its 2026-04-30 end-of-life date.

**Why:** This keeps monthly cost effectively at zero for the schedule itself, removes GitHub Actions from the retention path, and avoids creating a second implementation of album/blob deletion logic. The SWA cleanup endpoint already encapsulates the production cleanup behavior, so the timer becomes a small, auditable scheduler with less code and less drift risk.

**Status:** IMPLEMENTED. Created `func-raininggraces-cleanup` on Consumption plan (Node 24), deployed timer function, removed cleanup-expired.yml workflow, added function source under `functions/cleanup-timer/` in raininggraces-photos repo. Rotated cleanup API key. Verified running with successful live probe.

---

### 2026-05-11T17:35:34.210-05:00: Code Review Approval — PR #13 Security Hardening (Westley)

**Author:** Westley (Lead)  
**Branch:** `squad/security-hardening`  
**Date:** 2026-05-11  
**Verdict:** **APPROVE** ✅

Complete security hardening review for PR #13 addressing issues #6–#10:
- **#6 (HIGH):** Remove plaintext password storage — show-once model implemented correctly
- **#7 (HIGH):** Move download password from URL to POST body — closes credential leakage
- **#8 (MEDIUM):** Strip health endpoint — no info disclosure to unauthenticated callers
- **#9 (MEDIUM):** Sanitize API error responses — no stack traces or config details leak
- **#10 (LOW):** Scope workflow permissions to least-privilege

Breaking changes are handled gracefully. No data migration needed (old `passwordPlain` fields degrade safely). Frontend/backend updated in lockstep. All edge cases analyzed and mitigated.

**Blocking issues:** None. **Recommendation:** Merge after Vizzini validates with smoke tests.

**Full review:** `.squad/decisions/inbox/westley-pr13-review.md` (merged into this entry)

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
