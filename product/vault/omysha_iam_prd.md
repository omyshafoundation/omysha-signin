# PRD — Omysha Centralised Identity & Access Management System
## Product Requirements Document
**Version**: 1.0
**Prepared**: March 2026
**Author**: Nitin Dhawan
**Classification**: Internal — Technical Stakeholders
**Status**: Draft for Review

---

## Table of Contents

1. [Purpose & Background](#1-purpose--background)
2. [Organisational Context](#2-organisational-context)
3. [Problem Statement](#3-problem-statement)
4. [Goals & Success Metrics](#4-goals--success-metrics)
5. [Scope](#5-scope)
6. [User Types & Roles](#6-user-types--roles)
7. [Functional Requirements](#7-functional-requirements)
8. [System Architecture](#8-system-architecture)
9. [Integration Matrix](#9-integration-matrix)
10. [Local Development — Docker Setup](#10-local-development--docker-setup)
11. [Production Deployment — Hostinger](#11-production-deployment--hostinger)
12. [Security Requirements](#12-security-requirements)
13. [Implementation Roadmap](#13-implementation-roadmap)
14. [Open Questions & Constraints](#14-open-questions--constraints)

---

## 1. Purpose & Background

This document defines the requirements for the **Omysha Centralised Identity & Access Management (IAM) System** — a self-hosted Single Sign-On (SSO) and authorisation layer that will serve as the identity backbone for all Omysha digital systems.

The system will be built on **Authentik** (open-source IdP), brokering Google identities and issuing organisation-specific role tokens to downstream applications.

**The immediate trigger** is the development of a new internal system — the **Omysha Secretariat Management System** — which will be the first application integrated with this IAM. All subsequent Omysha systems (HRMS, LMS, tracking tools, etc.) will connect to the same IdP over time.

---

## 2. Organisational Context

### 2.1 Omysha Foundation

Omysha is a social-impact organisation operating on a **Secretariat model** — a lean central secretariat supported by functional teams of interns ("Sankles") working on two active initiatives:

| Initiative | Focus | Primary Audience |
|---|---|---|
| **A4G** (AI for Good) | Ethical AI governance, mental well-being, socio-economic sustainability | External public + internal team |
| **VONG** (Voice of New Generation) | Youth advocacy, sustainability, behavioural change | External community (Vongles) + internal team |

### 2.2 People in the Ecosystem

| Type | Description | Scale |
|---|---|---|
| **Sankles** | Full internal members — interns across all 7 teams | ~40 |
| **Operational Leaders** | Team leads managing each functional team | ~7 |
| **Council Members** | Governance, Management, Operational councils | ~10–15 |
| **Advisors** | Advisory Board members, limited access | ~5 |
| **External Collaborators** | Partners, guests, scoped access | Variable |
| **Vongles** | VONG community members — external learners on Moodle | Hundreds |

### 2.3 Functional Teams

01 Growth · 02 Marketing & PR · 03 Community Building · 04 Tech Systems & Products · 05 Enablers · 06 Research Analysis Bureau · 07 Content & Research

### 2.4 Existing IT Systems

The following 13 systems currently operate across Omysha's two initiatives. They represent the full integration surface for this IAM system.

| # | System | Domain | Audience | SSO Priority |
|---|---|---|---|---|
| 1 | HRMS (Frappe) | hr.omysha.org | Internal (Sankles) | High |
| 2 | VONG Hub LMS (Moodle) | hub.vong.earth | External (Vongles) | Medium |
| 3 | VLH (VONG Learning Hub) | vlh.omysha.org | External | Medium |
| 4 | Leaderboard | reports.vong.earth | External | Low |
| 5 | SustainaSpark Platform | sustainaspark6.vong.earth | External / Public | None (public) |
| 6 | SustainaSpark Backend API | ss-backend.vong.earth | Internal API | None (API key) |
| 7 | A4G Main Website | a4gcollab.org | External / Public | None (public) |
| 8 | A4G Backend API | backend.a4gcollab.org | Internal API | None (API key) |
| 9 | PyTracker | tracker.omysha.org | Internal | High |
| 10 | Todo App | todo.vong.earth | Internal | High |
| 11 | YouTube System | videos.omysha.org | Internal | Low |
| 12 | Google Drive Access Mgmt | 139.84.152.71:8080 | Internal Admin | High |
| 13 | **Omysha Secretariat System** | (new — TBD) | Internal | **First target** |

---

## 3. Problem Statement

### 3.1 Current Pain Points

1. **No centralised identity** — each system has independent credentials. A new Sankle joining requires accounts created manually in each system (HRMS, Moodle, Todo, Tracker, etc.).

2. **No single offboarding path** — when a Sankle's tenure ends, accounts must be disabled across 8+ systems manually. This creates security gaps.

3. **No role consistency** — a Sankle's team or council membership is tracked in spreadsheets, not in a system that downstream applications can verify.

4. **No audit trail** — there is no unified log of who accessed what, when.

5. **Password sprawl** — internal members manage different credentials for each tool, leading to weak passwords and credential reuse.

6. **The new Secretariat System needs authentication from day one** — it cannot be built with yet another independent auth layer.

### 3.2 What is NOT broken (out of scope)

- External-facing public pages (A4G Website, SustainaSpark landing pages) — no SSO needed.
- API backends authenticating via API keys (SustainaSpark Backend, A4G Backend) — not affected.
- VONG Hub Moodle for Vongles — Vongles are a separate community and do not need Omysha SSO (medium-term integration possible but not in this scope).

---

## 4. Goals & Success Metrics

### 4.1 Goals

| # | Goal |
|---|---|
| G1 | A single Authentik instance serves as the identity source for all Omysha internal systems |
| G2 | Members authenticate with their existing Google account — no new passwords to remember |
| G3 | Adding a new Sankle requires creating one account (in Authentik) — all systems provision automatically or on first SSO login |
| G4 | Offboarding a member disables access across all integrated systems by disabling their Authentik account |
| G5 | Role assignments (team, council, system permissions) are managed in one place and flow via JWT claims |
| G6 | The new Omysha Secretariat System is the first application fully integrated with this IAM |
| G7 | The system is testable on local Docker before production deployment |
| G8 | Production is hosted at `signin.omysha.org` |

### 4.2 Success Metrics

| Metric | Target |
|---|---|
| Time to onboard a new member | < 10 minutes (down from ~30 minutes across systems) |
| Time to offboard a member | < 2 minutes (single Authentik deactivation) |
| Systems integrated with SSO at launch | 1 (Secretariat System) |
| Systems integrated with SSO within 3 months of launch | 4 (Secretariat + HRMS + PyTracker + Todo App) |
| Login success rate via Google SSO | > 99% |
| Members using Google SSO vs. local passwords | > 90% |

---

## 5. Scope

### Phase 0 — Foundation (This PRD)
Deploy Authentik on local Docker. Integrate with the **Omysha Secretariat Management System** as the first and only consumer. Validate the full login flow, role assignment, and JWT claims before any production deployment.

### Phase 1 — Production Launch
Deploy Authentik at `signin.omysha.org` (Hostinger VPS). The Secretariat System live at its own subdomain, authenticated via Authentik.

### Phase 2 — Internal Systems SSO (Post-launch)
Integrate HRMS (Frappe), PyTracker, Todo App, and Google Drive Access Mgmt using SAML 2.0 or OIDC.

### Phase 3 — Community Systems SSO (Future)
Evaluate Moodle (VONG Hub) and VLH integration for Vongles — requires separate user population management.

---

## 6. User Types & Roles

### 6.1 Identity Category (Who they are)

| Authentik Group | Description | Default System Access |
|---|---|---|
| `internal:sankle` | Full Omysha member — active intern | All internal systems |
| `external:advisor` | Advisory Board member | Designated systems only |
| `external:collaborator` | External partner/guest | Scoped, per-project |

### 6.2 Team Roles (What team they're on)

`team:Growth` · `team:MarketingPR` · `team:CommunityBuilding` · `team:TechProducts` · `team:Enablers` · `team:ResearchAnalysisBureau` · `team:ContentResearch`

### 6.3 Council Roles

`council:Governance` · `council:Management` · `council:Operational`

### 6.4 System Roles (What permissions in specific tools)

| Group | Permission |
|---|---|
| `sys:frappe:admin` | HRMS system administrator |
| `sys:frappe:user` | HRMS standard user |
| `sys:secretariat:admin` | Secretariat System admin |
| `sys:secretariat:member` | Secretariat System member |
| `sys:github:maintainer` | GitHub org maintainer |
| `sys:tracker:admin` | PyTracker admin |

### 6.5 Admin Delegation Tiers

| Level | Role | Scope |
|---|---|---|
| L1 | Super Admin | Full Authentik — all users, groups, apps, certificates |
| L2 | Governance Admin | Governance Council group membership only |
| L3 | Team Admin | Single team group membership only |
| L3 | System Access Manager | Application bindings and system-role assignments |

---

## 7. Functional Requirements

### 7.1 User Provisioning — How People Get Added

**FR-01: Admin-initiated provisioning**
An Authentik admin creates a user account by:
1. Entering the member's canonical email address
2. Linking to Google (the member authenticates on first login via Google OAuth)
3. Assigning Authentik groups per the role taxonomy

**FR-02: Google SSO linkage**
The system supports Google as the upstream Identity Provider via OAuth2/OIDC identity brokering. On first login, if the email matches a pre-created account, the Google identity is linked automatically.

**FR-03: Local account fallback**
For service accounts or members without Google accounts, admins can create local Authentik accounts with username + password.

**FR-04: Email allowlist enforcement**
Until Omysha has a Google Workspace domain (`@omysha.org`), only pre-approved email addresses can enroll. The Google Source in Authentik enforces an allowlist policy — unapproved emails are rejected.

**FR-05: SCIM / manual provisioning in downstream apps**
At ~45 users, manual pre-provisioning is acceptable. For each new member: (1) create Authentik account, (2) create matching account in each downstream app using the same email address, (3) assign Authentik groups. This is documented as the standard onboarding checklist.

### 7.2 Authentication Flow

**FR-06: Google-brokered login**
Standard login flow:
1. User accesses an Omysha application
2. Application redirects to Authentik (OIDC or SAML request)
3. Authentik presents "Login with Google" option
4. User authenticates with Google; Google returns OIDC callback to Authentik
5. Authentik looks up the local user record, applies groups and policies
6. Authentik issues a SAML assertion or OIDC/JWT token with role claims to the application
7. Application grants access based on Authentik-issued claims

**FR-07: Session management**
Authentik manages the SSO session. Re-authentication is required after session expiry (configurable: default 24 hours for internal apps).

**FR-08: MFA (future)**
Multi-factor authentication via TOTP should be supported by Authentik but is not mandatory in Phase 0. It must not be blocked by design.

### 7.3 Role & Claims Management

**FR-09: JWT role claims**
All OIDC tokens issued by Authentik must include a `groups` claim listing the user's Authentik group memberships. Example:
```json
{
  "sub": "user@gmail.com",
  "email": "user@gmail.com",
  "groups": ["internal:sankle", "team:TechProducts", "sys:secretariat:member"]
}
```

**FR-10: Application binding**
Each application registered in Authentik has explicit group bindings. Access is **denied by default**. A user can only access an application if they belong to a group explicitly bound to that application.

**FR-11: Additive group permissions**
A Sankle who is also a Governance Council member and Team Lead has the union of all permissions from all their groups. No conflict resolution is needed — permissions are additive.

### 7.4 Onboarding Checklist (Operational)

For each new Sankle, the System Access Manager follows this sequence:

1. Collect canonical email address (must be a Google-linked email)
2. Create user in Authentik → set email → enable "Must change password on next login" if local, or leave for Google enrollment
3. Assign groups: `internal:sankle` + relevant `team:*` + any `council:*` or `sys:*`
4. Create matching accounts in each integrated downstream app with the same email
5. Share login URL (`signin.omysha.org`) with the new member
6. Member clicks "Login with Google" — Authentik links their Google account on first login

### 7.5 Offboarding

1. Disable the user's Authentik account (one action)
2. All Authentik-integrated systems deny access immediately (token validation fails)
3. For non-integrated systems (e.g., GitHub), disable separately — tracked via offboarding checklist
4. After 30 days, archive/delete the Authentik account

### 7.6 Admin Portal

**FR-12**: Authentik's built-in admin UI (`/if/admin/`) is used for all IAM management. No custom admin UI is required for Phase 0 or Phase 1.

---

## 8. System Architecture

### 8.1 High-Level Architecture

```
                        ┌─────────────────────────────────────┐
                        │           OMYSHA MEMBERS             │
                        │  (Sankles, Advisors, Collaborators)  │
                        └────────────────┬────────────────────┘
                                         │ Login Request
                                         ▼
┌────────────────────────────────────────────────────────────────┐
│                    signin.omysha.org                           │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  AUTHENTIK (IdP + Broker)                │  │
│  │                                                          │  │
│  │  ┌─────────────────┐    ┌──────────────────────────┐    │  │
│  │  │  Google Source  │    │  Role & Group Engine      │    │  │
│  │  │  (OAuth2/OIDC)  │    │  JWT / SAML Issuance      │    │  │
│  │  └────────┬────────┘    └──────────────────────────┘    │  │
│  │           │                                              │  │
│  │  ┌────────▼────────┐    ┌──────────────────────────┐    │  │
│  │  │  PostgreSQL DB  │    │  Redis (session cache)    │    │  │
│  │  └─────────────────┘    └──────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬────────────────────────────────┘
                                │ SAML / OIDC tokens
          ┌─────────────────────┼──────────────────────┐
          ▼                     ▼                      ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Secretariat App │  │  HRMS (Frappe)   │  │  PyTracker /     │
│ (Phase 0 — new) │  │  (Phase 2)       │  │  Todo (Phase 2)  │
│ OIDC            │  │  SAML 2.0        │  │  OIDC            │
└─────────────────┘  └──────────────────┘  └──────────────────┘
```

### 8.2 Component Stack

| Component | Technology | Purpose |
|---|---|---|
| Identity Provider | Authentik (latest stable) | SSO, brokering, token issuance |
| Database | PostgreSQL 16 | Authentik user/policy storage |
| Cache | Redis 7 | Session cache, worker queues |
| Upstream IdP | Google OAuth2/OIDC | Identity verification |
| Downstream Protocol (custom apps) | OIDC | JWT token issuance |
| Downstream Protocol (Frappe, Moodle) | SAML 2.0 | Enterprise SSO |
| TLS termination | Nginx reverse proxy (prod) | HTTPS for `signin.omysha.org` |

### 8.3 Data Flow — Authentication Sequence

```
Actor → App → Authentik → Google → Authentik → App

1. User hits protected route in Secretariat App
2. App redirects: GET /application/o/secretariat/authorize/
3. Authentik shows login screen
4. User clicks "Login with Google"
5. Authentik redirects to Google OAuth consent
6. Google authenticates user, returns id_token to Authentik callback
7. Authentik: looks up user by email, loads group memberships
8. Authentik: applies application binding check (is user in allowed group?)
9. Authentik: issues OIDC id_token + access_token with groups claim
10. App validates token, creates local session, grants access
```

---

## 9. Integration Matrix

### 9.1 Secretariat System (Phase 0 — Primary Target)

| Attribute | Value |
|---|---|
| Protocol | OIDC (Authorization Code Flow with PKCE) |
| Token format | JWT (id_token) |
| Required claims | `sub`, `email`, `name`, `groups` |
| Application binding | `internal:sankle`, `external:advisor` |
| Launch URL | TBD (local: `http://localhost:2008`) |

**Configuration steps:**
1. Create OIDC Provider in Authentik → enable `groups` scope
2. Create Application linked to provider → set launch URL
3. Bind groups `internal:sankle` and `external:advisor` to the application
4. In Secretariat app: configure OIDC library with Authentik's discovery endpoint (`/application/o/secretariat/.well-known/openid-configuration`)
5. Parse `groups` claim to determine access level

### 9.2 HRMS — Frappe (Phase 2)

| Attribute | Value |
|---|---|
| Protocol | SAML 2.0 (SP-initiated) |
| NameID | Email |
| Application binding | `internal:sankle`, `sys:frappe:admin`, `sys:frappe:user` |
| Pre-provisioning | Required — create matching Frappe account with same email before first SSO login |

### 9.3 PyTracker & Todo App (Phase 2)

| Attribute | Value |
|---|---|
| Protocol | OIDC |
| Application binding | `internal:sankle` |
| Notes | Verify if app supports OIDC; may require code changes |

### 9.4 GitHub (Phase 2 — Partial)

Authentik cannot directly broker GitHub org membership, but can enforce that only members with `sys:github:maintainer` get the relevant links/access surfaces in internal tools.

---

## 10. Local Development — Docker Setup

### 10.1 Series Allocation

Per the UDMSS Docker Master Guide, the next available series is **x008**.

| Service | Series Formula | Port |
|---|---|---|
| Authentik Server (HTTP) | Custom | `9008` |
| Authentik Server (HTTPS) | Custom | `9448` |
| PostgreSQL | `5000 + 8` | `5008` |
| Redis | Custom | `6308` |

> **Note**: Authentik's internal ports (9000/9443) are well-known; the external mapped ports follow the series pattern.

### 10.2 Docker Compose

**File location**: `DockerGuide/DockerSetups/MacBook-Pro-4.local/omysha-iam.yml`

```yaml
name: omysha-iam

services:

  omysha-iam-db:
    image: postgres:16-alpine
    container_name: omysha-iam-db
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${PG_PASS}
      POSTGRES_USER: authentik
      POSTGRES_DB: authentik
    volumes:
      - omysha_iam_pg_data:/var/lib/postgresql/data
    ports:
      - "5008:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U authentik"]
      interval: 10s
      timeout: 5s
      retries: 5

  omysha-iam-redis:
    image: redis:7-alpine
    container_name: omysha-iam-redis
    restart: unless-stopped
    ports:
      - "6308:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  omysha-iam-server:
    image: ghcr.io/goauthentik/server:latest
    container_name: omysha-iam-server
    restart: unless-stopped
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: omysha-iam-redis
      AUTHENTIK_POSTGRESQL__HOST: omysha-iam-db
      AUTHENTIK_POSTGRESQL__USER: authentik
      AUTHENTIK_POSTGRESQL__NAME: authentik
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_ERROR_REPORTING__ENABLED: "false"
    ports:
      - "9008:9000"
      - "9448:9443"
    volumes:
      - omysha_iam_media:/media
      - omysha_iam_custom_templates:/templates
    depends_on:
      omysha-iam-db:
        condition: service_healthy
      omysha-iam-redis:
        condition: service_healthy

  omysha-iam-worker:
    image: ghcr.io/goauthentik/server:latest
    container_name: omysha-iam-worker
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: omysha-iam-redis
      AUTHENTIK_POSTGRESQL__HOST: omysha-iam-db
      AUTHENTIK_POSTGRESQL__USER: authentik
      AUTHENTIK_POSTGRESQL__NAME: authentik
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - omysha_iam_media:/media
      - omysha_iam_certs:/certs
      - omysha_iam_custom_templates:/templates
    depends_on:
      omysha-iam-db:
        condition: service_healthy
      omysha-iam-redis:
        condition: service_healthy

volumes:
  omysha_iam_pg_data:
  omysha_iam_media:
  omysha_iam_certs:
  omysha_iam_custom_templates:
```

**Required `.env` file** (alongside the compose file):
```env
PG_PASS=<generate-strong-password>
AUTHENTIK_SECRET_KEY=<generate-with: openssl rand -hex 32>
```

### 10.3 Local Startup & Validation

```bash
# 1. Start containers
docker compose -f DockerGuide/DockerSetups/MacBook-Pro-4.local/omysha-iam.yml up -d

# 2. Wait for health — check status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 3. Create initial admin user (first-time only)
# Navigate to: http://localhost:9008/if/flow/initial-setup/

# 4. Access admin UI
# http://localhost:9008/if/admin/

# 5. Access user-facing login UI
# http://localhost:9008/if/user/
```

### 10.4 Local Configuration Checklist

- [ ] Deploy Authentik stack via Docker Compose
- [ ] Complete initial admin setup at `/if/flow/initial-setup/`
- [ ] Configure Google OAuth2 Source (requires Google Cloud Console OAuth credentials)
- [ ] Create groups: `internal:sankle`, `external:advisor`, `external:collaborator`
- [ ] Create team groups: `team:TechProducts`, `team:MarketingPR`, etc.
- [ ] Create system groups: `sys:secretariat:admin`, `sys:secretariat:member`
- [ ] Create OIDC Provider for Secretariat App
- [ ] Create Application + bind groups
- [ ] Create test users and validate login flow
- [ ] Validate `groups` claim appears in issued JWT
- [ ] Test group-based access denial (user not in allowed group should be blocked)

---

## 11. Production Deployment — Hostinger

### 11.1 Infrastructure Requirement

**Provider**: Vultr VPS (consistent with all existing Omysha infrastructure).

A dedicated VPS is recommended for the IAM system rather than sharing with an existing server (e.g., Hub-1Nov `139.84.152.71`), to avoid resource contention and allow independent scaling. The existing Test Server (`139.84.133.1`) may be repurposed for this if not otherwise in use — confirm with Nitin.

> **DNS**: The `signin.omysha.org` subdomain DNS A record must point to the Vultr VPS IP. Manage via wherever `omysha.org` DNS is hosted — confirm with Nitin.

### 11.2 Subdomain & DNS

```
DNS Record:
  Type: A
  Name: signin
  Value: <VPS IP address>
  TTL: 300
```

### 11.3 Production Docker Compose Differences from Local

| Setting | Local Dev | Production |
|---|---|---|
| External ports | `9008`, `9448` | Internal only (behind Nginx) |
| Nginx reverse proxy | Not used | Required — terminates TLS |
| TLS certificate | Not used | Let's Encrypt via Certbot |
| `AUTHENTIK_COOKIE_DOMAIN` | Not set | `omysha.org` |
| `AUTHENTIK_HOST` | Not set | `https://signin.omysha.org` |
| `AUTHENTIK_HOST_BROWSER` | Not set | `https://signin.omysha.org` |

### 11.4 Nginx Configuration (Production)

```nginx
server {
    listen 80;
    server_name signin.omysha.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name signin.omysha.org;

    ssl_certificate /etc/letsencrypt/live/signin.omysha.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signin.omysha.org/privkey.pem;

    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 11.5 Production Deployment Sequence

1. Provision VPS (Hostinger VPS or new Vultr), record IP
2. Point `signin.omysha.org` DNS A record to VPS IP
3. SSH into VPS, install Docker + Docker Compose
4. Clone deployment config / copy compose file securely
5. Generate production secrets (`openssl rand -hex 32`)
6. Start containers: `docker compose up -d`
7. Install Nginx, configure reverse proxy
8. Obtain TLS cert: `certbot --nginx -d signin.omysha.org`
9. Complete Authentik initial setup
10. Configure Google OAuth Source with production callback URL:
    `https://signin.omysha.org/source/oauth/callback/google/`
11. Migrate local configuration (providers, applications, groups, policies)
12. Smoke test with a real Google account
13. Add member accounts and validate

---

## 12. Security Requirements

| Requirement | Detail |
|---|---|
| TLS everywhere | All traffic to `signin.omysha.org` over HTTPS. Let's Encrypt certificate with auto-renewal. |
| Secrets not in code | All secrets (PG_PASS, SECRET_KEY, Google Client Secret) in `.env` files excluded from version control |
| Google client secret | Stored as environment variable only — never committed to git |
| Allowlist enforcement | Authentik Google Source configured to allow only pre-approved email addresses during enrolment |
| Token expiry | OIDC access tokens expire in 5 minutes; refresh tokens in 24 hours (configurable per app) |
| Admin account | First admin account protected with a strong password + TOTP MFA enabled |
| No default credentials | Authentik default admin credentials changed on first setup |
| Backup | PostgreSQL data volume backed up weekly to off-server storage |
| Audit logging | Authentik's built-in audit log (Events section) reviewed monthly by Super Admin |
| Port exposure | Database (5008) and Redis (6308) ports not exposed publicly in production — internal Docker network only |

---

## 13. Implementation Roadmap

### Phase 0 — Local Validation (Target: 2 weeks)

| Week | Tasks |
|---|---|
| Week 1 | Spin up Authentik on local Docker. Configure Google OAuth Source. Create all groups per role taxonomy. Create test users. |
| Week 2 | Build/configure Secretariat App OIDC integration. Validate full login flow (Google → Authentik → App). Validate group-based access control. Validate JWT claims. |

### Phase 1 — Production Launch (Target: 1 week after Phase 0)

| Task | Owner |
|---|---|
| Provision VPS or confirm Hostinger VPS plan | Nitin |
| Point `signin.omysha.org` DNS | Nitin |
| Deploy Authentik to production | Tech Lead |
| Configure production Google OAuth credentials | Tech Lead |
| Migrate configuration from local to prod | Tech Lead |
| Import all ~45 members into Authentik | System Access Manager |
| Smoke test with 3 real members | QA |
| Go live — update Secretariat App to use prod Authentik URL | Tech Lead |

### Phase 2 — Legacy System SSO Integration (Target: 6–8 weeks after Phase 1)

| System | Protocol | Pre-provisioning needed | Complexity |
|---|---|---|---|
| HRMS (Frappe) | SAML 2.0 | Yes — Frappe accounts must pre-exist | Medium |
| PyTracker | OIDC (if supported) | Depends on app | Low–Medium |
| Todo App | OIDC (if supported) | Depends on app | Low–Medium |
| Google Drive Access Mgmt | OIDC | Custom integration needed | Medium |

---

## 14. Open Questions & Constraints

| # | Question | Who to resolve |
|---|---|---|
| Q1 | Which Vultr VPS will host Authentik — a new dedicated instance or the existing Test Server (`139.84.133.1`)? A dedicated instance is recommended. | Nitin |
| Q2 | What is the intended subdomain for the Secretariat App itself? (Authentik lives at `signin.omysha.org` — the Secretariat App needs its own subdomain, e.g., `app.omysha.org` or `secretariat.omysha.org`) | Nitin |
| Q3 | Google OAuth credentials: Does Omysha have a Google Cloud Console project for `omysha.org`? OAuth Client ID and Secret are required for Google Source in Authentik. | Nitin |
| Q4 | Does Omysha plan to adopt Google Workspace (`@omysha.org` accounts)? If yes, the Authentik Google Source can enforce domain restriction. Until then, an email allowlist must be maintained manually. | Leadership |
| Q5 | Zoho Connect is mentioned in the IAM research docs — is this still in active use? If so, it would be a Phase 2 integration (SAML 2.0). | Nitin |
| Q6 | Should Vongles (VONG Hub Moodle users) ever be able to use Omysha SSO? They are a separate, much larger population and have different identity needs. This would be Phase 3 at the earliest. | Product |

---

*End of Document*
*Next step: Review open questions (Section 14), then proceed to Phase 0 Docker implementation.*
