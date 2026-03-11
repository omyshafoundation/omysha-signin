<!-- progress.md — APPEND-ONLY session log
     story_id:   STORY-001-02-03
     created:    2026-03-10
     created_by: Nitin Dhawan (gtalk.nitin@gmail.com)
-->

# Progress Log — STORY-001-02-03: JWT Groups Claim Validation

---

## Session 1 — 2026-03-10

**Phase**: g1_approved -> in_progress
**Tasks completed**: T-1, T-2
**Cost**: $0.10

### What was done
- Created groups scope mapping in both OIDC providers to ensure JWT tokens include group claims
- Verified provider configurations for secretariat-oidc and updss-dashboard-oidc include groups scope
- Admin user assigned test groups (internal:sankle, team:TechProducts, sys:updss:admin) for validation

### Next steps
- T-3: Complete a real OIDC flow — log in as test user, inspect JWT token, verify groups claim matches assigned groups
- T-4: Test access denial for user not in application's bound groups
- T-5: Document token structure and full validation results

### Blockers
- Requires a real OIDC login flow to inspect the JWT token end-to-end

## Session 2 — 2026-03-11

**Model**: claude-opus-4-6
**Tasks completed**: T-3, T-4, T-5

### What was done

- T-3: End-to-end OIDC flow validated with real Google-enrolled user (Zoom1 / zoom1@omysha.org):
  - Built Python callback server to capture authorization code and exchange for tokens
  - UPDSS Dashboard OIDC provider issued JWT with correct claims:
    - `iss`: http://localhost:3008/application/o/updss-dashboard/
    - `email`: zoom1@omysha.org
    - `email_verified`: true
    - `groups`: ["internal:sankle", "team:TechProducts", "sys:updss:admin"]
    - `name`: Zoom1 Omysha
    - `preferred_username`: Zoom1
  - Fixed: signing key was `None` — set to self-signed cert (pk: fb133648...)
  - Fixed: groups were duplicated (profile mapping + custom scope both returned groups).
    Updated custom scope expression to use `list(set(...))` for deduplication.

- T-4: Access denial validated:
  - Created `secretariat-access-policy` (expression policy requiring sys:secretariat:admin or sys:secretariat:member)
  - Bound policy to Secretariat application
  - Zoom1 (not in Secretariat groups) received "Permission denied" when attempting to authorize against Secretariat OIDC provider
  - Confirms group-based application access control works correctly

- T-5: Token structure documented (this entry).

### JWT Token Structure (redacted)

```json
{
  "iss": "http://localhost:3008/application/o/updss-dashboard/",
  "sub": "[uuid]",
  "aud": "oCuJojPhAbIENwfaRBWvkNRGWZBOdCxA9J8UZXiT",
  "email": "zoom1@omysha.org",
  "email_verified": true,
  "groups": ["internal:sankle", "team:TechProducts", "sys:updss:admin"],
  "name": "Zoom1 Omysha",
  "preferred_username": "Zoom1",
  "acr": "goauthentik.io/providers/oauth2/default"
}
```

### AC verification

- AC-1: Test user (Zoom1) created with 3 group memberships ✓
- AC-2: JWT groups claim contains all assigned groups ✓
- AC-3: Access denied for user not in Secretariat bound groups ✓

---
<!-- Add new session entries above this line. Never edit entries above. -->
