# Decisions: SWA /admin Exact Route + Persistent Rate Limiting

**Author:** Inigo  
**Date:** 2026-05-11  
**Status:** Implemented and deployed

---

## Decision 1: SWA `/admin` exact route required alongside `/admin/*`

Azure Static Web Apps route matching is first-match-wins. The wildcard pattern `/admin/*` does **not** match the bare path `/admin` — that falls through to `navigationFallback`, serving the dashboard HTML to unauthenticated users.

**Ruling:** Always add an exact `/admin` route entry **before** the `/admin/*` wildcard entry in `staticwebapp.config.json`, with identical `allowedRoles`. This is a general SWA pattern: for every wildcard-protected section, pair it with an exact route for the root path.

**Impact:** Vizzini should add a P0 test case: `GET /admin` (no trailing slash) must return 401 for unauthenticated users.

---

## Decision 2: Rate limiting must use Azure Table Storage, not in-memory Maps

Azure Functions on Consumption plan spins up multiple instances; in-memory state does not persist across them. The 5-attempt/minute IP rate limit on `/api/share/{token}/verify` was implemented as an in-memory `Map` and therefore never triggered on multi-instance deployments.

**Ruling:** Rate limit counters are stored in the `ratelimits` Azure Table Storage table (same `straininggraces` storage account as albums/photos):
- PartitionKey: `ratelimit`
- RowKey: sanitized IP address (chars `/`, `\`, `#`, `?` replaced with `-`)
- Fields: `count` (integer), `windowStart` (ISO timestamp string)
- Window: 60 seconds, max 5 attempts
- On window expiry: reset counter (opportunistic cleanup on read)

Implementation lives in `api/helpers/storage.js` alongside all other storage helpers. `share-verify/index.js` imports `isRateLimited`, `registerFailedAttempt`, `resetRateLimit` from there.

**Impact:** The `ratelimits` table is created automatically on first cold start via `ensureStorageReady()`. No Azure provisioning changes needed.
