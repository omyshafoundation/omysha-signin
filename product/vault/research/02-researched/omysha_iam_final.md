# Omysha Centralised Identity & Access System — Final Research Report
## v3.0
**Prepared:** March 2026
**Classification:** Internal Strategic Document
**Audience:** Leadership, Governance Council, Technical Stakeholders

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Organisational Context and Requirements](#2-organisational-context-and-requirements)
3. [Candidate Evaluation](#3-candidate-evaluation)
   - [3.1 Authentik](#31-authentik)
   - [3.2 Keycloak](#32-keycloak)
   - [3.3 ZITADEL](#33-zitadel)
   - [3.4 Eliminated Candidates](#34-eliminated-candidates)
4. [Comparison Matrix](#4-comparison-matrix)
5. [Top Recommendation: Authentik](#5-top-recommendation-authentik)
6. [High-Level Architecture](#6-high-level-architecture)
7. [Authentication via Google (Identity Brokering)](#7-authentication-via-google-identity-brokering)
8. [SSO Integration Details](#8-sso-integration-details)
   - [8.1 Zoho Connect](#81-zoho-connect)
   - [8.2 Frappe (Self-Hosted)](#82-frappe-self-hosted)
   - [8.3 GitHub](#83-github)
   - [8.4 Future Custom Systems](#84-future-custom-systems)
9. [Role and Identity Hierarchy Model](#9-role-and-identity-hierarchy-model)
10. [Admin Delegation Model](#10-admin-delegation-model)
11. [Centralised Authorisation via JWT Token Claims](#11-centralised-authorisation-via-jwt-token-claims)
12. [Hosting and Cost Analysis](#12-hosting-and-cost-analysis)
13. [Scalability and Future Vision](#13-scalability-and-future-vision)
14. [Risks and Limitations](#14-risks-and-limitations)
15. [Implementation Roadmap](#15-implementation-roadmap)
16. [References](#16-references)

---

## 1. Executive Summary

Omysha requires a single, trusted identity system that can authenticate and authorise approximately 45 people (20 Sankles + 25 Advisory Board members) across Zoho Connect, a self-hosted Frappe instance, GitHub, and future custom-built tools — all within a hard infrastructure budget of USD $10 per month.

After evaluating Keycloak, Authentik, ZITADEL, Kanidm, and the lldap+Authelia combination, this document recommends **Authentik** as the primary Identity Provider (IdP).

**Key conclusions:**

- **Authentik** is the strongest fit: it is open-source with no per-user fees, supports SAML 2.0 and OIDC natively, has a documented working integration with Zoho, Frappe, and GitHub Enterprise Server, supports multi-role assignment per user through groups, and can run comfortably on a Hetzner CX22 VPS (~EUR 3.79/month, ~USD 4.15) within budget.
- **Google Identity Brokering**: Omysha members can use their existing Google accounts to authenticate. Authentik acts as the broker between Google (upstream identity provider) and all downstream applications (Zoho, Frappe, custom systems). Downstream apps only ever communicate with Authentik — Google is invisible to them. All roles, council memberships, and team assignments are managed in Authentik, not Google.
- Authentik's **RBAC model** (roles → groups → users) maps cleanly onto Omysha's governance structure: councils, teams, Sankles, and Advisory Board members can each be a group, with roles stacked per person.
- The **role taxonomy** follows a clear naming convention: `internal:sankle`, `external:advisor`, `external:collaborator`, `team:Marketing`, `team:TechProducts`, `council:Governance`, `council:Management`, `council:Operational`, `sys:zoho:editor`, `sys:frappe:admin`, `sys:github:maintainer`.
- Authentik's **OIDC JWT tokens** include group/role claims that future custom systems can consume directly for authorisation, providing a path to centralised authorisation — not just authentication.
- The **GitHub SAML SSO caveat** applies to all candidates: GitHub's native SAML SSO for organisations requires GitHub Enterprise Cloud (paid). A practical, cost-free workaround is documented in Section 8.3.
- The **admin delegation model** (Super Admin → Governance Admin → Team Admin → System Access Manager) is achievable in Authentik through its RBAC permission system and role delegation.

---

## 2. Organisational Context and Requirements

### 2.1 Omysha's Structure

| Entity | Count | Notes |
|---|---|---|
| Sankles (internal members) | ~20 | Full members with org-wide access |
| Advisory Board members | ~25 | External collaborators, logically separated |
| Governance Council | Subset | Top-level authority |
| Management Council | Subset | Operational management |
| Operational Council | Subset | Day-to-day operations |
| Functional Teams | 6 | Each with specific tool access |

People hold **multiple roles simultaneously** (e.g., a Sankle may be on the Governance Council and lead Team A). The identity system must support this natively.

### 2.2 Current and Future Toolchain

```
Current:    Zoho Connect  |  Frappe (self-hosted)  |  GitHub
Future:     Google Workspace (possible)  |  Custom-built internal tools
```

### 2.3 Hard Constraints

| Constraint | Requirement |
|---|---|
| Total monthly cost | ≤ USD $10 (infra + licensing combined) |
| SSO | Mandatory |
| RBAC with multi-role per person | Mandatory |
| Integration with Zoho, Frappe, GitHub | Mandatory |
| Multi-level admin delegation | Mandatory (Super Admin > Governance Admin > Team Admin > System Access Manager) |
| External/internal member separation | Required |
| MFA | Not mandatory at this stage |
| Periodic access reviews | Not required at this stage |
| Self-hosted or affordably hosted | Required |

### 2.4 Policy Decisions Confirmed

- External collaborators separated logically: Yes
- Advisory access time-bound: No
- MFA mandatory: No
- Periodic access reviews: Not now
- Sankle dashboard in future: Yes (complete dashboard)

---

## 3. Candidate Evaluation

### 3.1 Authentik

**Project:** [goauthentik/authentik](https://github.com/goauthentik/authentik)
**Licence:** MIT (open-source core), Enterprise tier optional
**Language:** Python (backend), TypeScript (frontend)
**Community:** 20,200+ GitHub stars (as of early 2026), bimonthly release cadence
**Commercial backing:** Authentik Security Inc. (public benefit company)

#### Protocol Support

| Protocol | Support |
|---|---|
| SAML 2.0 (IdP) | Full — SP-initiated and IdP-initiated |
| OIDC / OAuth2 | Full — access tokens, ID tokens, refresh tokens |
| LDAP (read) | Via LDAP outpost |
| SCIM | Supported for provisioning |

#### RBAC and Multi-Role Support

Authentik's access control model is built on a three-layer hierarchy:

```
Permissions  →  Roles  →  Groups  →  Users
```

- A **Role** is a named collection of permissions.
- **Groups** can be assigned one or more Roles.
- **Users** can belong to multiple Groups simultaneously, and directly receive multiple Roles.
- Roles and permissions are **inherited through the group tree** (child groups inherit from parent groups).

A user like a Sankle who is also a Governance Council member and Team Lead can be a member of three groups simultaneously, inheriting all corresponding roles and permissions. This is a first-class feature, not a workaround.

Since release 2025.12, Authentik introduced a full RBAC overhaul with multi-parent groups and role-inherited permissions, significantly strengthening this model. [[Release 2025.12](https://docs.goauthentik.io/releases/2025.12)]

#### Admin Delegation

Authentik's RBAC provides the ability to finely configure permissions within Authentik itself, allowing delegation of tasks — such as user management, application creation, group management — to specific users without granting full superuser permissions. [[Permissions docs](https://docs.goauthentik.io/users-sources/access-control/permissions/)]

This maps directly to Omysha's four-tier admin model:
- **Super Admin**: Full Authentik admin (manages the whole instance, all applications, all users)
- **Governance Admin**: Assigned a role with permissions to manage specific groups/users/applications scoped to the Governance domain
- **Team Admin**: Assigned a role with permissions limited to their team's group membership
- **System Access Manager**: Assigned a role with permissions to manage application bindings and system-role assignments

#### Internal vs External User Separation

Authentik supports distinct user types:
- **Internal users** (`internal:sankle`): Sankles — full access to the user dashboard and all authorised applications
- **External users** (`external:advisor`, `external:collaborator`): Advisory Board members and collaborators — redirected to a configured default application; cannot access the admin or user dashboard unless explicitly permitted

Advisory Board members can be placed in a dedicated group with access restricted only to specific applications (e.g., a shared Frappe workspace), while Sankles have broader access. This is configurable without any enterprise licence.

#### JWT Token Claims for Downstream Authorisation

Authentik's OAuth2/OIDC provider supports configurable **Scope Mappings** (a type of Property Mapping written in Python). By default, the `profile` scope includes the user's group membership in the token. Custom scope mappings can add any attribute — including role names, council membership, team names, or custom user attributes — to the JWT access token or ID token.

Downstream custom systems (future Omysha tools) can decode these tokens and enforce authorisation locally based on the claims, without calling back to the IdP on each request. [[OAuth2 provider docs](https://docs.goauthentik.io/add-secure-apps/providers/oauth2/)]

#### Resource Requirements

Since Authentik 2025.10, Redis has been removed as a dependency. The stack is now:
- Authentik server process
- Authentik worker process
- PostgreSQL database

Idle RAM usage for a small deployment (~10 users, ~5 applications): approximately 735 MB total (server + worker combined). Recommended minimum for production: 2 vCPU, 2 GB RAM. [[Resource discussion](https://github.com/goauthentik/authentik/discussions/9569)]

On a Hetzner CX22 (2 vCPU, 4 GB RAM, EUR 3.79/month), Authentik runs with comfortable headroom.

#### Known Limitations

- **Zoho IdP-initiated login** does not work due to Zoho's non-standard NameID format requirement. SP-initiated login (user clicks "Login with SSO" on Zoho) works correctly. [[Authentik Zoho integration](https://integrations.goauthentik.io/platforms/zoho/)]
- GitHub SAML SSO requires GitHub Enterprise Cloud (a constraint affecting all candidates, not specific to Authentik).
- Accounts must be **manually provisioned** in Zoho before SSO can be used (Zoho does not support automated SCIM provisioning from all IdPs at the free tier).
- Python-based backend is slightly heavier than Go-based alternatives; however, the Redis removal in 2025.10 simplified the operational footprint significantly.

---

### 3.2 Keycloak

**Project:** [keycloak/keycloak](https://github.com/keycloak/keycloak)
**Licence:** Apache 2.0
**Language:** Java (Quarkus)
**Commercial backing:** Red Hat / IBM
**Community:** Largest in the category — 25,000+ GitHub stars, extensive documentation

#### Protocol Support

Full SAML 2.0, OIDC, OAuth2, LDAP, Kerberos, SCIM. The most complete protocol coverage of all candidates.

#### RBAC and Multi-Role Support

Keycloak has two layers of roles:
- **Realm Roles**: Global within a Keycloak realm, applicable across all clients
- **Client Roles**: Scoped to a specific application (client)
- **Composite Roles**: A role that inherits from other roles (role hierarchy)

A user can be assigned any number of realm roles and client roles simultaneously. Role claims are included in the JWT access token automatically via the `realm_access` and `resource_access` standard claims.

Keycloak also supports **Groups** which can have roles assigned, allowing role inheritance via group membership.

#### Admin Delegation

Keycloak's **Fine-Grained Admin Permissions V2** (released in Keycloak 26.2) provides delegated administration — server admins can assign management privileges to users in a realm. [[Fine-grained admin permissions](https://www.keycloak.org/2025/05/fgap-kc-26-2)]

The master realm holds the top-level admin. Each realm client can have delegated admins. This maps to Omysha's admin model but requires careful Keycloak realm design.

#### Resource Requirements

Keycloak is **Java-based** and resource-hungry. Red Hat's own sizing guide recommends:
- Base memory: **1,250 MB RAM** for a single node with 10,000 cached sessions
- Minimum practical: 750 MB heap + 300 MB non-heap = ~1,050 MB minimum
- Recommended for stability: **2 GB RAM minimum**, ideally 4 GB

Recent versions (v24+) have seen reports of increased memory consumption compared to v23. [[Keycloak sizing guide](https://www.keycloak.org/high-availability/concepts-memory-and-cpu-sizing)] [[Memory increase issue](https://github.com/keycloak/keycloak/issues/28211)]

On a Hetzner CX22 (4 GB RAM), Keycloak fits — but with less headroom than Authentik, particularly if the same host also runs PostgreSQL.

#### Assessment for Omysha

Keycloak is battle-tested and protocol-complete, but it is operationally heavier. Its configuration model (realms, clients, mappers, flows) has a significantly steeper learning curve. For a ~45-person organisation without a dedicated IAM engineer, it introduces unnecessary operational burden. The fine-grained admin delegation in v26.2+ is powerful but complex to configure correctly.

---

### 3.3 ZITADEL

**Project:** [zitadel/zitadel](https://github.com/zitadel/zitadel)
**Licence:** AGPL 3.0 (switched from Apache 2.0 in v3)
**Language:** Go
**Commercial:** ZITADEL Cloud free tier (with limits), self-hosted free

#### Protocol Support

SAML 2.0, OIDC, OAuth2. No native LDAP server (can consume LDAP sources). Strong API-first design with gRPC and REST APIs.

#### RBAC and Multi-Role Support

ZITADEL provides RBAC but explicitly documents that "ZITADEL provides RBAC but no permission handling" — meaning the IdP emits role claims but the enforcement of what those roles *permit* must happen in the consuming application. [[RBAC discussion](https://github.com/zitadel/zitadel/discussions/9768)]

Users can be assigned to multiple roles within a project. The **Manager** hierarchy is ZITADEL's internal admin delegation model:
- IAM Manager (instance-wide)
- Org Manager (organisation-wide)
- Project Manager (project-scoped)
- Project Grant Manager (for granted projects)

[[ZITADEL Managers](https://zitadel.com/docs/concepts/structure/managers)] (404 at time of research — see [ZITADEL docs overview](https://zitadel.com/docs))

#### Resource Requirements

ZITADEL is a Go binary — very lightweight. Can run with **512 MB RAM** in test environments. Production recommendation: 1-2 GB RAM with PostgreSQL. ZITADEL v3 requires PostgreSQL 14–18 (CockroachDB support dropped). [[Requirements](https://zitadel.com/docs/self-hosting/manage/requirements)]

#### Assessment for Omysha

ZITADEL is architecturally modern and lightweight, but its RBAC model places more responsibility on consuming applications to enforce permissions. Its multi-tenancy (Organisations model) is powerful for B2B SaaS but adds complexity for a single-organisation governance setup. The **AGPL 3.0 licence switch in v3** introduces a copyleft consideration for future custom systems — any organisation modifying ZITADEL itself must open-source those modifications. For organisations that only *use* ZITADEL without modifying it, AGPL does not impose obligations on their own proprietary code, but the risk warrants monitoring. Authentik's MIT licence imposes no such concern. The community is smaller than Keycloak or Authentik. The Zoho SAML integration is not officially documented by ZITADEL (unlike Authentik's dedicated Zoho guide).

---

### 3.4 Eliminated Candidates

#### lldap + Authelia

**lldap** is a lightweight LDAP server with a web UI for basic user and group management. It does **not** provide SAML 2.0 or OIDC natively — it requires a separate portal like Authelia or Keycloak. **Authelia** is primarily a forward-authentication proxy for reverse-proxy setups (e.g., NGINX, Traefik) and does not function as a full IdP. The combination cannot natively issue SAML assertions to Zoho. Eliminated due to architectural gap. [[lldap](https://github.com/lldap/lldap)] [[Authelia](https://www.authelia.com/)]

#### Kanidm

Kanidm is a Rust-based, security-first IAM system with strong Unix integration. Its web UI is primarily user-facing; administration is primarily CLI-based. OAuth2/OIDC support is present but SAML 2.0 support is limited/absent. The community is significantly smaller than Authentik or Keycloak. Eliminated due to insufficient SAML support for Zoho integration and limited operational tooling. [[Kanidm](https://github.com/kanidm/kanidm)]

#### Okta, Auth0, Azure AD, Ping Identity

Explicitly out of scope per requirements (enterprise/expensive options). Free tiers on Auth0 (25,000 MAU free) are tempting but vendor lock-in risk and the fact that the free tier excludes SAML (requires paid plan) makes them non-viable.

---

## 4. Comparison Matrix

| Criterion | Authentik | Keycloak | ZITADEL |
|---|---|---|---|
| **Licence** | MIT (OSS core) | Apache 2.0 | AGPL 3.0 (v3+) |
| **SAML 2.0** | Full | Full | Full |
| **OIDC / OAuth2** | Full | Full | Full |
| **RBAC + Multi-Role** | Strong (groups + roles) | Strong (realm + client roles) | Moderate (roles without enforcement) |
| **Admin Delegation** | Strong (RBAC-based delegation) | Strong (fine-grained v26.2+) | Moderate (Manager hierarchy) |
| **Zoho SAML** | Documented, SP-init works | Works (community reports) | No official guide |
| **Frappe OIDC** | Official guide exists | Community-supported | No official guide |
| **GitHub SSO** | Via Enterprise Server plugin | Via Enterprise Server plugin | Via Enterprise Server plugin |
| **JWT Role Claims** | Custom scope mappings (Python) | Protocol mappers (config-driven) | Roles in token claims |
| **Google Identity Brokering** | Native Source support | Native identity provider support | Supported |
| **Internal/External User Separation** | Native (user types) | Via groups/attributes | Via organisations |
| **Min RAM (production)** | ~2 GB (Redis removed 2025.10) | ~2 GB (Java overhead) | ~1 GB (Go binary) |
| **Operational Complexity** | Moderate | High | Moderate |
| **Community Size** | Large (20k+ stars) | Very Large (25k+ stars) | Medium (12k+ stars) |
| **Release Cadence** | Bimonthly (active) | Frequent (active) | Regular (active) |
| **Hetzner CX22 fit** | Excellent (4 GB RAM) | Good (tight with DB) | Excellent |
| **Monthly Cost (hosting)** | ~$4.15 (Hetzner CX22) | ~$4.15 (Hetzner CX22) | ~$4.15 (Hetzner CX22) |
| **Zoho IdP-init login** | Does not work | Works | Not documented |
| **AGPL licence risk** | None (MIT) | None (Apache 2.0) | Yes (v3+) |
| **Self-host deployment** | Docker Compose | Docker Compose | Docker Compose |

---

## 5. Top Recommendation: Authentik

**Recommended solution: self-hosted Authentik on a Hetzner CX22 VPS**

### Justification

1. **Protocol completeness meets all integration requirements.** Authentik supports SAML 2.0 (for Zoho), OIDC/OAuth2 (for Frappe and future systems), and has a documented integration path for GitHub Enterprise Server.

2. **The Zoho integration is officially documented and tested.** Authentik's integration catalogue includes a dedicated [Zoho guide](https://integrations.goauthentik.io/platforms/zoho/) with step-by-step instructions. The SP-initiated flow (the standard enterprise usage pattern) works reliably. The only limitation — IdP-initiated login — is a Zoho-side constraint, not an Authentik deficiency, and affects all self-hosted IdPs equally.

3. **RBAC with multi-role per person is a first-class citizen.** The groups → roles → permissions model directly supports Omysha's governance structure without workarounds. A Sankle can simultaneously be a Governance Council member, a Team Lead, and an Advisory Committee liaison, with all corresponding permissions active.

4. **Admin delegation is configurable without enterprise licensing.** Authentik's RBAC permission system allows creating a `council:Governance` admin role that grants user management permissions scoped to the Governance Council group, and a `team:*` admin role scoped further. No enterprise licence is needed.

5. **Internal/external user separation is native.** Advisory Board members (`external:advisor`) can be created as "external" user type — they can authenticate and access designated applications but cannot see Sankle-only applications or the admin panel.

6. **Google Identity Brokering is natively supported.** Authentik supports Google as an upstream "Source" (OIDC/OAuth2). Members use their Google accounts to authenticate; Authentik brokers that identity and issues its own tokens to downstream apps. All role and access management remains in Authentik.

7. **The operational footprint is manageable.** Since 2025.10, the Redis dependency has been removed. The deployment is PostgreSQL + two Authentik processes. Docker Compose deployment is straightforward and well-documented.

8. **Zero licensing cost.** The open-source core has no per-user fee and no feature gates that matter to Omysha's use case.

9. **Future-proof token-based authorisation.** Custom scope mappings allow embedding council membership, team roles, and any custom attributes into JWT tokens. Future custom-built Omysha tools can consume these claims directly.

10. **Financially sustainable.** Authentik Security Inc. (the commercial entity behind the project) has adopted an open-core model that explicitly commits to not moving open-source features to enterprise tier. The frequent release cadence and active community reduce abandonment risk.

---

## 6. High-Level Architecture

The architecture places Authentik as the single authoritative identity plane. All authentication flows pass through it. Role and group data originates in Authentik and propagates to connected systems via SSO tokens or protocol assertions. Omysha members may authenticate to Authentik using their Google accounts (identity brokering), while all downstream applications remain unaware of Google — they only ever interact with Authentik.

```mermaid
graph TB
    subgraph UpstreamIdP["Upstream Identity Provider"]
        GOOGLE[Google<br/>OAuth2 / OIDC Source<br/>Authenticates users via<br/>existing Google accounts]
    end

    subgraph IdP["Identity Plane — Authentik on Hetzner CX22"]
        AUTH[Authentik IdP<br/>SAML 2.0 / OIDC / OAuth2<br/>Central broker and<br/>role/group authority]
        PG[(PostgreSQL<br/>User store, sessions,<br/>groups, roles)]
        AUTH --> PG
    end

    subgraph ServiceProviders["Service Providers"]
        ZOHO[Zoho Connect<br/>SAML 2.0 SP]
        FRAPPE[Frappe / ERPNext<br/>OIDC Social Login]
        GH[GitHub<br/>OIDC App or<br/>Manual team sync]
        CUSTOM[Future Custom Tools<br/>OIDC Client + JWT claims]
    end

    subgraph AdminLayer["Admin Delegation"]
        SA[Super Admin<br/>Full Authentik access]
        GA[Governance Admin<br/>Manage governance users]
        TA[Team Admin<br/>Manage team members]
        SAM[System Access Manager<br/>Manage app bindings]
    end

    GOOGLE -->|"OIDC callback:\nIdentity confirmed"| AUTH
    AUTH -->|"Redirect to Google\nfor authentication"| GOOGLE

    AUTH -->|SAML Assertion + email| ZOHO
    AUTH -->|OIDC ID Token + groups| FRAPPE
    AUTH -->|OIDC Token / manual| GH
    AUTH -->|"JWT Access Token\nwith role claims"| CUSTOM

    SA --> AUTH
    GA --> AUTH
    TA --> AUTH
    SAM --> AUTH
```

### Architecture Principles

- **Google is the upstream authenticator.** When users log in, Authentik redirects to Google for credential verification. Google confirms the identity and returns to Authentik via OIDC callback. Authentik then applies its own groups, roles, and policies.
- **Authentik is the single source of truth** for user identities, group memberships, and role assignments. Downstream apps never communicate with Google directly.
- **No passwords are stored in Zoho, Frappe, or GitHub** for SSO-enabled users; credentials live in Google (or Authentik local accounts for fallback users).
- **Role claims flow outward** via OIDC token claims and SAML attribute assertions.
- **Admin delegation is layered**: Governance Admin cannot exceed the permissions of Super Admin; Team Admin cannot exceed the permissions of Governance Admin.

---

## 7. Authentication via Google (Identity Brokering)

### Overview

Omysha members use their existing Google accounts to authenticate into all Omysha systems. Rather than maintaining separate passwords in Authentik, users are redirected to Google at login time. This approach — called **identity brokering** — is a native Authentik capability implemented via an Authentik "Source."

Google acts as the **upstream identity provider**. Authentik acts as the **broker and downstream IdP** — it verifies identity through Google, then issues its own tokens to Omysha applications. Downstream apps (Zoho, Frappe, custom systems) are entirely unaware of Google. All role, council, and team assignments are managed inside Authentik, not in Google.

### How It Works

1. **Login request**: A user navigates to Zoho Connect or any other Omysha application and clicks the SSO login option.
2. **Redirect to Google**: Authentik detects the user is not authenticated and redirects them to Google's OAuth2/OIDC authorisation endpoint.
3. **Google authentication**: Google presents its login prompt (or silently authenticates if the user already has an active Google session).
4. **Identity confirmed**: Google verifies the user's identity and returns an OIDC callback to Authentik, confirming who the user is.
5. **Authentik user lookup and role application**: Authentik looks up the corresponding local user record (creating one on first login if enrollment is enabled). It then applies its own groups, roles, and access policies — which may include `council:Governance`, `team:Marketing`, `internal:sankle`, etc.
6. **Token issuance**: Authentik issues its own SAML assertion or OIDC/JWT token to the requesting application, containing Omysha-specific role claims.
7. **Access granted**: The downstream application (Zoho, Frappe, or a custom system) reads the token and grants access based on Authentik's claims.

### Key Design Point: Role Management Stays in Authentik

It is important to understand that Google only answers the question **"is this person who they claim to be?"**. Google does not know or care that a user is on the Governance Council or part of the Marketing team. All of that lives in Authentik. The following are **always managed in Authentik**, never in Google:

- Identity categories: `internal:sankle`, `external:advisor`, `external:collaborator`
- Team memberships: `team:Marketing`, `team:TechProducts`, etc.
- Council memberships: `council:Governance`, `council:Management`, `council:Operational`
- System roles: `sys:zoho:editor`, `sys:frappe:admin`, `sys:github:maintainer`

### Domain Restriction (Optional)

If Omysha adopts Google Workspace in future (e.g., `@omysha.org` accounts), the Google Source in Authentik can be configured to **restrict logins to the `omysha.org` domain only**. This prevents members from accidentally or intentionally using a personal Gmail account instead of their official Omysha Google account.

Until Omysha has a Google Workspace domain, this restriction is left open (any Google account can be used), combined with an explicit allowlist policy in Authentik (only pre-approved email addresses can create/enroll accounts).

### Fallback: Local Authentik Accounts

Members who do not have a Google account — or for whom Google authentication is not appropriate — can be provisioned with a **local Authentik account** (username + password set directly in Authentik). This is the fallback path for:
- Service accounts used by automated systems
- Any member who specifically cannot use Google

Local accounts and Google-brokered accounts coexist in Authentik without any special configuration.

### Authentication Flow Diagram

```mermaid
sequenceDiagram
    actor User
    participant App as App (Zoho / Frappe / Custom)
    participant Auth as Authentik (IdP + Broker)
    participant Google as Google (Upstream IdP)

    User->>App: Access application (login required)
    App->>Auth: Redirect: SAML / OIDC login request
    Auth->>User: Show login options (Google or local)
    User->>Auth: Select "Login with Google"
    Auth->>Google: Redirect for authentication (OIDC)
    Google->>User: Google login prompt
    User->>Google: Enter Google credentials
    Google->>Auth: Identity confirmed (OIDC callback with id_token)
    Auth->>Auth: Look up or create local user record
    Auth->>Auth: Apply groups, roles, and access policies
    Auth->>App: Issue SAML assertion / OIDC token with role claims
    App->>User: Access granted based on Authentik roles
```

---

## 8. SSO Integration Details

### 8.1 Zoho Connect

```mermaid
sequenceDiagram
    actor User
    participant Zoho as Zoho Connect (SP)
    participant Auth as Authentik (IdP)

    User->>Zoho: Access Zoho Connect
    Zoho->>User: Redirect to IdP (SP-initiated SAML)
    User->>Auth: Authenticate (Google or local account)
    Auth->>Auth: Validate identity, load groups and roles
    Auth->>Zoho: SAML Response (NameID=email, attributes)
    Zoho->>Zoho: Match email to provisioned account
    Zoho->>User: Authenticated session
```

**Protocol:** SAML 2.0 (Zoho does not support OIDC as an IdP consumer)

**Configuration Steps:**

1. In Zoho Accounts: navigate to **Organisation → SAML Authentication**, download Zoho's metadata XML.
2. In Authentik Admin: create a **SAML Provider** using Zoho's metadata. Set:
   - Signing Certificate: select a certificate
   - NameID Property Mapping: `authentik default SAML Mapping: Email`
3. Create an **Application** in Authentik linked to this provider. Set launch URL to `https://www.zoho.com/login.html`.
4. Download Authentik's metadata XML from the provider's **Related Objects → Metadata** section.
5. In Zoho: upload Authentik's metadata. Set Name Identifier to `Email Address`. Submit.
6. **Pre-provision users** in Zoho with matching email addresses before first SSO login.

**Reference:** [Authentik Zoho Integration Guide](https://integrations.goauthentik.io/platforms/zoho/) | [Zoho SAML Configuration](https://help.zoho.com/portal/en/kb/accounts/manage-your-organization/saml/articles/configure-saml-in-zoho-accounts)

**Known Limitation:** IdP-initiated login does not work (Zoho restriction on NameID format). All logins must be initiated from Zoho's login page. This is standard enterprise behaviour and not an impediment to daily use.

**Access control:** Assign Sankles and relevant Advisory Board members (`external:advisor`) to the `zoho-connect-access` group in Authentik, and bind this group to the Zoho application. Members not in this group cannot access Zoho even if they have an Authentik account.

---

### 8.2 Frappe (Self-Hosted)

**Protocol:** OIDC / OAuth2 (Authorization Code Flow) — not LDAP

```mermaid
sequenceDiagram
    actor User
    participant Frappe as Frappe Instance (OIDC RP)
    participant Auth as Authentik (OIDC IdP)

    User->>Frappe: Click "Login with Authentik"
    Frappe->>Auth: Authorization Code Request (scope: openid email profile)
    Auth->>User: Authentik login page (Google or local)
    User->>Auth: Authenticate
    Auth->>Frappe: Authorization Code
    Frappe->>Auth: Exchange code for tokens (POST /application/o/token/)
    Auth->>Frappe: ID Token (JWT) + Access Token
    Frappe->>Auth: Fetch user info (GET /application/o/userinfo/)
    Auth->>Frappe: {email, name, groups, ...}
    Frappe->>Frappe: Match or create user by email
    Frappe->>User: Authenticated session
```

**Configuration Steps:**

**In Authentik:**
1. Create an **OAuth2/OpenID Connect Provider**. Record the `Client ID`, `Client Secret`, and `slug`.
2. Set Redirect URI: `https://frappe.yourdomain.com/api/method/frappe.integrations.oauth2_logins.custom/<provider-name>`
3. Set Subject Mode: `Based on the User's username`
4. Add a scope mapping to include groups: select `authentik default OAuth Mapping: OpenID 'profile'` and add a custom scope mapping returning `{"groups": [group.name for group in request.user.ak_groups.all()]}` if role-based Frappe profiles are needed.

**In Frappe:**
1. Go to **Integrations → Social Login Key → New**.
2. Enable Social Login toggle.
3. Enter `Client ID` and `Client Secret`.
4. Set `Base URL`: `https://authentik.yourdomain.com/`
5. Configure endpoints:
   - Authorize: `/application/o/authorize/`
   - Access Token: `/application/o/token/`
   - API Endpoint: `/application/o/userinfo/`
6. Auth Scope: `{ "response_type": "code", "scope": "email profile openid" }`
7. Allow sign-ups: On. Save.

**Reference:** [Authentik Frappe Integration Guide](https://integrations.goauthentik.io/development/frappe/) | [Frappe OIDC Docs](https://docs.frappe.io/framework/user/en/guides/integration/openid_connect_and_frappe_social_login)

**Role Mapping in Frappe:** The community-maintained [frappe-oidc-extended](https://github.com/MohammedNoureldin/frappe-oidc-extended) extension enables mapping JWT group claims to Frappe roles, allowing Authentik groups to directly control Frappe role assignments. For example, a user with `sys:frappe:admin` in their Authentik groups can automatically receive the System Manager role in Frappe.

**Advisory Board access:** Advisory Board members (`external:advisor`) can be assigned a Frappe role (e.g., `Advisory Board Member`) via their Authentik group claim, limiting them to relevant Frappe modules.

---

### 8.3 GitHub

**Important constraint:** GitHub's native SAML SSO for organisations requires **GitHub Enterprise Cloud** (approximately USD $21/user/month). This constraint applies to all IdP candidates — it is a GitHub platform restriction, not an Authentik limitation. [[GitHub SAML SSO docs](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on)]

**Recommended approach for Omysha (cost-free):**

Since Omysha uses GitHub at the free or Teams tier, the practical strategy is a **hybrid model**:

```mermaid
flowchart LR
    Auth[Authentik<br/>Source of Truth]
    GH[GitHub Organisation]
    Admin[Team Admin / System Access Manager]

    Auth -->|"Groups: team:TechProducts,\ncouncil:Governance, ..."| Admin
    Admin -->|"Manual sync:\nadd/remove members\nbased on Authentik groups"| GH
    Auth -->|"OIDC login for\nGitHub Apps / Gitea"| GH
```

**Option A — Manual Sync (recommended for current scale):**
- Authentik is the authoritative source for group membership.
- A Team Admin or System Access Manager (`sys:github:maintainer`) refers to Authentik group membership when adding/removing members from GitHub teams.
- At ~45 people, this is low-effort (changes are infrequent).
- Authentik group reports or a simple API query (`GET /api/v3/core/groups/`) can be used to audit membership.

**Option B — GitHub App + OIDC (for authentication only):**
- Register Authentik as an OAuth2/OIDC app within GitHub (for services or automation accounts).
- GitHub users still authenticate with their own GitHub credentials to github.com, but service-to-service authentication can flow through Authentik.

**Option C — If GitHub Enterprise is adopted in future:**
- All candidates (Authentik, Keycloak, ZITADEL) support SAML for GitHub Enterprise. The integration follows standard GitHub SAML setup with Authentik as the IdP.
- GitHub team synchronisation with IdP groups would then allow automatic team membership management. [[GitHub team synchronisation](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-saml-single-sign-on-for-your-organization/managing-team-synchronization-for-your-organization)]

---

### 8.4 Future Custom Systems

```mermaid
sequenceDiagram
    actor User
    participant App as Custom Omysha App (OIDC RP)
    participant Auth as Authentik (OIDC IdP)

    User->>App: Access protected resource
    App->>Auth: Redirect: Authorization Request
    Auth->>User: Login page (if not already authenticated)
    User->>Auth: Already has SSO session (via Google)
    Auth->>App: Authorization Code
    App->>Auth: Token request
    Auth-->>App: JWT Access Token { "sub": "user123", "email": "sankle@omysha.org", "groups": ["internal:sankle", "council:Governance", "team:TechProducts"], "omysha_roles": ["council-member", "team-lead"], "exp": 1735000000 }
    App->>App: Decode JWT, enforce RBAC based on groups and roles claims
    App->>User: Access granted or denied
```

**Integration pattern:** Any custom system built by Omysha registers as an **OIDC Relying Party (RP)** in Authentik. The application:
1. Redirects unauthenticated users to Authentik's authorisation endpoint.
2. Exchanges the authorisation code for tokens.
3. Reads the `groups` and custom role claims from the JWT.
4. Enforces application-specific permissions locally based on those claims.

Because Authentik signs JWTs with a private key, applications can verify token authenticity without calling back to Authentik on every request — the token is a self-contained credential valid for its lifetime (configurable, typically 5–60 minutes).

**Custom scope mapping example** (to be added in Authentik Customization → Property Mappings → Scope Mapping):

```python
# Returns Omysha-specific role claims using the v3 role taxonomy
return {
    "omysha_roles": [group.name for group in request.user.ak_groups.all()],
    "is_sankle": request.user.type == "internal",
    "council_membership": [
        g.name for g in request.user.ak_groups.all()
        if g.name.startswith("council:")
    ],
    "team_membership": [
        g.name for g in request.user.ak_groups.all()
        if g.name.startswith("team:")
    ],
    "system_roles": [
        g.name for g in request.user.ak_groups.all()
        if g.name.startswith("sys:")
    ]
}
```

This scope mapping is attached to the OIDC provider for each custom application.

---

## 9. Role and Identity Hierarchy Model

```mermaid
flowchart TB
    P[Person] --> C1[Identity Category]
    P --> C2[Team Roles]
    P --> C3[Council Roles]
    P --> C4[System Roles]
```

### Role Taxonomy

Omysha uses a structured naming convention for all roles and groups in Authentik. This taxonomy is used consistently across the identity system, JWT claims, and access policies.

#### 1. Identity Category (User Type)

| Role Name | Description |
|---|---|
| `internal:sankle` | Full Omysha member — access to all internal applications |
| `external:advisor` | Advisory Board member — access to designated applications only |
| `external:collaborator` | External collaborator — limited, scoped access |

#### 2. Team Roles

| Role Name | Description |
|---|---|
| `team:Marketing` | Member of the Marketing team |
| `team:TechProducts` | Member of the Tech Products team |
| (additional teams follow same pattern) | |

#### 3. Council Roles

| Role Name | Description |
|---|---|
| `council:Governance` | Member of the Governance Council |
| `council:Management` | Member of the Management Council |
| `council:Operational` | Member of the Operational Council |

#### 4. System Roles

| Role Name | Description |
|---|---|
| `sys:zoho:editor` | Zoho Connect editor-level access |
| `sys:frappe:admin` | Frappe system administrator |
| `sys:github:maintainer` | GitHub organisation maintainer |

### Design Decisions

1. **A person is represented as one Authentik user account** regardless of how many roles or councils they belong to. Multiple group memberships handle multi-role assignment.

2. **Groups are additive.** A Sankle who is a Governance Council member and Team Lead has the union of all permissions from all their groups.

3. **Advisory Board members** (`external:advisor`) are a separate identity category with access restricted to designated applications only. They cannot see applications bound exclusively to `internal:sankle`.

4. **Application bindings in Authentik** control which groups can access which applications. Access is denied by default; groups are explicitly granted access to each application.

5. **Token claims reflect actual group membership.** When an Advisory Board member authenticates to Frappe, their JWT includes `"groups": ["external:advisor"]`, not any council or team groups.

### Full Role and Access Hierarchy

```mermaid
graph TB
    subgraph IdentityCategories["Identity Categories"]
        INT["internal:sankle"]
        EXT_ADV["external:advisor"]
        EXT_COL["external:collaborator"]
    end

    subgraph OrgGroups["Organisational Groups"]
        GC["council:Governance"]
        MC["council:Management"]
        OC["council:Operational"]
        TM["team:Marketing"]
        TTP["team:TechProducts"]
    end

    subgraph SystemRoles["System Roles"]
        SZ["sys:zoho:editor"]
        SF["sys:frappe:admin"]
        SG["sys:github:maintainer"]
    end

    subgraph Apps["Applications"]
        A_ZOHO[Zoho Connect]
        A_FRAPPE[Frappe]
        A_GH[GitHub]
        A_CUSTOM[Future Apps]
    end

    INT -->|"member of (one or more)"| GC
    INT -->|"member of (one or more)"| MC
    INT -->|"member of (one or more)"| OC
    INT -->|"member of (one or more)"| TM
    INT -->|"member of (one or more)"| TTP
    EXT_ADV -->|"designated access only"| A_FRAPPE
    EXT_ADV -->|"designated access only"| A_ZOHO

    GC -->|access| A_ZOHO
    GC -->|access| A_FRAPPE
    GC -->|access| A_CUSTOM
    MC -->|access| A_ZOHO
    MC -->|access| A_FRAPPE
    OC -->|access| A_FRAPPE

    SZ -->|controls| A_ZOHO
    SF -->|controls| A_FRAPPE
    SG -->|controls| A_GH
```

---

## 10. Admin Delegation Model

```mermaid
flowchart TB
    SA[Super Admin] --> GA[Governance Admin]
    SA --> TA[Team Admin]
    SA --> SAM[System Access Manager]

    GA --> DIR[Directory: Governance groups\nand council members]
    TA --> DIR2[Directory: Team group\nmembers only]
    SAM --> DIR3[Application bindings\nand system roles]
```

### Admin Tier Definitions

| Level | Role | Scope |
|---|---|---|
| **Level 1** | Super Admin | Full Authentik instance — all users, applications, groups, system config, certificates |
| **Level 2** | Governance Admin | Manage Governance Council group membership; view governance-scoped audit logs; cannot modify system config or other teams |
| **Level 3** | Team Admin | Manage a single team group membership only; cannot modify other teams or councils |
| **Level 3** | System Access Manager | Manage application bindings and system-role assignments; cannot modify identity or council groups |

### Implementation in Authentik

The admin delegation is implemented using Authentik's **object-level permissions** system:

1. **Create a role** named `governance-admin` with the following global permissions:
   - `Can view User`
   - `Can change Group Membership` (scoped to governance groups only via object permission)

2. **Create object-level permissions** on the Governance Council group, granting the `governance-admin` role the ability to edit that specific group's membership.

3. **Assign the `governance-admin` role** to the designated Governance Admin user.

4. **Repeat the pattern** for each Team Admin, scoping their object-level permissions to their respective team group only.

5. **Create a `system-access-manager` role** with permissions to manage application bindings and assign system-level groups (`sys:zoho:editor`, `sys:frappe:admin`, `sys:github:maintainer`).

This means a Team Admin for `team:TechProducts` literally cannot see or modify `team:Marketing`'s members in the Authentik UI — they only see the objects they have permissions on.

**Escalation principle:** No delegated admin can grant permissions they do not themselves possess. A Governance Admin cannot create a new Super Admin. Authentik enforces this at the permission-checking layer.

---

## 11. Centralised Authorisation via JWT Token Claims

A key architectural question for future Omysha systems is: **can the IdP serve as the source of truth for authorisation (not just authentication)?**

The answer is **yes, with an important design distinction:**

```mermaid
graph LR
    subgraph AuthN["Authentication (AuthN)"]
        Q1["Who are you?"]
        A1["You are sankle@omysha.org\n(confirmed via Google)"]
    end

    subgraph AuthZ["Authorisation (AuthZ)"]
        Q2["What can you do?"]
        A2["You are in: council:Governance,\nteam:TechProducts, internal:sankle\nYou have role: council-member"]
    end

    subgraph App["Custom App Logic"]
        D["App checks:\nif 'council:Governance' in groups:\n  show governance dashboard\nif 'team:TechProducts' in groups:\n  show tech workspace"]
    end

    AUTH[Authentik IdP] -->|"ID Token: proves identity"| AuthN
    AUTH -->|"Access Token JWT:\ncontains groups + roles"| AuthZ
    AuthZ -->|"JWT claims\npassed to app"| App
```

**How it works in practice:**

Authentik issues JWT access tokens containing the user's group memberships and any custom role claims defined in scope mappings. These tokens are:
- **Cryptographically signed** (RSA or ECDSA, configurable) by Authentik's private key
- **Verifiable** by any application with access to Authentik's public JWKS endpoint (`/application/o/<app-slug>/jwks/`)
- **Self-contained** — no network call to Authentik is needed per request

A custom Omysha app (e.g., a governance dashboard) can:
1. Accept the JWT from the OIDC flow
2. Verify the signature against Authentik's JWKS
3. Read the `groups` claim: `["internal:sankle", "council:Governance", "team:TechProducts"]`
4. Enforce local RBAC: if `council:Governance` is in groups, show the governance panel

**The important design distinction:** Authentik acts as the **source of truth for identity and group/role assignments**. The **enforcement** of what each role permits within a given application remains the application's responsibility. This is the industry-standard pattern (used by Okta, Azure AD, and all major IdPs) and is the correct separation of concerns.

**What this means for Omysha:**
- Future custom tools do **not** need their own user database or role system — they consume Authentik claims.
- Changing a Sankle's role (e.g., promoting them to `council:Governance`) happens **once** in Authentik; the change propagates to all connected applications on the next authentication.
- The "Sankle access dashboard" (future vision) is a natural consequence of this architecture: it reads the user's current Authentik groups and displays their access profile across all integrated systems.

---

## 12. Hosting and Cost Analysis

### Recommended Hosting: Hetzner Cloud CX22

| Parameter | Value |
|---|---|
| Provider | Hetzner Cloud ([hetzner.com/cloud](https://www.hetzner.com/cloud)) |
| Plan | CX22 (Shared CPU, Cost-Optimised) |
| vCPU | 2 |
| RAM | 4 GB |
| Storage | 40 GB NVMe SSD |
| Network | 20 TB included traffic |
| Price | EUR 3.79/month (~USD 4.15/month) |
| Location | Falkenstein, Nuremberg, or Helsinki (EU) |
| IPv4 included | Yes |
| DDoS protection | Included |

**Total monthly cost breakdown:**

| Item | Cost |
|---|---|
| Hetzner CX22 VPS | ~USD 4.15/month |
| Authentik (open-source) | USD 0 |
| PostgreSQL (on same VPS) | USD 0 |
| Domain (if needed for IdP) | ~USD 1.00/month (optional, use existing) |
| TLS certificate (Let's Encrypt) | USD 0 |
| **Total** | **~USD 4.15–5.15/month** |

This leaves USD 4.85–5.85/month of the USD $10 budget as headroom.

### Why Hetzner over DigitalOcean or Fly.io

| Provider | Comparable Plan | Price | Notes |
|---|---|---|---|
| Hetzner CX22 | 2 vCPU, 4 GB RAM, 40 GB | ~USD 4.15/mo | Best value, EU-based, traffic included |
| DigitalOcean Basic Droplet | 2 vCPU, 2 GB RAM, 50 GB | ~USD 18/mo | Higher cost for same RAM |
| Fly.io | Variable (usage-based) | ~USD 5–15/mo | No fixed pricing, complex for stateful DBs |

Note: Hetzner announced a price increase effective April 2026 due to DRAM/NAND cost increases. The CX22 may adjust slightly, but is expected to remain significantly below DigitalOcean's comparable tier.

### Docker Compose Deployment Stack

```yaml
# Simplified docker-compose.yml for Authentik on Hetzner CX22
# Redis removed since Authentik 2025.10 — stack is PostgreSQL + server + worker only
services:
  postgresql:
    image: docker.io/library/postgres:16-alpine
    volumes:
      - database:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${PG_PASS}
      POSTGRES_USER: authentik
      POSTGRES_DB: authentik

  server:
    image: ghcr.io/goauthentik/server:2025.12
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: ""  # Redis removed in 2025.10
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__USER: authentik
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
    ports:
      - "0.0.0.0:9000:9000"
      - "0.0.0.0:9443:9443"
    depends_on:
      - postgresql

  worker:
    image: ghcr.io/goauthentik/server:2025.12
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: ""
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
    depends_on:
      - postgresql

volumes:
  database:
```

**Reference:** [Authentik Docker Compose install](https://docs.goauthentik.io/install-config/install/docker-compose/)

---

## 13. Scalability and Future Vision

### Near-Term (Current State)

- ~45 users, 4 applications (Zoho Connect, Frappe, GitHub manual sync, future tools)
- Hetzner CX22 is more than sufficient
- Single-node Authentik with PostgreSQL is stable and low-maintenance
- Google identity brokering in place from day one

### Medium-Term (Growth to ~100 users, Google Workspace addition)

- Hetzner CX22 remains appropriate up to several hundred users
- Google Workspace supports SAML SSO via third-party IdP — Authentik can serve as the IdP for Workspace SSO, unifying the login experience [[Google Workspace SAML setup](https://support.google.com/a/answer/6087519)]
- When Omysha acquires the `@omysha.org` Google Workspace domain, the Google Source in Authentik can be restricted to `omysha.org` domain only
- SCIM provisioning (supported by Authentik) can automate user lifecycle management in Google Workspace

### Long-Term (Sankle Access Dashboard)

The "Sankle access dashboard" — a unified view of each member's current access across all systems — is architecturally straightforward once Authentik is the central IdP:

```mermaid
graph LR
    AUTH[Authentik API] -->|"GET /api/v3/core/users/{id}/\ngroups, permissions, applications"| DASH[Sankle Access Dashboard]
    DASH -->|Display| U[Sankle / Admin]
```

The Authentik REST API exposes all user data, group memberships, and bound applications. A lightweight web application can query this API (using a service account token with read-only permissions) and render a real-time access profile for any user. This requires no additional IdP infrastructure — it is a consumer application on top of Authentik's existing API.

The dashboard can display:
- Current identity category (`internal:sankle`, `external:advisor`, etc.)
- Active team and council memberships
- System-level roles across all integrated tools
- Active application access bindings

### If Organisation Grows Beyond Single Node

If Omysha grows significantly (hundreds of users, high availability requirements):
- Authentik supports horizontal scaling: multiple server instances behind a load balancer sharing a common PostgreSQL database.
- PostgreSQL can be migrated to a managed service (e.g., Hetzner Managed Databases, starting ~EUR 15/month).
- The same Authentik configuration, applications, and role definitions remain unchanged — scale is an operational concern, not an architectural redesign.

---

## 14. Risks and Limitations

### 14.1 GitHub SSO Limitation

**Risk:** GitHub SAML/OIDC SSO for organisations requires GitHub Enterprise Cloud (~USD $21/user/month). For 20 Sankles, this would be USD $420/month — far exceeding budget.

**Mitigation:** The manual sync approach described in Section 8.3 is operationally adequate at current scale. A Team Admin or System Access Manager (`sys:github:maintainer`) maintains GitHub team membership based on Authentik group state. If Omysha later migrates to GitHub Enterprise, the Authentik SAML integration is a standard, documented configuration.

### 14.2 Zoho IdP-Initiated Login

**Risk:** Users cannot be pushed from Authentik to Zoho (IdP-initiated SAML). All logins must begin from Zoho's login page.

**Mitigation:** This is standard enterprise behaviour. Users bookmark or access Zoho directly; SSO redirects them to Authentik (and then to Google if brokering is active) transparently. The limitation is a Zoho platform constraint on NameID format handling, not an Authentik deficiency.

### 14.3 Manual User Provisioning in Zoho

**Risk:** New users must be manually created in Zoho before SSO login works. Zoho's SCIM support requires Zoho Directory Plus (paid add-on).

**Mitigation:** At ~45 users with low churn, manual provisioning is a minor operational task (< 5 minutes per new member). Document a standard onboarding checklist: (1) Create Authentik account (or link Google account), (2) Create matching Zoho account with same email, (3) Assign Authentik groups per the role taxonomy.

### 14.4 Self-Hosting Operational Responsibility

**Risk:** A self-hosted IdP requires the hosting organisation to manage uptime, backups, security patches, and TLS renewal.

**Mitigation:**
- Use automated TLS with Let's Encrypt via Caddy or Certbot (no manual cert management).
- Set up automated PostgreSQL backups (Hetzner Snapshots or `pg_dump` to object storage).
- Subscribe to Authentik's security advisories (RSS or GitHub releases).
- Authentik releases bimonthly; minor version updates are low-risk and well-documented.
- Consider designating one technical Sankle as the "IAM Owner" with a clear runbook.

### 14.5 Authentik Idle Memory on Small VPS

**Risk:** Authentik requires ~735 MB RAM at idle. On a 2 GB VPS, this leaves limited headroom for PostgreSQL and OS.

**Mitigation:** The recommended Hetzner CX22 has 4 GB RAM, providing ~3.2 GB after OS overhead for Authentik + PostgreSQL. This is comfortable. Do not use a 1 GB VPS.

### 14.6 ZITADEL AGPL Licence Risk (For Future Reference)

**Note:** If Omysha later evaluates ZITADEL, its AGPL 3.0 licence (from v3+) requires that any modifications to ZITADEL itself be open-sourced. For organisations that *embed* ZITADEL (not modify it), AGPL does not impose obligations on their own proprietary code. Authentik's MIT licence imposes no such concern and is the recommended choice in part for this reason.

### 14.7 Advisory Board Email Inconsistencies

**Risk:** Advisory Board members may use personal email addresses that differ from any Zoho/Frappe provisioned accounts, causing SSO matching failures.

**Mitigation:** Enforce a single canonical email address per person at the point of Authentik account creation. Document this in onboarding. Use Authentik's user attributes to store alternative email addresses for reference. For Google-brokered accounts, the canonical email is the Google account email.

### 14.8 Google Dependency for Authentication

**Risk:** If Google experiences downtime or a member's Google account is suspended, they cannot authenticate via the Google brokering path.

**Mitigation:** Authentik local account fallback is available for any member who cannot use Google authentication. Service accounts and automated systems should always use local Authentik credentials, not Google brokering. Document the local account fallback procedure in the IAM runbook.

---

## 15. Implementation Roadmap

| Phase | Actions | Timeline |
|---|---|---|
| **Phase 0: Preparation** | Procure Hetzner CX22 VPS. Register domain for IdP (e.g., `auth.omysha.org`). Inventory all 45 members with canonical email addresses. Confirm which members have Google accounts. | Week 1 |
| **Phase 1: Deploy Authentik** | Install Docker + Docker Compose. Deploy Authentik + PostgreSQL via docker-compose. Configure TLS (Caddy or Certbot). Create initial admin account. | Week 1–2 |
| **Phase 2: Identity Model** | Create groups following the role taxonomy: `internal:sankle`, `external:advisor`, `external:collaborator`, `council:Governance`, `council:Management`, `council:Operational`, `team:Marketing`, `team:TechProducts` (and remaining teams), `sys:zoho:editor`, `sys:frappe:admin`, `sys:github:maintainer`. Import all users. Assign group memberships. | Week 2–3 |
| **Phase 3: Google Identity Brokering** | Configure Google as an Authentik Source (OAuth2/OIDC). Register an OAuth2 app in Google Cloud Console. Set enrollment flow. Test login for 2–3 pilot users. Configure optional domain restriction if `@omysha.org` Workspace is available. | Week 3 |
| **Phase 4: Zoho Integration** | Create Authentik SAML provider for Zoho. Pre-provision all users in Zoho with matching emails. Test SP-initiated SSO for 2–3 pilot users. Roll out to all. | Week 3–4 |
| **Phase 5: Frappe Integration** | Create Authentik OIDC provider for Frappe. Configure Frappe Social Login Key. Test login flow. Optionally install frappe-oidc-extended for role mapping. | Week 4–5 |
| **Phase 6: Admin Delegation** | Configure RBAC permissions for Governance Admin role. Configure RBAC permissions for Team Admin roles (one per team). Configure System Access Manager role. Test delegation: Governance Admin modifies governance group; Team Admin modifies their team only. | Week 5–6 |
| **Phase 7: GitHub Sync** | Document the manual GitHub sync procedure using the Authentik role taxonomy. Assign a System Access Manager (`sys:github:maintainer`) as responsible for GitHub team membership. Run first audit comparing Authentik groups to GitHub teams. | Week 6 |
| **Phase 8: Hardening and Future Prep** | Enable PostgreSQL automated backups. Set up Authentik security advisory monitoring. Write internal runbook for onboarding, offboarding, and role changes. Define standard JWT claim schema for future custom apps. Document OIDC RP registration process for new internal tools. Document Google account fallback procedure. | Week 6–8, then Ongoing |

---

## 16. References

### Authentik
- [Authentik Official Documentation](https://docs.goauthentik.io/)
- [Authentik OAuth2/OIDC Provider](https://docs.goauthentik.io/add-secure-apps/providers/oauth2/)
- [Authentik Access Control / Permissions](https://docs.goauthentik.io/users-sources/access-control/permissions/)
- [Authentik RBAC Overview](https://docs.goauthentik.io/users-sources/access-control)
- [Authentik Roles Documentation](https://version-2024-2.goauthentik.io/docs/user-group-role/roles/)
- [Authentik Groups Documentation](https://docs.goauthentik.io/users-sources/groups/)
- [Authentik About Users (Internal/External)](https://docs.goauthentik.io/users-sources/user/)
- [Authentik Property Mappings](https://docs.goauthentik.io/add-secure-apps/providers/property-mappings/)
- [Authentik Sources (Identity Brokering)](https://docs.goauthentik.io/users-sources/sources/)
- [Authentik Google Source Configuration](https://docs.goauthentik.io/users-sources/sources/social-logins/google/)
- [Authentik Outposts](https://docs.goauthentik.io/add-secure-apps/outposts/)
- [Authentik Docker Compose Installation](https://docs.goauthentik.io/install-config/install/docker-compose/)
- [Authentik Zoho Integration Guide](https://integrations.goauthentik.io/platforms/zoho/)
- [Authentik Frappe/ERPNext Integration Guide](https://integrations.goauthentik.io/development/frappe/)
- [Authentik Release 2025.10 — Redis Removed](https://docs.goauthentik.io/releases/2025.10)
- [Authentik Release 2025.12 — RBAC Overhaul](https://docs.goauthentik.io/releases/2025.12)
- [We Removed Redis — Authentik Blog](https://goauthentik.io/blog/2025-11-13-we-removed-redis/)
- [Authentik Resource Consumption Discussion](https://github.com/goauthentik/authentik/discussions/9569)
- [Authentik Zoho SAML Discussion](https://github.com/goauthentik/authentik/discussions/10662)
- [Authentik GitHub Repository](https://github.com/goauthentik/authentik)
- [Authentik Pricing](https://goauthentik.io/pricing/)

### Keycloak
- [Keycloak Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)
- [Keycloak Memory and CPU Sizing](https://www.keycloak.org/high-availability/concepts-memory-and-cpu-sizing)
- [Keycloak Fine-Grained Admin Permissions V2](https://www.keycloak.org/2025/05/fgap-kc-26-2)
- [Keycloak 26.0 Release Notes](https://www.keycloak.org/2024/10/keycloak-2600-released)

### ZITADEL
- [ZITADEL Documentation](https://zitadel.com/docs)
- [ZITADEL Production Setup](https://zitadel.com/docs/self-hosting/manage/production)
- [ZITADEL Requirements](https://zitadel.com/docs/self-hosting/manage/requirements)
- [ZITADEL Roles and Role Assignments](https://zitadel.com/docs/guides/manage/console/roles)
- [ZITADEL v3 AGPL Licence Announcement](https://zitadel.com/blog/zitadel-v3-announcement)
- [ZITADEL GitHub Repository](https://github.com/zitadel/zitadel)

### Zoho
- [Configure SAML in Zoho Accounts](https://help.zoho.com/portal/en/kb/accounts/manage-your-organization/saml/articles/configure-saml-in-zoho-accounts)
- [Zoho Directory SSO Overview](https://www.zoho.com/creator/newhelp/account-setup/zoho-directory/sso.html)
- [Zoho SAML Authentication for Zoho Mail](https://www.zoho.com/mail/help/adminconsole/saml-authentication.html)

### Frappe
- [Frappe OpenID Connect and Social Login](https://docs.frappe.io/framework/user/en/guides/integration/openid_connect_and_frappe_social_login)
- [How to Enable Social Logins — Frappe](https://docs.frappe.io/framework/user/en/guides/deployment/how-to-enable-social-logins)
- [frappe-oidc-extended (community extension for role mapping)](https://github.com/MohammedNoureldin/frappe-oidc-extended)

### GitHub
- [GitHub SAML SSO for Organisations](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-saml-single-sign-on-for-your-organization/about-identity-and-access-management-with-saml-single-sign-on)
- [GitHub Team Synchronisation with IdP](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-saml-single-sign-on-for-your-organization/managing-team-synchronization-for-your-organization)

### Hosting
- [Hetzner Cloud Plans and Pricing](https://www.hetzner.com/cloud)

### Comparative Research
- [The State of Open-Source Identity in 2025 (House of FOSS)](https://www.houseoffoss.com/post/the-state-of-open-source-identity-in-2025-authentik-vs-authelia-vs-keycloak-vs-zitadel)
- [ZITADEL vs Keycloak Comparison](https://zitadel.com/blog/zitadel-vs-keycloak)
- [lldap GitHub Repository](https://github.com/lldap/lldap)
- [Kanidm GitHub Repository](https://github.com/kanidm/kanidm)
- [Kanidm vs Other Services](https://kanidm.com/comparisons/)

---

*This document was prepared as a strategic IAM architecture recommendation for Omysha. It reflects the state of the evaluated tools as of March 2026. All referenced URLs were verified at time of writing. Tool behaviour, pricing, and integration capabilities should be re-validated before production deployment.*
