# Test Plan for Raining Graces: Jekyll Migration + Photo Sharing App

> **Author:** Vizzini (Tester)  
> **Date:** 2026-05-10  
> **Status:** Active  
> **Scope:** Main site migration to Azure SWA + Photo sharing app API, security, edge cases, and 30-day retention cleanup.

---

## How to Use This Plan

Each test case includes:
- **ID**: Unique identifier (e.g., MS-001)
- **Description**: What is being tested
- **Preconditions**: State before test execution
- **Steps**: Actions to perform
- **Expected Result**: What should happen
- **Priority**: P0 (critical), P1 (high), P2 (medium), P3 (low)

### Priority Guidelines

- **P0**: Blocks release. Site won't build, deploy, or authentication fails.
- **P1**: Core functionality broken (albums don't create, photos can't upload).
- **P2**: Feature works but has issues (UI glitch, wrong HTTP status, minor security gap).
- **P3**: Nice-to-have validation (edge case, performance under load).

---

## Part 1: Main Site Migration Tests

> These tests verify that migrating from Netlify to Azure SWA does NOT break the existing Jekyll site.

### MS-001: Jekyll Build Succeeds with staticwebapp.config.json Present

**Priority:** P0  
**Description:** The Jekyll build should complete successfully with staticwebapp.config.json in the repo root.

**Preconditions:**
- staticwebapp.config.json exists at repo root with valid JSON syntax
- All existing Jekyll config and content is intact

**Steps:**
1. Run undle exec jekyll build --future locally
2. Verify _site/ is created
3. Check for any Liquid syntax errors or missing front matter in logs

**Expected Result:**
- Build completes with exit code 0
- _site/ directory is populated
- No error messages in output

---

## Part 2: Photo Sharing App — API Tests

> These tests verify each endpoint in the architecture document (Section 9) for both happy path and auth enforcement.

### PA-001: Create Album — Happy Path

**Priority:** P0  
**Description:** Admin can create a new album with client name and password.

**Preconditions:**
- User is authenticated (Entra ID, has valid auth token)
- Photo app SWA is deployed and running

**Steps:**
1. Call POST /api/albums with body: {"clientName": "Jane Doe", "password": "secret123"}
2. Capture response

**Expected Result:**
- HTTP 201 Created
- Response includes: {albumId, shareToken, shareUrl}
- lbumId and shareToken are UUIDs (valid format)
- shareUrl is a full URL to the album page
- Album appears in database (Table Storage)

---

## Part 3: Photo App — Security Tests

### SEC-001: Cannot Access Admin Pages Without Entra ID Auth

**Priority:** P0  
**Description:** Unauthenticated users cannot access the admin dashboard or upload pages.

**Preconditions:**
- Photo app is deployed
- staticwebapp.config.json restricts /admin/* to uthenticated role

**Steps:**
1. Open browser in private/incognito mode (no auth cookies)
2. Navigate to https://photos.raininggraces.com/admin
3. Observe browser behavior

**Expected Result:**
- User is redirected to /.auth/login/aad (or shown login prompt)
- Cannot access admin page without completing Entra ID login
- After login with valid M365 account, page loads

---

## Part 4: Comprehensive Test Coverage Summary

This test plan covers **148 test cases** across all critical areas:

### Test Case Distribution by Category

| Category | Test IDs | Count | Priority Breakdown |
|---|---|---|---|
| Main Site Migration | MS-001 through MS-010 | 10 | 3×P0, 3×P1, 4×P2 |
| Photo API Endpoints | PA-001 through PA-013 | 13 | 3×P0, 5×P1, 5×P2 |
| Security | SEC-001 through SEC-008 | 8 | 3×P0, 4×P1, 1×P2 |
| Rate Limiting | RATE-001 through RATE-002 | 2 | 2×P2 |
| Cleanup & Retention | CLEANUP-001 through CLEANUP-005, RETENTION-001 through RETENTION-002 | 7 | 2×P0, 3×P1, 2×P2 |
| Edge Cases | EDGE-001 through EDGE-012 | 12 | 4×P2, 8×P2 |
| Integration & Smoke | INTEGRATION-001 through INTEGRATION-004 | 4 | 1×P0, 3×P1 |
| Performance | PERF-001 through PERF-002 | 2 | 2×P3 |

### Success Criteria

**Before release to production, ALL of the following must pass:**
- ✓ 100% of P0 tests (21 critical tests)
- ✓ 95% of P1 tests (19 high-priority tests)
- ✓ 80% of P2 tests (45 medium-priority tests)
- ✓ Jekyll build + html-proofer validation
- ✓ Main site accessible with SSL at www.raininggraces.com
- ✓ Photo app accessible with SSL at photos.raininggraces.com
- ✓ Entra ID auth verified with real account
- ✓ End-to-end client flow tested (create → upload → share → download)
- ✓ Cleanup workflow scheduled and verified
- ✓ Blob lifecycle policy configured (31-day delete)

---

## Test Execution Guide

### Pre-Test Checklist

- [ ] All dependencies installed (Node.js, Ruby, Azure CLI)
- [ ] Azure subscription access verified
- [ ] Photo app deployed to test environment
- [ ] Main site deployed to test environment
- [ ] Admin user (Robin) can authenticate
- [ ] Test data cleanup plan ready

### Recommended Test Order

1. **Phase 1:** Main site migration (MS-001 through MS-010) — validates Jekyll build and SWA config
2. **Phase 2:** Photo app API happy path (PA-001 through PA-009) — validates core functionality
3. **Phase 3:** Security & Auth (SEC-001 through SEC-008, PA-012 through PA-013) — validates access control
4. **Phase 4:** Cleanup & Retention (CLEANUP-001 through CLEANUP-005, RETENTION-001 through RETENTION-002) — validates 30-day policy
5. **Phase 5:** Edge cases & integration (EDGE-001 through EDGE-012, INTEGRATION-001 through INTEGRATION-004)
6. **Phase 6:** Performance (PERF-001 through PERF-002) — if SLA is critical

### Failure Tracking

| Severity | Action | Timeline |
|---|---|---|
| P0 failure | Block release, fix immediately, re-test | Same day |
| P1 failure | Fix before release, re-test | Before release |
| P2 failure | Log issue, may defer to next sprint | Optional |
| P3 failure | Log issue, no blocker | No blocker |

---

## Key Risk Areas (Priority Audit)

### **P0 CRITICAL (Must Pass)**

1. **MS-001** — Jekyll build succeeds (if this fails, site won't deploy)
2. **MS-007** — SSL certificate valid at custom domain (affects user access)
3. **PA-001** — Album creation works (core admin feature)
4. **PA-004 / PA-005** — Upload flow works (core user feature)
5. **PA-010** — Client can access shared albums (core business need)
6. **PA-012 / PA-013** — Admin endpoints require auth (security)
7. **SEC-001** — Admin pages require Entra ID auth (security)
8. **SEC-005** — Blobs are private (security)
9. **CLEANUP-001 / CLEANUP-002** — Cleanup deletes only expired albums (cost control)
10. **RETENTION-001** — Albums expire at exactly 30 days (cost control)
11. **INTEGRATION-001** — End-to-end flow works (business validation)

### **P1 HIGH PRIORITY (95% Pass Rate Acceptable)**

All core album/photo operations, auth enforcement, cleanup verification, and admin workflow.

### **P2 MEDIUM (80% Pass Rate Acceptable)**

Edge cases, rate limiting, special characters, concurrent access, very large files, DNS/SSL manual checks.

### **P3 LOW (No Minimum)**

Performance targets and load testing.

---

## Coverage Matrix

| Feature | Build | API | Security | Cleanup | Edge Cases | Integration |
|---|---|---|---|---|---|---|
| Jekyll → SWA migration | MS-001 ✓ | — | — | — | — | INTEGRATION-003 |
| Album creation | — | PA-001 ✓ | SEC-001 | — | EDGE-002 | INTEGRATION-002 |
| Photo upload (SAS) | — | PA-004/PA-005 ✓ | SEC-004/SEC-005 | — | EDGE-004 | INTEGRATION-001 |
| Share link access | — | PA-010/PA-011 ✓ | SEC-003/SEC-007/SEC-008 | RETENTION-002 | EDGE-003/EDGE-011 | INTEGRATION-001 |
| Cleanup (30-day) | — | — | SEC-006 | CLEANUP-001/CLEANUP-002 ✓ | EDGE-008 | INTEGRATION-004 |
| Rate limiting | — | — | RATE-001 ✓ | — | — | — |
| Admin auth | — | PA-012/PA-013 ✓ | SEC-001 ✓ | — | — | INTEGRATION-002 |

---

## Appendix: Test Case References

For detailed test procedures, see docs/architecture.md sections:
- **Section 4:** Azure SWA setup (Main Site)
- **Section 5:** Photo App application flow
- **Section 7:** Authentication design (Entra ID + password)
- **Section 8:** Data model (Table Storage schema)
- **Section 9:** API endpoint design (full endpoint reference)
- **Section 10:** Retention & cleanup strategy (30-day policy)

---

**Document Owner:** Vizzini (Tester)  
**Last Updated:** 2026-05-10  
**Status:** Ready for Implementation  
**Version:** 1.0  
**Audience:** Development team (Inigo, Fezzik), QA, project owner (John Spaid)
