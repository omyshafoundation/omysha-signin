# Omysha SignIn — Release Roadmap

| Version | Name | Scope | Status |
|---------|------|-------|--------|
| **0.1** | Foundation | Authentik deployed, groups created, Google OAuth, first OIDC consumer (Secretariat) | In Progress |
| **0.2** | Internal SSO | HRMS (Frappe), PyTracker, Todo App integrated via SAML/OIDC | Planned |
| **0.3** | Community SSO | Moodle (VONG Hub) integration, Vongles user population | Planned |

## v0.1 — Foundation

**Goal**: Complete the Authentik deployment with all groups, Google OAuth brokering, and the first OIDC consumer application.

Maps to IAM PRD Phase 0 + Phase 1.

Key deliverables:
- Local Docker environment validated
- Google OAuth Source configured
- All groups created per IAM PRD role taxonomy (identity, team, council, system)
- UPDSS-specific groups added (`sys:updss:admin`, `sys:updss:developer`, `sys:updss:viewer`)
- OIDC Provider created for Secretariat System
- OIDC Provider created for UPDSS Dashboard
- Production at signin.omysha.org validated
- JWT `groups` claim confirmed flowing to consumers

## v0.2 — Internal SSO

**Goal**: Integrate existing internal Omysha systems.

Maps to IAM PRD Phase 2.

- HRMS (Frappe) via SAML 2.0
- PyTracker via OIDC
- Todo App via OIDC
- Google Drive Access Management

## v0.3 — Community SSO

**Goal**: Evaluate and integrate community-facing systems.

Maps to IAM PRD Phase 3.

- Moodle (VONG Hub) for Vongles
- Separate user population management
