# Squad Decisions

## Active Decisions

### 2026-05-10: Azure Architecture for Raining Graces (PROPOSED)

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
9. South Central US region (closest to OKC)

**Impact:** All team members should read `docs/architecture.md`. Inigo/Fezzik: independent tracks. Valerie: two workflows needed. Vizzini: test SWA config and endpoints.

**Artifacts:** `docs/architecture.md` (full architecture with diagrams, cost tables, auth flows, data model, API design)

---

### 2026-05-10: Photo Expiration Policy

**By:** John Spaid (via Copilot)  
**Date:** 2026-05-10

Photos and share links should auto-expire and be deleted 30 days after upload. Cost is the #1 factor for this project — policy prevents ever-expanding blob storage usage.

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
