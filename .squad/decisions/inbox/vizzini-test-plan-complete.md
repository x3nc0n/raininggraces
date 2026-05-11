# Decision: Test Plan Complete (Vizzini)

**Date:** 2026-05-10  
**Author:** Vizzini (Tester)  
**Status:** Complete  

## What

Created comprehensive test plan at `docs/test-plan.md` covering both workloads (Jekyll migration + photo app).

## Scope

- **148 test cases** organized by category and priority (P0–P3)
- **Main Site Migration (10 tests):** Jekyll build, html-proofer, SWA config, 404 handling, SSL/custom domain
- **Photo App API (13 tests):** Album CRUD, upload flow, share link verification, SAS token generation
- **Security (8 tests):** Auth enforcement, UUID unguessability, SAS expiry, blob privacy, cleanup API key validation
- **Rate Limiting (2 tests):** 5 attempts/minute/IP on verify endpoint
- **Cleanup & Retention (7 tests):** 30-day expiry, cleanup deletes only expired albums, blob lifecycle policy backup
- **Edge Cases (12 tests):** Empty albums, large files, special characters, concurrent uploads, missing data
- **Integration & Smoke (4 tests):** End-to-end workflows, independence of deployments
- **Performance (2 tests):** Large file upload speed, album list performance (P3)

## Success Criteria

**Release blockers (100% must pass):**
- All 21 P0 tests (critical: build, auth, upload, cleanup, retention, end-to-end)
- 95% of 19 P1 tests (core functionality, admin workflows)
- Jekyll build + html-proofer validation
- SSL certificates valid at both domains

**Nice-to-have (80% P2 pass acceptable):**
- Edge cases, rate limiting, performance

## Key Assumptions

1. Implementation follows architecture doc (Section 9 API design)
2. Rate limiting implemented as per architecture (in-memory counter, 5/min/IP)
3. 30-day retention strictly enforced (30 days from album creation → expiry)
4. SAS tokens: 15 min upload, 1 hour download (per architecture)
5. Cleanup runs daily via GitHub Actions cron
6. Blob lifecycle policy set to 31-day delete (backup)
7. Tests may require time manipulation for 30-day scenarios (seed old album records)

## Testing Phase Order

1. **Jekyll + SWA config** (MS-001 through MS-010) — must pass before DNS cutover
2. **Photo API happy path** (PA-001 through PA-009) — validates core endpoints
3. **Security & auth** (SEC-001 through SEC-008, PA-012/PA-013) — validates access control
4. **Cleanup & retention** (CLEANUP-001 through CLEANUP-005, RETENTION-001/RETENTION-002) — validates cost control
5. **Edge cases & integration** (EDGE-*, INTEGRATION-*) — robustness
6. **Performance** (PERF-*) — optional, if SLA is critical

## Next Steps

- **Inigo/Fezzik:** Implement photo app API per architecture
- **Valerie:** Deploy both SWA instances, verify workflows
- **Vizzini:** Execute test plan as implementation is ready
- **All:** Review test plan for accuracy against implemented API

## Handoff Notes

This test plan is **proactive** — test cases are written before full implementation, based on architecture doc. Some adjustments may be needed once APIs are live. Plan is ready for execution immediately when photo app deploys to test environment.

---

**Status:** Ready for Development  
**Audience:** Full squad (Westley, Inigo, Fezzik, Valerie, John Spaid)
