# Omysha SignIn — Centralised Identity & Access Management

Authentik-based SSO and authorisation layer for all Omysha digital systems. Managed as a UPDSS product.

## Production

- **URL**: https://signin.omysha.org
- **Server**: 139.84.133.1 (Vultr)
- **Status**: Deployed (2026-03-02)

## Local Development

### Quick Start

```bash
cp .env.example .env
# Edit .env — generate secrets with: openssl rand -hex 32
docker compose up -d
# First-time setup: http://localhost:3008/if/flow/initial-setup/
```

### Port Allocations

Per UPDSS Docker Guide (series x008):

| Service | Port | Internal |
|---------|------|----------|
| Authentik HTTP | 3008 | 9000 |
| Authentik HTTPS | 3448 | 9443 |
| PostgreSQL | 9008 | 5432 |
| Redis | 9018 | 6379 |

### Admin UI

- **Local**: http://localhost:3008/if/admin/
- **Production**: https://signin.omysha.org/if/admin/

## Project Structure

```
omysha-signin/
├── docker-compose.yml          # Authentik stack (local dev)
├── .env.example                # Environment template
├── product/
│   ├── code/                   # Authentik customisations
│   │   ├── blueprints/         # Authentik declarative config
│   │   └── custom-templates/   # Custom login page templates
│   ├── operations/             # Deployment, setup, guides
│   │   ├── deployment-log.md
│   │   └── users/
│   └── vault/                  # UPDSS vault (epics, releases, research)
│       ├── registry/           # Product profile
│       ├── epics/              # Work tracking
│       ├── releases/           # Release documentation
│       ├── research/           # IAM research artifacts
│       ├── templates/          # UPDSS templates
│       └── schemas/            # UPDSS schemas
```

## Documentation

- **IAM PRD**: [product/vault/omysha_iam_prd.md](product/vault/omysha_iam_prd.md)
- **IAM Research**: [product/vault/research/02-researched/](product/vault/research/02-researched/)
- **Deployment Log**: [product/operations/deployment-log.md](product/operations/deployment-log.md)

## UPDSS Integration

This product is managed under UPDSS methodology v4.0.0. See [product/vault/](product/vault/) for the vault structure.

- **Product ID**: `omysha-signin`
- **Registry**: [product/vault/registry/omysha-signin.yaml](product/vault/registry/omysha-signin.yaml)
