# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Completed full architecture document at `docs/architecture.md`. Two Azure SWA Free tier apps: main Jekyll site + photo sharing app. Total cost ~$0.04/month (storage only). All compute is free tier.
- **2026-05-10:** SWA Free tier managed Functions only support HTTP triggers — no Timer triggers. Designed GitHub Actions cron for 30-day photo cleanup instead, with Blob lifecycle policy as belt-and-suspenders backup.
- **2026-05-10:** Current site: 34 images (~9 MB), 4 blog posts, 18 client testimonials. Well under SWA Free 250 MB app size limit.
- **2026-05-10:** Chose SWA built-in Entra ID auth over custom MSAL — zero code, sufficient for single-admin use case.
- **2026-05-10:** Photo app should be a separate repo (`raininggraces-photos`) — independent deployment from main site.
- **2026-05-10:** Current site uses Netlify (netlify.toml in repo root). Build: `jekyll build --future`, publish dir: `_site`, Ruby 3.2/3.3.3, Node 22.
- **2026-05-10:** Region choice: South Central US (closest to OKC). Storage: Standard LRS (cheapest, photos are temporary).
