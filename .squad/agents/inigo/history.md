# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Architecture document available at `docs/architecture.md`. Main site migration (Jekyll → SWA) is independent implementation track from photo app. Read architecture doc before starting work.
- **2026-05-11 (post-deploy):** P0 smoke test results: 13/15 passed. Two failures requiring fixes: (1) CRITICAL — /admin route not protected in `staticwebapp.config.json` (add `"allowedRoles": ["authenticated"]`); (2) HIGH — rate-limiting not persisting across Function instances (design persistent counter in Azure Table Storage). Both fixes needed before smoke tests pass. See `.squad/decisions.md` for detailed test results and recommended solutions.
- **2026-05-11:** SWA route matching is first-match-wins. `/admin/*` does NOT match the bare `/admin` path — always add an exact `/admin` route before the wildcard. Both routes should have identical `allowedRoles`.
- **2026-05-11:** Rate limiting on Azure Functions Consumption plan must use persistent storage (Azure Table Storage) not in-memory Maps. Used `ratelimits` table with PartitionKey=`ratelimit`, RowKey=sanitized-IP. Rate limit functions (`isRateLimited`, `registerFailedAttempt`, `resetRateLimit`) live in `api/helpers/storage.js` alongside all other Table Storage helpers.
- **2026-05-11 (post-fix):** Implemented both security fixes: (1) added exact `/admin` route in staticwebapp.config.json; (2) migrated rate limit counters to Azure Table Storage with automatic table creation on cold start. Both fixes committed and pushed. Decisions documented in `.squad/decisions.md`.
- **2026-05-11T10:53:11.105-05:00:** In `raininggraces-photos\api\helpers\storage.js`, Azure Data Tables SDK v13 entities returned from `getEntity()`/`listEntities()` use camelCase `partitionKey`/`rowKey`. Normalizers for albums/photos must accept both camelCase SDK responses and PascalCase entities built locally before `createEntity()`.
- **2026-05-11T11:00:34.012-05:00:** Album records in `raininggraces-photos` now store both `passwordHash` (bcrypt verification) and `passwordPlain` (admin retrieval/reset). Never expose either field in album list responses; only dedicated admin-only password endpoints should read/write the plaintext value.
- **2026-05-11T15:05:08.870-05:00:** Removed plaintext password storage (#6). `passwordPlain` is gone from all storage operations. Only `passwordHash` is persisted. `albums-password-get` endpoint deleted. Create and reset endpoints now return the plaintext password once in their response for show-once display in the admin UI. Never store or re-fetch plaintext credentials from Table Storage.
- **2026-05-11T15:05:08.870-05:00:** Download-all flow fixed (#7). `POST /api/share-download` now reads `token` and `password` from the request body. The old `GET ?password=...` query-string pattern is gone. Always use POST body for credentials — never query strings.
- **2026-05-11T20:12:17Z (Scribe team update):** Both issues (#6 and #7) decisions archived to `.squad/decisions.md`. Commits c5d7312 and ef8d6f1 logged. Ready for code review and PR merge to `main`.
