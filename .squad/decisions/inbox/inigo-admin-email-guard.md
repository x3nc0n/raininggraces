# Inigo Decision: Admin Email Guard

- **Author:** Inigo
- **Date:** 2026-05-10T13:05:12-05:00

## Decision

In addition to SWA's `authenticated` role checks, the photo API supports an `ADMIN_EMAIL` app setting. When set, admin endpoints reject authenticated callers whose principal email does not match the configured address.

## Why

The architecture notes that Robin may be the only user in the tenant, but also recommends verifying the caller email for extra safety. Making this an app-setting guard keeps the default SWA flow simple while allowing a tighter production lock without code changes.

## Impact

- Valerie should include `ADMIN_EMAIL` in deployment configuration for the photo app.
- Fezzik can rely on `401/403` responses for admin-only frontend flows.
