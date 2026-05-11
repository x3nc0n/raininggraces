### 2026-05-10T20:10:36-05:00: Azure resource follow-up configuration
**By:** Valerie
**What:** When Azure resources are created for the photo platform, enable Blob Storage soft delete with 7-day retention and consider turning on the Application Insights free tier (5 GB/month) for API logging.
**Why:** Soft delete is a free safety net against accidental blob deletion, and Application Insights gives low-cost operational visibility for Functions/API behavior. These are Azure portal or CLI follow-up steps, not repository code changes.
