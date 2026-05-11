# Azure IaC bootstrap

- **Date:** 2026-05-11T07:45:28-05:00
- **Author:** Valerie
- **Decision:** Use subscription-scope Bicep plus manually triggered GitHub Actions OIDC workflows in both repos for provisioning, and treat SWA deployment-token secret setup as a documented bootstrap step after provisioning.
- **Why:** This keeps Azure resource creation in CI/CD as requested, avoids manual portal provisioning, and respects GitHub's limitation that the default workflow token cannot create or update repository secrets.
