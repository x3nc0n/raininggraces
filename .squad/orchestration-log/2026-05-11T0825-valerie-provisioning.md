# Orchestration: Valerie Provisioning — 2026-05-11T08:25

**Agent:** Valerie (DevOps)  
**Status:** COMPLETE  
**Trigger:** Post-Azure provisioning — extract SWA tokens, set GitHub secrets, scope down SP, configure Entra ID auth, create deploy workflow

---

## Context

Both Azure provisioning workflows succeeded after fixing a Bicep `list()` syntax bug (InvalidResourceNamespace error).

**Resources Created:**
- **RG:** rg-raininggraces (centralus)
- **SWA:** swa-raininggraces-main
- **SWA:** swa-raininggraces-photos
- **Storage:** straininggraces
- **Provisioning run IDs:** main=25672880631, photos=25672874429

**Previous Failed Attempts:**
1. southcentralus region not available for SWA → fixed to centralus
2. list() function syntax → fixed to .listSecrets()

---

## Post-Provisioning Tasks

Next phase: Extract SWA deployment tokens, set GitHub repository secrets, scope down service principal, configure Entra ID auth, and create CI/CD deploy workflows.

---

**Created by:** Scribe (orchestration log post-success)
