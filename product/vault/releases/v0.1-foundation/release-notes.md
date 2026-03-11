# Release Notes — omysha-signin v0.1 Foundation

**Released**: 2026-03-11
**Epic**: EPIC-001 Authentik Foundation
**Stories**: 6 (2 features)
**Approved by**: Nitin Dhawan (gtalk.nitin@gmail.com)

---

## What's New

### Google OAuth Login
Users can sign in with their Google accounts. The login page shows a "Login with Google"
button. New users are automatically enrolled as internal users in Authentik.

### Group Taxonomy (22 groups)
Full IAM PRD role taxonomy implemented:

| Category | Groups |
|----------|--------|
| Identity | `internal:sankle`, `external:advisor`, `external:collaborator` |
| Teams (7) | Growth, MarketingPR, CommunityBuilding, TechProducts, Enablers, ResearchAnalysisBureau, ContentResearch |
| Councils (3) | Governance, Management, Operational |
| System — Secretariat | `sys:secretariat:admin`, `sys:secretariat:member` |
| System — UPDSS | `sys:updss:admin`, `sys:updss:developer`, `sys:updss:viewer` |
| System — SignIn | `sys:signin:admin`, `sys:signin:member` |
| Special | `authentik Admins`, `all-staff` |

### OIDC Providers
Two consumer applications configured:

| Application | Client ID | Redirect (local) |
|-------------|-----------|-------------------|
| Omysha Secretariat | `SycpMTRPcon...` | http://localhost:2008/callback |
| UPDSS Dashboard | `oCuJojPhAb...` | http://localhost:3021/callback |

Both providers issue signed JWTs with the `groups` claim containing all user group memberships.

### Application Access Control
Expression policies enforce group-based access. The Secretariat app requires
`sys:secretariat:admin` or `sys:secretariat:member` group membership.

---

## Configuration Summary

| Component | Detail |
|-----------|--------|
| Authentik version | 2024.12.3 |
| Local URL | http://localhost:3008 |
| Production URL | https://signin.omysha.org |
| Admin user | gtalk.nitin@gmail.com |
| API token | Non-expiring, identifier: `updss-agent` |
| Google OAuth callback | http://localhost:3008/source/oauth/callback/google/ |
| Signing key | Self-signed certificate |
| Custom scope | `groups` — returns all user group names in JWT |

---

## Known Limitations

- **Email allowlist not enforced** — any Google account can currently enroll. Future: add enrollment policy to restrict to @omysha.org and approved domains.
- **UPDSS Dashboard open access** — no access policy bound yet. Will be added when UPDSS EPIC-015 authorization model is implemented.
- **Production not yet mirrored** — signin.omysha.org needs the same configuration (groups, providers, Google OAuth with production callback URL).
- **Groups deduplication** — default profile mapping and custom groups scope both return groups. Fixed via `set()` in custom scope expression.

---

## What's Next (v0.2 — Internal SSO)

- HRMS (Frappe) integration via SAML 2.0
- PyTracker integration via OIDC
- Todo App integration via OIDC
- Google Drive access management
