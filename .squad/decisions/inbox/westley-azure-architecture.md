# Decision: Azure Architecture for Raining Graces

**Author:** Westley
**Date:** 2026-05-10
**Status:** PROPOSED

## Summary

Designed full architecture for migrating Jekyll site from Netlify to Azure Static Web Apps (Free) and a new photo sharing app. Total estimated cost: ~$0.04/month.

## Key Decisions

1. **Two Azure SWA Free tier apps** — main site + photo app. $0/month each.
2. **SWA built-in Entra ID auth** over custom MSAL — zero code, zero maintenance.
3. **Azure Table Storage** over Cosmos DB — included with Storage Account, sufficient for ~100 records.
4. **Standard LRS storage** — photos are temporary (30-day retention), originals on Robin's device.
5. **Separate repo** (`raininggraces-photos`) for the photo app — independent deployments.
6. **Direct-to-blob upload** via SAS tokens — avoids Function payload limits.
7. **GitHub Actions cron** for 30-day cleanup — SWA Free managed Functions don't support Timer triggers.
8. **Keep DNS at current registrar** — saves $0.50/month vs Azure DNS.
9. **South Central US region** — closest to OKC.

## Impact

- All team members should read `docs/architecture.md` before starting implementation.
- Inigo/Fezzik: implementation tracks are independent (main site migration vs photo app).
- Valerie: CI/CD needs two workflows — SWA deploy for main site, separate repo for photo app.
- Vizzini: test strategy should cover SWA config routing and API endpoints.

## Artifacts

- `docs/architecture.md` — full architecture document with diagrams, cost tables, auth flows, data model, API design.
