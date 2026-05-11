# Raining Graces — Azure Architecture Document

> **Author:** Westley (Lead/Architect)
> **Date:** 2026-05-10
> **Status:** PROPOSED — awaiting team review
> **Cost Priority:** FREE TIER FIRST. Every dollar must be justified.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State](#2-current-state)
3. [Architecture Overview](#3-architecture-overview)
4. [Component 1: Main Site (Jekyll → Azure SWA)](#4-component-1-main-site-jekyll--azure-swa)
5. [Component 2: Photo Sharing App](#5-component-2-photo-sharing-app)
6. [Azure Resource Inventory & Cost Estimates](#6-azure-resource-inventory--cost-estimates)
7. [Authentication Design](#7-authentication-design)
8. [Data Model](#8-data-model)
9. [API Endpoint Design](#9-api-endpoint-design)
10. [Retention & Cleanup Strategy](#10-retention--cleanup-strategy)
11. [Branch Strategy](#11-branch-strategy)
12. [Migration Runbook](#12-migration-runbook)
13. [Risks & Mitigations](#13-risks--mitigations)
14. [Decision Log](#14-decision-log)

---

## 1. Executive Summary

Two independent workloads on Azure, both targeting $0/month under normal usage:

| Workload | Azure Resources | Expected Monthly Cost |
|---|---|---|
| Main doula site (Jekyll) | Azure Static Web Apps (Free) | **$0.00** |
| Photo sharing app | Azure SWA (Free) + Azure Blob Storage + Azure Functions (Consumption) | **~$0.01–$0.10** (storage only; compute free) |

**Total estimated cost: under $0.15/month.** The VS subscription $150/month credits are not needed for steady-state operation but serve as a safety net for any unexpected overages.

---

## 2. Current State

### Site Inventory

| Item | Detail |
|---|---|
| Generator | Jekyll (Ruby 3.3.3) |
| CSS framework | Bulma 0.8.2 (CDN) |
| Blog posts | 4 |
| Client testimonials | 18 |
| Static images | 34 files, ~9 MB total |
| Build output | `_site/` directory |
| Current host | Netlify (free tier) |
| CI/CD | GitHub Actions → build + html-proofer |
| Custom domain | `www.raininggraces.com` |
| Build command | `jekyll build --future` |
| Publish directory | `_site` |

### Current Deployment Flow

```
push to master → GitHub Actions → jekyll build → html-proofer
                                       ↓
                              Netlify picks up _site/ and deploys
```

Netlify config (`netlify.toml`):
- Publish dir: `_site`
- Build command: `jekyll build --future`
- Ruby 3.2, Node 22

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AZURE ARCHITECTURE                          │
├──────────────────────────────┬──────────────────────────────────────┤
│   MAIN SITE (Jekyll)        │   PHOTO SHARING APP                  │
│                              │                                      │
│   ┌──────────────────────┐  │   ┌──────────────────────────────┐   │
│   │  Azure Static Web    │  │   │  Azure Static Web App #2     │   │
│   │  Apps (Free)         │  │   │  (Free tier)                 │   │
│   │                      │  │   │                              │   │
│   │  - Jekyll _site/     │  │   │  - SPA (HTML/CSS/JS)         │   │
│   │  - Custom domain     │  │   │  - Built-in Entra ID auth    │   │
│   │  - Free SSL          │  │   │  - Managed Functions API     │   │
│   └──────────┬───────────┘  │   └──────────────┬───────────────┘   │
│              │               │                  │                    │
│   GitHub Actions (CI/CD)    │   ┌──────────────┴───────────────┐   │
│              │               │   │  Azure Functions             │   │
│   ┌──────────┴───────────┐  │   │  (Managed, included in SWA)  │   │
│   │  GitHub repo         │  │   │                              │   │
│   │  master branch       │  │   │  - Album CRUD                │   │
│   └──────────────────────┘  │   │  - Photo upload (SAS tokens) │   │
│                              │   │  - Share link generation     │   │
│                              │   │  - Client auth (password)    │   │
│                              │   │  - Cleanup trigger           │   │
│                              │   └──────────────┬───────────────┘   │
│                              │                  │                    │
│                              │   ┌──────────────┴───────────────┐   │
│                              │   │  Azure Blob Storage          │   │
│                              │   │  (Standard LRS, Hot tier)    │   │
│                              │   │                              │   │
│                              │   │  - Photo blobs               │   │
│                              │   │  - Album metadata (Table)    │   │
│                              │   └──────────────────────────────┘   │
│                              │                                      │
│   ┌──────────────────────────┴──────────────────────────────────┐   │
│   │                    Entra ID (M365 E5)                       │   │
│   │                    Robin's existing tenant                  │   │
│   │                    App registration (free)                  │   │
│   └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

**Key design principle:** These are two completely independent deployments. The main site has zero dependency on the photo app. If the photo app breaks, the business site stays up.

---

## 4. Component 1: Main Site (Jekyll → Azure SWA)

### What Changes

| Aspect | Netlify (current) | Azure SWA (target) |
|---|---|---|
| Hosting | Netlify Free | Azure SWA Free |
| Build | Netlify builds OR GitHub Actions | GitHub Actions only |
| SSL | Automatic | Automatic |
| Custom domain | Netlify DNS | Azure SWA + DNS update |
| CDN | Netlify Edge | Azure global POP |
| Cost | $0 | $0 |

### Azure SWA Free Tier Limits vs Our Usage

| Limit | Free Tier Allows | Our Usage | Fits? |
|---|---|---|---|
| Apps per subscription | 10 | 2 (site + photo app) | ✅ |
| Storage (app size) | 250 MB | ~9 MB images + ~2 MB HTML | ✅ |
| Bandwidth | 100 GB/month | ~1–5 GB (low-traffic local business) | ✅ |
| Custom domains | 2 per app | 1 (`www.raininggraces.com`) | ✅ |
| SSL certificates | Free (managed) | 1 | ✅ |
| Staging environments | 3 | 1–2 (PR previews) | ✅ |
| API (managed Functions) | Included | Not needed for main site | ✅ |

**Verdict: Comfortably within free tier.** A local doula business won't approach 100 GB bandwidth.

### GitHub Actions Workflow for SWA

The existing `jekyll.yml` workflow stays for build + html-proofer. A new workflow deploys to Azure SWA using the official `Azure/static-web-apps-deploy@v1` action. This action receives the pre-built `_site/` directory.

### staticwebapp.config.json

Place in repo root. Azure SWA uses this for routing, headers, and error pages:

```json
{
  "navigationFallback": null,
  "responseOverrides": {
    "404": {
      "rewrite": "/404.html"
    }
  },
  "globalHeaders": {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff"
  }
}
```

No `navigationFallback` — this is a static site with real file paths, not a SPA.

---

## 5. Component 2: Photo Sharing App

### Requirements Recap

1. Robin logs in (Entra ID) → creates album → sets simple password → uploads photos
2. System generates share link per album
3. Client visits link → enters password → views/downloads photos
4. Everything auto-deletes after 30 days

### Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Frontend | Vanilla HTML/CSS/JS (or lightweight framework like Alpine.js) | No build step, fits SWA free tier, simple enough |
| API | Azure Functions (Node.js, managed by SWA) | Free with SWA, serverless, no infrastructure |
| Storage | Azure Blob Storage + Azure Table Storage | Cheapest option, Table Storage is included with Storage Account |
| Auth (admin) | Azure SWA built-in Entra ID auth | Zero code, free, simpler than MSAL |
| Auth (client) | Simple password check via API | No accounts, no auth provider needed |
| Cleanup | Azure Function on timer trigger | Free tier, runs daily |

### Application Flow

```
ADMIN FLOW (Robin):
═══════════════════

Browser ──► SWA (/.auth/login/aad) ──► Entra ID ──► redirect back
                                                         │
Robin sees dashboard                                     │
   │                                                     │
   ├── Create Album ──► POST /api/albums ──► Table Storage (album record)
   │                         │
   │                         └──► Returns: albumId, shareLink, shareUrl
   │
   ├── Upload Photos ──► POST /api/albums/{id}/photos ──► generates SAS token
   │                         │
   │                         └──► Client JS uploads direct to Blob Storage
   │                              (skips the Function for large files)
   │
   └── View/Manage Albums ──► GET /api/albums ──► returns all albums


CLIENT FLOW (photo viewer):
═══════════════════════════

Client receives link:  https://photos.raininggraces.com/album/{shareToken}
   │
   ├── Browser loads SPA page
   │
   ├── Prompt for password
   │
   ├── POST /api/share/{shareToken}/verify  ──► check password hash
   │         │
   │         ├── 401: wrong password
   │         └── 200: returns signed SAS URLs for all photos (1-hour expiry)
   │
   └── Client views/downloads photos using time-limited SAS URLs
       (photos served directly from Blob Storage, not through Function)
```

### Why Direct-to-Blob Upload?

Birth photos can be large (5–20 MB each). Routing them through an Azure Function would:
- Hit the 100 MB request limit on Consumption plan
- Waste Function execution time (cost)
- Be slow

Instead: the Function generates a short-lived SAS token, and the browser uploads directly to Blob Storage. The Function then records the blob reference in Table Storage.

---

## 6. Azure Resource Inventory & Cost Estimates

### Resource 1: Azure Static Web App — Main Site

| Property | Value |
|---|---|
| Resource type | `Microsoft.Web/staticSites` |
| SKU | Free |
| Purpose | Host Jekyll `_site/` output |
| Custom domain | `www.raininggraces.com` |
| **Monthly cost** | **$0.00** |

Free tier limits: 250 MB app size, 100 GB bandwidth, 2 custom domains, free SSL.
Our usage: ~11 MB app, <5 GB bandwidth. **Well within limits.**

### Resource 2: Azure Static Web App — Photo Sharing App

| Property | Value |
|---|---|
| Resource type | `Microsoft.Web/staticSites` |
| SKU | Free |
| Purpose | Host photo sharing SPA + managed Functions API |
| Custom domain | `photos.raininggraces.com` (or subdomain) |
| Built-in auth | Entra ID provider configured |
| **Monthly cost** | **$0.00** |

Free tier limits: Same as above. SWA Free includes managed Azure Functions.
Our usage: Tiny SPA (<1 MB), API calls only when Robin uploads or clients view. **Well within limits.**

> **Note:** SWA Free tier managed Functions are limited to HTTP triggers only and have no support for timer triggers. The cleanup function must use an alternative approach — see [Section 10: Retention & Cleanup Strategy](#10-retention--cleanup-strategy).

### Resource 3: Azure Storage Account

| Property | Value |
|---|---|
| Resource type | `Microsoft.Storage/storageAccounts` |
| SKU | Standard LRS (locally redundant) |
| Purpose | Blob Storage for photos + Table Storage for metadata |
| **Monthly cost** | **~$0.01–$0.10** (see breakdown) |

#### Storage Cost Breakdown

Assumptions based on Robin's business:
- ~2–4 births/month
- ~20–50 photos per birth (after culling)
- Average photo size: 5 MB
- Monthly new data: 100–250 photos × 5 MB = **500 MB–1.25 GB**
- 30-day retention means max storage at any time: **~1–2.5 GB**

| Cost Component | Rate | Our Usage | Monthly Cost |
|---|---|---|---|
| Blob Storage (Hot, LRS) | $0.018/GB/month | ~2 GB avg | $0.036 |
| Write operations | $0.05/10K ops | ~200 ops | $0.001 |
| Read operations | $0.004/10K ops | ~500 ops | $0.001 |
| Data egress (first 100 GB free) | $0.00 | <5 GB | $0.000 |
| Table Storage | $0.045/GB/month | <1 MB | $0.000 |
| Table operations | $0.00036/10K ops | ~500 ops | $0.000 |
| **Total** | | | **~$0.04** |

**Even in a busy month, storage cost stays under $0.10.** The 30-day auto-delete keeps this bounded.

#### Why Standard LRS?

- LRS = 3 copies within one datacenter. Cheapest redundancy option.
- These are temporary photos (30-day retention). We don't need geo-redundancy for data that auto-deletes.
- If the datacenter burns down, Robin re-uploads. The photos exist on her phone/camera.

### Resource 4: Entra ID App Registration

| Property | Value |
|---|---|
| Resource type | Entra ID App Registration |
| SKU | Free (included with M365 E5) |
| Purpose | Enable "Login with Microsoft" for Robin |
| **Monthly cost** | **$0.00** |

App registrations are free. The M365 E5 subscription already includes Entra ID P2.

### Resource 5: DNS (if moving to Azure DNS)

| Property | Value |
|---|---|
| Resource type | `Microsoft.Network/dnsZones` |
| SKU | Standard |
| **Monthly cost** | **$0.50** for the zone + $0.40/million queries |
| **Recommendation** | **SKIP — keep DNS at current registrar** |

Azure DNS costs ~$0.50/month minimum. Since the domain is already registered somewhere with DNS, just update the CNAME/A records to point to Azure SWA. No need to move DNS.

**Decision: Keep DNS at current registrar. Cost: $0.00 additional.**

### Total Monthly Cost Summary

| Resource | Monthly Cost |
|---|---|
| SWA — Main Site (Free) | $0.00 |
| SWA — Photo App (Free) | $0.00 |
| Storage Account (Blob + Table) | ~$0.04 |
| Entra ID App Registration | $0.00 |
| DNS changes | $0.00 |
| **TOTAL** | **~$0.04** |

The VS subscription $150/month credits cover this thousands of times over, but even without credits, this is effectively free.

---

## 7. Authentication Design

### Decision: Azure SWA Built-in Auth vs Custom MSAL

| Factor | SWA Built-in Auth | Custom MSAL |
|---|---|---|
| Code required | Zero — config only | 50–200 lines of MSAL.js |
| App registration | Still need one, but simpler config | Full app registration + redirect URIs |
| Token management | Handled by SWA runtime | You manage tokens, refresh, caching |
| Role-based access | Via `staticwebapp.config.json` roles | You implement it |
| Logout | Built-in `/.auth/logout` | You implement it |
| Cost | Free | Free (but more dev time) |
| Flexibility | Limited to SWA's auth model | Full control |
| User info | `/.auth/me` endpoint returns claims | Full token with all claims |

**Recommendation: Use SWA built-in auth.** It's zero code, zero maintenance, and does exactly what we need — confirm Robin is Robin. We don't need custom claims or complex token handling.

### Admin Auth Flow (Robin — Entra ID via SWA)

```
Robin opens photos.raininggraces.com/admin
         │
         ▼
┌─────────────────────────────┐
│  staticwebapp.config.json   │
│  routes: /admin/* requires  │
│  role: "authenticated"      │
└────────────┬────────────────┘
             │ (not authenticated)
             ▼
┌─────────────────────────────┐
│  SWA redirects to           │
│  /.auth/login/aad           │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  Microsoft Entra ID         │
│  login.microsoftonline.com  │
│                             │
│  Robin enters her M365      │
│  email + password (or MFA)  │
└────────────┬────────────────┘
             │ (auth code flow)
             ▼
┌─────────────────────────────┐
│  SWA receives token,        │
│  sets auth cookie            │
│  Redirects to /admin         │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  /admin page loads           │
│  JS calls /.auth/me         │
│  Confirms user identity      │
│                             │
│  API calls include auth      │
│  cookie automatically        │
└─────────────────────────────┘
```

#### Restricting Admin to Robin Only

In `staticwebapp.config.json`:

```json
{
  "auth": {
    "identityProviders": {
      "azureActiveDirectory": {
        "registration": {
          "openIdIssuer": "https://login.microsoftonline.com/{tenant-id}/v2.0",
          "clientIdSettingName": "AAD_CLIENT_ID",
          "clientSecretSettingName": "AAD_CLIENT_SECRET"
        }
      }
    }
  },
  "routes": [
    {
      "route": "/admin/*",
      "allowedRoles": ["authenticated"]
    },
    {
      "route": "/api/albums*",
      "methods": ["POST", "PUT", "DELETE"],
      "allowedRoles": ["authenticated"]
    },
    {
      "route": "/api/share/*",
      "allowedRoles": ["anonymous"]
    }
  ]
}
```

Since the Entra ID app registration is set to **single-tenant** (Robin's M365 tenant only), only users in her tenant can authenticate. If she's the only user, that's sufficient. For extra safety, the API functions verify the caller's email matches Robin's known email.

### Client Auth Flow (Photo Viewer — Password)

```
Client receives link:
  https://photos.raininggraces.com/album/a1b2c3d4

         │
         ▼
┌─────────────────────────────┐
│  SPA loads album page        │
│  Shows password prompt       │
│  (no SWA auth needed —       │
│   this route is anonymous)   │
└────────────┬────────────────┘
             │ (client enters password)
             ▼
┌─────────────────────────────┐
│  POST /api/share/a1b2c3d4   │
│  Body: { "password": "..." } │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  Azure Function:             │
│  1. Look up album by token   │
│  2. Check expiry (30 days)   │
│  3. Compare password hash    │
│  4. If match: generate SAS   │
│     URLs for all photos      │
│  5. Return photo URLs        │
│     (1-hour SAS expiry)      │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  SPA displays photos         │
│  using SAS URLs              │
│  Client can download         │
└─────────────────────────────┘
```

#### Password Security Notes

- Passwords are hashed (SHA-256 is fine — these are intentionally simple passwords, not security-critical)
- No brute-force protection needed per requirements ("simple password, not hardcore security")
- However, we add a basic rate limit: 5 attempts per minute per IP via a simple in-memory counter in the Function
- The share token itself is a UUID v4 (unguessable) — the password is a secondary check

---

## 8. Data Model

### Azure Table Storage Entities

Table Storage is schemaless and included free with the Storage Account. Two tables:

#### Table: `albums`

| Property | Type | Description |
|---|---|---|
| `PartitionKey` | string | Fixed value: `"album"` (all albums in one partition — scale is tiny) |
| `RowKey` | string | Album ID (UUID v4) |
| `clientName` | string | Client's name (for Robin's dashboard) |
| `shareToken` | string | URL-safe token for share link (UUID v4, different from RowKey) |
| `passwordHash` | string | SHA-256 hash of the simple password |
| `createdAt` | datetime | When album was created |
| `expiresAt` | datetime | `createdAt + 30 days` — used by cleanup |
| `photoCount` | int32 | Number of photos in album |

#### Table: `photos`

| Property | Type | Description |
|---|---|---|
| `PartitionKey` | string | Album ID (groups photos by album for efficient queries) |
| `RowKey` | string | Photo ID (UUID v4) |
| `blobName` | string | Blob path: `{albumId}/{photoId}.{ext}` |
| `originalFilename` | string | Original filename from upload |
| `contentType` | string | MIME type (image/jpeg, etc.) |
| `sizeBytes` | int64 | File size |
| `uploadedAt` | datetime | Upload timestamp |

### Blob Storage Structure

```
Container: photos
└── {albumId}/
    ├── {photoId-1}.jpg
    ├── {photoId-2}.jpg
    └── {photoId-3}.png
```

- One container: `photos`
- Blobs organized by album ID prefix
- Access level: Private (no public access — all access via SAS tokens)

### Why Table Storage Instead of Cosmos DB?

| Factor | Table Storage | Cosmos DB (Serverless) |
|---|---|---|
| Cost | ~$0.00/month at our scale | $0.00 RU cost, but min ~$0.25/month for storage |
| Complexity | Simple key-value, no SDK overhead | Full document model, overkill |
| Included in Storage Account | Yes | No, separate resource |
| Query capability | PartitionKey + RowKey lookups | Full SQL-like queries |
| Our needs | Lookup album by shareToken, list photos by albumId | Same |

Table Storage wins on cost and simplicity. We have ~50–100 records at any time. This is not a Cosmos DB problem.

---

## 9. API Endpoint Design

All APIs are Azure Functions (Node.js) managed by the SWA. Located in the `api/` directory of the SWA project.

### Admin Endpoints (require `authenticated` role)

| Method | Path | Description | Request Body | Response |
|---|---|---|---|---|
| `GET` | `/api/albums` | List all active albums | — | `[{albumId, clientName, photoCount, shareUrl, expiresAt}]` |
| `POST` | `/api/albums` | Create new album | `{clientName, password}` | `{albumId, shareToken, shareUrl}` |
| `DELETE` | `/api/albums/{albumId}` | Delete album + all photos | — | `204` |
| `POST` | `/api/albums/{albumId}/upload-url` | Get SAS upload URL(s) | `{files: [{name, type}]}` | `{uploadUrls: [{photoId, sasUrl}]}` |
| `POST` | `/api/albums/{albumId}/photos/confirm` | Confirm upload complete | `{photoIds: [...]}` | `200` |
| `GET` | `/api/albums/{albumId}/photos` | List photos in album | — | `[{photoId, filename, size}]` |
| `DELETE` | `/api/albums/{albumId}/photos/{photoId}` | Delete single photo | — | `204` |

### Public Endpoints (anonymous access)

| Method | Path | Description | Request Body | Response |
|---|---|---|---|---|
| `POST` | `/api/share/{shareToken}/verify` | Verify album password | `{password}` | `{albumId, clientName, photos: [{photoId, url, filename}]}` |

The `verify` response includes SAS URLs for each photo, valid for 1 hour. The client-side app uses these to render the gallery and enable downloads.

### Upload Flow (Detail)

```
1. Robin selects files in browser
2. Frontend calls POST /api/albums/{albumId}/upload-url
   with file names and types
3. Function generates one SAS URL per file (write-only, 15-min expiry)
   and creates photo records in Table Storage (status: "uploading")
4. Frontend uploads each file directly to Blob Storage via PUT to SAS URL
5. Frontend calls POST /api/albums/{albumId}/photos/confirm
   with the list of photoIds that succeeded
6. Function marks photos as "uploaded" in Table Storage
```

---

## 10. Retention & Cleanup Strategy

### The Problem with SWA Free Tier

Azure SWA Free tier managed Functions only support **HTTP triggers**. We cannot use a Timer trigger (which requires a standalone Azure Functions app on Consumption plan — also free, but adds deployment complexity).

### Recommended Approach: GitHub Actions Scheduled Cleanup

Run a GitHub Actions workflow on a daily cron schedule that calls a cleanup API endpoint:

```yaml
# .github/workflows/photo-cleanup.yml
name: Photo Cleanup
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch: {}   # Manual trigger for testing

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger cleanup
        run: |
          curl -X POST "https://photos.raininggraces.com/api/cleanup" \
            -H "x-cleanup-key: ${{ secrets.CLEANUP_API_KEY }}" \
            -H "Content-Type: application/json"
```

The cleanup endpoint is secured with a shared secret (API key in SWA app settings), not Entra ID auth, since it's called by a GitHub Action, not a browser.

### Cleanup Function Logic

```
1. Query Table Storage: albums WHERE expiresAt < now()
2. For each expired album:
   a. List all blobs with prefix {albumId}/
   b. Delete all blobs
   c. Delete all photo records from Table Storage
   d. Delete the album record from Table Storage
3. Log results (count of albums/photos deleted)
```

### Blob Lifecycle Management (Belt & Suspenders)

As a backup, configure Azure Blob Storage lifecycle management policy:

```json
{
  "rules": [
    {
      "name": "delete-old-photos",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["photos/"]
        },
        "actions": {
          "baseBlob": {
            "delete": {
              "daysAfterCreationGreaterThan": 31
            }
          }
        }
      }
    }
  ]
}
```

This catches any blobs the cleanup function missed. It's a free feature of Blob Storage — no additional cost.

### Why Not Azure Durable Functions / Durable Timers?

Durable Functions require a storage account (we have one) but also need the Durable Functions extension, which adds complexity. A simple cron-via-GitHub-Actions is more maintainable and uses GitHub Actions' free tier (2,000 minutes/month for private repos; unlimited for public).

---

## 11. Branch Strategy

### Protecting Production During Migration

```
master (current production — Netlify deploys from here)
  │
  ├── azure-migration (feature branch for main site migration)
  │     ├── Add staticwebapp.config.json
  │     ├── Add Azure SWA GitHub Actions workflow
  │     ├── Test with Azure SWA staging environment
  │     └── Merge to master only after DNS cutover plan is ready
  │
  └── photo-app (separate repo OR feature branch — see recommendation)
```

### Recommendation: Separate Repo for Photo App

The photo sharing app is a completely independent application. It should live in a separate GitHub repository:

| Aspect | Same Repo | Separate Repo (recommended) |
|---|---|---|
| Deployment coupling | SWA deploys both — risk of cross-contamination | Independent deploys |
| CI/CD | Shared workflow, need path filters | Clean separation |
| Codebase clarity | Mixed Jekyll + SPA | Each repo has one purpose |
| SWA configuration | Can only have one `staticwebapp.config.json` | Each app has its own |
| Team workflow | PRs touch unrelated files | Clean PRs |

**Decision: Create `raininggraces-photos` repo.** Azure SWA for the photo app links to this repo.

### Migration Sequence

1. **Phase 1:** Create `azure-migration` branch on `raininggraces` repo. Add SWA config + workflow. Get the site building and deploying to Azure SWA on the auto-generated `*.azurestaticapps.net` URL. Verify everything works.

2. **Phase 2:** Create `raininggraces-photos` repo. Build the photo app. Deploy to its own SWA instance. Test on auto-generated URL.

3. **Phase 3 (cutover):** Update DNS for `www.raininggraces.com` to point to Azure SWA instead of Netlify. Merge `azure-migration` to `master`. Netlify stops receiving deployments (or remove Netlify integration).

4. **Phase 4:** Configure `photos.raininggraces.com` subdomain for the photo app.

5. **Phase 5:** Remove `netlify.toml` from repo. Clean up.

---

## 12. Migration Runbook

### Pre-Migration Checklist

- [ ] Azure subscription active (VS subscription)
- [ ] Entra ID tenant identified (Robin's M365 E5)
- [ ] Current DNS provider login available
- [ ] Netlify dashboard access (for eventual decommission)

### Step-by-Step

1. **Create Azure Resource Group:** `rg-raininggraces` in `South Central US` (closest to OKC)
2. **Create Storage Account:** `straininggraces` (Standard LRS, Hot)
3. **Create Blob container:** `photos` (private access)
4. **Create Table Storage tables:** `albums`, `photos`
5. **Configure Blob lifecycle policy** (31-day delete)
6. **Register Entra ID application** (single-tenant, web redirect to SWA URL)
7. **Create SWA — Main Site:** Link to `raininggraces` repo, `master` branch, app location `/`, output `_site`
8. **Create SWA — Photo App:** Link to `raininggraces-photos` repo
9. **Configure SWA auth** (Entra ID provider in app settings)
10. **Test both apps** on `*.azurestaticapps.net` URLs
11. **DNS cutover:** Update CNAME for `www.raininggraces.com` → SWA-generated CNAME target
12. **Add custom domain** in Azure SWA (auto-provisions SSL)
13. **Verify SSL and routing**
14. **Decommission Netlify** (remove site or downgrade)

---

## 13. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| SWA Free tier limits hit | Site goes down | Very Low | 100 GB bandwidth is massive for a local business. Monitor usage. |
| Entra ID auth breaks | Robin can't upload photos | Low | SWA built-in auth is mature. Keep app registration simple. |
| Blob lifecycle policy deletes too early | Photos lost before 30 days | Very Low | Set policy to 31 days. Cleanup function handles exact 30-day logic. |
| DNS propagation delay during cutover | Brief downtime | Medium | Lower TTL to 300s 24 hours before cutover. Keep Netlify live until DNS propagates. |
| GitHub Actions cleanup cron doesn't run | Stale photos accumulate | Low | Blob lifecycle policy is the backup. Storage cost increase is marginal even if cleanup stops for weeks. |
| Photo app complexity creeps | Dev time grows | Medium | Keep scope minimal. No image processing, no thumbnails v1, no fancy gallery. |

---

## 14. Decision Log

| # | Decision | Rationale | Date |
|---|---|---|---|
| D1 | Use Azure SWA Free tier for both apps | $0/month, covers our needs with massive headroom | 2026-05-10 |
| D2 | Use SWA built-in Entra ID auth (not MSAL) | Zero code, zero maintenance, does exactly what we need | 2026-05-10 |
| D3 | Use Azure Table Storage (not Cosmos DB) | Included with Storage Account, sufficient for ~100 records | 2026-05-10 |
| D4 | Use Standard LRS (not GRS/ZRS) | Photos are temporary (30-day), originals exist on Robin's device | 2026-05-10 |
| D5 | Separate repo for photo app | Independent deployment, clean separation of concerns | 2026-05-10 |
| D6 | Direct-to-blob upload via SAS tokens | Avoids Function payload limits, faster, cheaper | 2026-05-10 |
| D7 | GitHub Actions cron for cleanup (not Timer trigger) | SWA Free managed Functions don't support Timer triggers | 2026-05-10 |
| D8 | Keep DNS at current registrar | Azure DNS costs $0.50/month; just update CNAME records instead | 2026-05-10 |
| D9 | SHA-256 for album passwords | Intentionally simple passwords per requirements; not security-critical | 2026-05-10 |
| D10 | South Central US region | Closest Azure region to OKC for lowest latency | 2026-05-10 |

---

*This document is the implementation blueprint. Each component should be built and tested independently. The main site migration and photo app are on parallel tracks — neither blocks the other.*
