# Project Context

- **Owner:** John Spaid
- **Project:** Raining Graces Birth Services — Jekyll static site for Robin Spaid's birth doula business (OKC Metro). Migrating from Netlify to Azure Static Web Apps. Building a new photo sharing app for birth photos with Entra ID auth and client album sharing.
- **Stack:** Jekyll, Bulma 0.8.2, SCSS, GitHub Actions, Azure Static Web Apps, Azure Functions, Azure Blob Storage, Entra ID / MSAL
- **Created:** 2026-05-10

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

- **2026-05-10:** Architecture document available at `docs/architecture.md`. CI/CD requires two workflows: (1) SWA deploy for main Jekyll site, (2) separate deployment for photo app repo. See architecture doc for SWA Free tier limitations and GitHub Actions cron setup for 30-day photo cleanup.
- **2026-05-10T13:05:12-05:00:** Phase 1 main-site migration uses branch `azure-migration`, adds repo-root `staticwebapp.config.json`, and introduces `.github/workflows/azure-swa-deploy.yml` while leaving `.github/workflows/jekyll.yml` and `netlify.toml` unchanged until DNS cutover.
- **2026-05-10T13:05:12-05:00:** Because the Azure workflow deploys a prebuilt `_site/` directory with `skip_app_build: true`, it must copy `staticwebapp.config.json` into `_site/` before calling `Azure/static-web-apps-deploy@v1`.
