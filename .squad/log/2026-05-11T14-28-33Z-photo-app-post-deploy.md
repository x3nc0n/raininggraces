# Session Log: 2026-05-11T14-28-33Z Photo App Post-Deploy

**Session ID:** 2026-05-11T14-28-33Z-photo-app-post-deploy  
**Duration:** Post-deployment team coordination  
**Agents:** valerie-8, vizzini-1, inigo  

## Summary

Post-deployment session following photo app SWA provisioning and initial testing. Valerie completed admin invite and CLEANUP_API_KEY setup. Vizzini ran P0 smoke tests and identified 2 failures. Inigo tasked with implementing both fixes.

## Outcomes

- ✅ Robin invited as admin to photo app (link expires May 18)
- ✅ CLEANUP_API_KEY generated, configured in SWA and GitHub Actions
- ✅ P0 smoke tests: 13/15 passed
- ⚠️ 2 critical/high failures logged as architectural decisions
- 🔄 Inigo now fixing /admin auth and rate-limiting persistence

## Decisions Logged

1. `az staticwebapp users invite` requires `--domain` parameter (lookup first)
2. P0 Smoke Test Failures: /admin auth, rate-limiting cross-instance issue

## Blockers Resolved

- Admin invite required domain lookup — documented for future use
- Rate-limiting cross-instance behavior identified — persistent counter design needed
