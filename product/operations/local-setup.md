# Local Development Setup — Omysha SignIn

## Prerequisites

- Docker Desktop (or Docker CE + Docker Compose)
- Git

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/omyshafoundation/omysha-signin.git
cd omysha-signin

# 2. Create environment file
cp .env.example .env

# 3. Generate secrets
# Edit .env and replace placeholders:
#   OMYSHA_SIGNIN_DB_PASSWORD — generate with: openssl rand -hex 24
#   OMYSHA_SIGNIN_SECRET_KEY  — generate with: openssl rand -hex 32

# 4. Start the stack
docker compose up -d

# 5. Verify all containers are healthy
docker ps --format "table {{.Names}}\t{{.Status}}"

# Expected output:
#   omysha-signin-server   Up (healthy)
#   omysha-signin-worker   Up (healthy)
#   omysha-signin-db       Up (healthy)
#   omysha-signin-redis    Up (healthy)
```

## First-Time Admin Setup

Navigate to: **http://localhost:3008/if/flow/initial-setup/**

- Set admin username and password
- This can only be done once

## Port Allocations

Per UPDSS Docker Guide (series x008):

| Service | External Port | Internal Port |
|---------|--------------|---------------|
| Authentik HTTP | 3008 | 9000 |
| Authentik HTTPS | 3448 | 9443 |
| PostgreSQL | 9008 | 5432 |
| Redis | 9018 | 6379 |

## Key URLs (Local)

| URL | Purpose |
|-----|---------|
| http://localhost:3008/if/admin/ | Admin dashboard |
| http://localhost:3008/if/user/ | User-facing login |
| http://localhost:3008/if/flow/initial-setup/ | First-time setup (once only) |

## Stopping / Starting

```bash
# Stop
docker compose down

# Stop and remove volumes (DESTROYS DATA)
docker compose down -v

# View logs
docker compose logs -f server
docker compose logs -f worker
```

## Troubleshooting

### Containers not starting
Check ports are free: `lsof -i :3008 -i :9008 -i :9018`

### Database connection errors
Wait for the `db` healthcheck to pass before `server` starts. Check with `docker compose ps`.

### Worker not healthy
The worker takes longer to start. Check logs: `docker compose logs worker`
