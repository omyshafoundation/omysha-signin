# Omysha Centralised Identity & Access System --- Research (Full Version)

------------------------------------------------------------------------

## 0. Executive Summary

For Omysha's scale (\~20 internal members + \~25 advisory members) and a
strict budget cap of USD 10/month, the most realistic and sustainable
approach is:

1.  Deploy a self-hosted Identity Provider (IdP) on a low-cost VPS.
2.  Use it as the central system for:
    -   Authentication (SSO)
    -   Role management
    -   Authorisation reuse across systems

Top practical options:

-   Option A (Recommended): authentik (self-hosted)
-   Option B: Keycloak (self-hosted)
-   Option C: ZITADEL Cloud Free (hosted, with constraints)

------------------------------------------------------------------------

## 1. Organisational Context

### Structure

-   \~20 active Sankles
-   \~25 Advisory members
-   6 functional teams
-   Governance, Management, Operational Councils
-   Individuals can hold multiple roles

### Policy Decisions Confirmed

-   External collaborators separated logically: Yes
-   Advisory access time-bound: No
-   MFA mandatory: No
-   Periodic access reviews: Not now
-   Sankle dashboard in future: Yes (complete dashboard)

------------------------------------------------------------------------

## 2. What Centralisation Means

### Authentication

Single login identity used across Zoho, Frappe, GitHub, and future
systems.

### Authorisation

Roles and groups managed centrally and consumed by all systems.

------------------------------------------------------------------------

## 3. Proposed High-Level Architecture

``` mermaid
flowchart LR
  U[Users: Sankles + Advisory + External] -->|SSO| IDP[Central IdP / Directory]
  IDP -->|SAML/OIDC| ZOHO[Zoho]
  IDP -->|OIDC/LDAP| FRAPPE[Frappe]
  IDP -->|SAML (Enterprise)| GITHUB[GitHub]
  IDP -->|OIDC + Claims| CUSTOM[Future Systems]
```

------------------------------------------------------------------------

## 4. Role & Governance Model

``` mermaid
flowchart TB
  P[Person] --> C1[Identity Category]
  P --> C2[Team Roles]
  P --> C3[Council Roles]
  P --> C4[System Roles]
```

### Role Categories

1.  Identity Category
    -   internal:sankle
    -   external:advisor
    -   external:collaborator
2.  Team Roles
    -   team:Marketing
    -   team:TechProducts
    -   etc.
3.  Council Roles
    -   council:Governance
    -   council:Management
    -   council:Operational
4.  System Roles
    -   sys:zoho:editor
    -   sys:frappe:admin
    -   sys:github:maintainer

------------------------------------------------------------------------

## 5. Option Evaluation

### Option A --- authentik (Recommended)

Strengths: - Open source IdP - Supports OIDC, OAuth2, SAML, LDAP -
Modern UI - Good small-organisation fit

References: - https://github.com/goauthentik/authentik -
https://docs.goauthentik.io/providers/

Budget: - Self-hosted, no per-user fees - VPS cost only

------------------------------------------------------------------------

### Option B --- Keycloak

Strengths: - Mature and widely adopted - Enterprise-grade reliability

Trade-off: - Slightly heavier operational footprint

------------------------------------------------------------------------

### Option C --- ZITADEL Cloud Free

Strengths: - Hosted option - Free plan available

Reference: - https://zitadel.com/pricing

Constraint: - Custom domain and advanced features require paid plan

------------------------------------------------------------------------

## 6. System Integration Evidence

### Zoho SAML SSO

https://help.zoho.com/portal/en/kb/accounts/sign-in-za/articles/sign-in-using-saml

### Frappe LDAP Integration

https://docs.frappe.io/framework/user/en/integration/ldap-integration

### Frappe OAuth Integration

https://docs.frappe.io/framework/user/en/guides/integration/how_to_set_up_oauth

### GitHub SAML (Enterprise Cloud Required)

https://docs.github.com/enterprise-cloud/latest/organizations/managing-saml-single-sign-on-for-your-organization

### Google Workspace SAML

https://support.google.com/a/answer/12032922

------------------------------------------------------------------------

## 7. Hosting Strategy Under USD 10/month

### VPS Providers

-   AWS Lightsail (\~\$5/month)
    https://aws.amazon.com/lightsail/pricing/

-   DigitalOcean (entry-level droplets)
    https://www.digitalocean.com/pricing/droplets

Deployment approach: - Docker Compose - Automated backups - Domain +
SSL - Nightly database backup

------------------------------------------------------------------------

## 8. Administrative Delegation Model

``` mermaid
flowchart TB
  SA[Super Admin] --> GA[Governance Admin]
  SA --> TA[Team Admin]
  SA --> SAM[System Access Manager]

  GA --> DIR[Directory]
  TA --> DIR
  SAM --> DIR
```

Levels: - Super Admin (constitutional authority) - Governance Admin -
Team Admin - System Access Manager

------------------------------------------------------------------------

## 9. Risks & Trade-offs

-   GitHub SSO requires Enterprise Cloud
-   Google Drive authorisation remains Google-native
-   VPS uptime responsibility if self-hosted
-   No mandatory MFA reduces security posture (currently intentional)

------------------------------------------------------------------------

## 10. Scalability Outlook (3--5 Years)

-   45 → 150 users: fully manageable
-   Governance complexity: supported via group-based modelling
-   Dashboard layer can be built atop central roles API

------------------------------------------------------------------------

## 11. Final Recommendation

Start with:

authentik self-hosted on low-cost VPS

Reason: - Within budget - Flexible - Modern - Governance-compatible -
Strong integration surface

Reassess hosted option later if scale increases.

------------------------------------------------------------------------

End of Document
