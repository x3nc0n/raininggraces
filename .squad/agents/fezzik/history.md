# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Architecture document available at `docs/architecture.md`. Photo app build is independent implementation track from main site migration. Read architecture doc and design patterns before starting implementation.
- **2026-05-11T11:00:34.012-05:00:** `raininggraces-photos/src/assets/js/admin.js` rebuilds admin album cards from `state` inside `renderAlbums()` and relies on delegated document events, so new per-card controls should keep their UI state in `state` instead of depending on ad hoc DOM mutations.
