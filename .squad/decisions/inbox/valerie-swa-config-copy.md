### 2026-05-10T13:05:12-05:00: SWA config deployment handling
**By:** Valerie
**What:** The new main-site Azure Static Web Apps workflow keeps `staticwebapp.config.json` in the repo root for maintainability, then copies it into `_site/` before deployment because the workflow uploads prebuilt Jekyll output with `skip_app_build: true`.
**Why:** Azure SWA expects the config file in the deployed artifact when app build is skipped. This preserves the architecture's repo-root config while making routing, headers, and 404 handling actually reach Azure.
