# Decisions Log

## Password Security Hardening (Issues #6 and #7)

**Author:** Inigo  
**Date:** 2026-05-11T15:05:08.870-05:00  
**Branch:** squad/security-hardening  
**Severity:** Two HIGH security issues resolved

---

### Issue #6: Removed Plaintext Password Storage

#### Problem
Album passwords were persisted in a `passwordPlain` field alongside the bcrypt hash. A dedicated `GET /api/albums/{albumId}/password` endpoint returned this plaintext value to any authenticated caller. The admin UI cached it in JavaScript state and could re-display it at any time.

#### Decision
**Never store the plaintext password.** Only the bcrypt hash is kept in Table Storage.

- `normalizeAlbumEntity`, `createAlbum`, and `updateAlbumPassword` in `storage.js` no longer accept or persist `passwordPlain`.
- The `albums-password-get` function folder has been deleted entirely.
- `albums-create` now returns `{ password }` once in the 201 response so Robin can copy it at creation time.
- `albums-password-reset` now returns `{ password }` once in the 200 response so Robin can copy it after a reset.
- The admin UI shows the password from the API response at creation/reset time only. There is no "Show Password" button; passwords are not re-fetched from storage.

#### Rationale
Storing a plaintext credential alongside its hash doubles the exposure surface for no benefit. The bcrypt hash is sufficient for `verifyPassword()` on the share/download path. A show-once model at creation/reset time is the industry-standard pattern for credentials.

#### Impact
- Any existing albums that had `passwordPlain` stored will simply not have that field read — no breakage.
- Robin must use "Reset Password" to recover access to a password she has lost; she cannot retrieve a previously-set password.

---

### Issue #7: Moved Download Password from URL to POST Body

#### Problem
`GET /api/share-download?token=...&password=...` sent the family album password in the URL query string, which appears in browser history, server access logs, referrer headers, and proxy logs.

#### Decision
**Use POST with the password in the request body.**

- `share-download/function.json` now declares `"methods": ["POST"]`.
- `share-download/index.js` reads `token` and `password` from `req.body`.
- `share.js` sends a `fetch` POST with `Content-Type: application/json` and the credentials as JSON in the body.
- Password verification against the bcrypt hash is unchanged.

#### Rationale
Request bodies are not logged by default by proxies, load balancers, or browser history. Moving credentials out of the URL is a minimal, zero-cost fix that eliminates a concrete logging exposure.

---

## GitHub Actions Workflow Permissions Scoped to Job Level

**Author:** Valerie (DevOps)  
**Date:** 2026-05-11  
**Issue:** #10 ([LOW] Deploy workflow permissions are broader than necessary)  
**Severity:** Security hardening (least-privilege principle)

### Problem

The `.github/workflows/deploy.yml` in `raininggraces-photos` granted `pull-requests: write` at the workflow level:

```yaml
permissions:
  contents: read
  pull-requests: write
```

This meant **every job and every event** received both scopes, even when not needed. For example:
- The `close_pull_request_job` (which only closes SWA preview environments) has no business writing to pull requests
- Push events (which skip PR-related jobs entirely) still had `pull-requests: write` available

### Solution

Moved permissions to job level:

1. **`build_and_deploy_job`** — receives `contents: read` + `pull-requests: write`
   - Needs `contents: read` for checkout
   - Needs `pull-requests: write` because the SWA action may post comments/status updates to the PR

2. **`close_pull_request_job`** — receives `contents: read` only
   - Needs `contents: read` for any potential action requirements
   - Does NOT need `pull-requests: write` (the SWA action only closes the environment; it doesn't comment)

3. Workflow-level `permissions:` block removed entirely

### Impact

- **Security posture:** Reduced blast radius if a workflow job is compromised — attackers cannot write to PRs from jobs that don't need that capability
- **Compliance:** Follows GitHub's least-privilege principle for token scopes
- **No functional change:** SWA deployment and PR preview behavior remain identical

### Verification

Both jobs continue to work as expected:
- Push events run `build_and_deploy_job` with both scopes (SWA deployment succeeds)
- PR events run both jobs with appropriate scopes (SWA deployment + preview + cleanup)
- PR close events run `close_pull_request_job` with `contents: read` only (preview environment closed)

---

**Reference:** Commits c5d7312 (Inigo), ef8d6f1 (Inigo), ab39ccd (Valerie)  
**Branch:** squad/security-hardening

---

## Health Endpoint Hardening & API Error Sanitization

**Author:** Inigo  
**Date:** 2026-05-11T15:12:15-05:00  
**Closes:** Issues #8 and #9 (MEDIUM security)  
**Branch:** squad/security-hardening

### Issue #8 — Health endpoint stripped to minimal signal

`/api/health` previously returned:
- `storageConnectionStringConfigured` (bool) — reveals infrastructure state
- `error.message` from `ensureStorageReady()` — leaks internal exception text

**Decision:** Keep the endpoint anonymous (uptime monitoring compatible) but return **only**:
- `{ "status": "ok" }` — 200
- `{ "status": "error" }` — 503

Full diagnostics (missing env var, storage exception text) are logged server-side via `context.log.error`.

### Issue #9 — Generic client-safe error messages everywhere

Three sources of internal leakage fixed:

| File | Before | After |
|---|---|---|
| `api/helpers/auth.js` `wrapHandler` | `error?.message` in 500 response | `'Internal server error.'` always |
| `api/helpers/storage.js` `confirmPhotoUploads` | `error.message` per failed photo | `'Upload confirmation failed.'`; real cause logged with `photoId` |
| `api/cleanup-run/index.js` | 500 + config disclosure when `CLEANUP_API_KEY` missing | 401 `'Unauthorized.'` for both missing and wrong key; missing-key case logged server-side |

**Rule going forward:** Any new API path that catches an exception must log the full error via `context.log.error` or `console.error` and return a static, generic string to the client. Never interpolate `error.message` into a response body.

---

**Reference:** Commits ac9f8ee (Inigo), e4ac1b7 (Inigo)  
**Branch:** squad/security-hardening
