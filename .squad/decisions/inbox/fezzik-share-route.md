# Team Decision Inbox

- **Author:** Fezzik
- **Date:** 2026-05-10T13:05:12-05:00
- **Topic:** Standardize photo share route

## Context

The photo frontend is implemented as static pages under `raininggraces-photos/src/`, with a client viewer at `/share/{shareToken}` and an admin dashboard at `/admin/`.

## Proposed Decision

Standardize public album links on `/share/{shareToken}` and have the API/helper-generated `shareUrl` values use that same route. Also keep a dedicated SWA rewrite rule for `/share/*` to serve `src/share/index.html`.

## Why It Matters

This keeps generated share links, frontend routing, and Static Web Apps behavior aligned so families land directly in the password screen without a broken SPA fallback.
