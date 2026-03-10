# Omysha IAM Deployment Log
**Date**: 2026-03-02
**Engineer**: Claude Code (supervised by Nitin Dhawan)
**Outcome**: SUCCESS — Authentik live at https://upanel.omysha.org

---

## 1. Server Preparation — 139.84.133.1 (Vultr Test Server)

### 1.1 SSH Access Confirmed
- **Method**: Password auth via sshpass
- **User**: root
- **Credentials stored at**: `/Users/nitindhawan/coderepository/NitinServerCredentials/Vultr/139.84.133.1/.env`
- **OS**: Ubuntu 22.04.5 LTS (Jammy Jellyfish)
- **Kernel**: 5.15.0-161-generic (pending reboot for 5.15.0-171)

### 1.2 Disk Cleanup (before: 33G used / 47G, 64% full)

| Action | Space Freed |
|---|---|
| Deleted `/home/frappe/.cache/yarn` | ~3.1 GB |
| Deleted `/home/frappe/.cache/pip` | ~0.2 GB |
| Deleted `/root/.npm` | ~1.1 GB |
| Deleted `/root/.cache` | ~0.2 GB |
| Rotated + vacuumed journal (capped to 500MB) | ~3.6 GB |
| **Total freed** | **~8.2 GB** |

**After cleanup**: 25G used / 47G (56% used, 20G free)

### 1.3 Journal Size Permanently Capped
- Added `SystemMaxUse=500M` to `/etc/systemd/journald.conf`
- Restarted `systemd-journald`

---

## 2. Docker Installation

- **Version installed**: Docker CE 29.2.1 + Docker Compose v5.1.0
- **Method**: Official Docker apt repo for Ubuntu 22.04 (jammy)
- **Status**: Running, enabled on boot

---

## 3. Authentik Deployment

### 3.1 Files Created on Server

| Path | Purpose |
|---|---|
| `/opt/omysha-iam/docker-compose.yml` | Main compose file |
| `/opt/omysha-iam/.env` | Secrets (PG_PASS, SECRET_KEY, cookie domain) |

### 3.2 Docker Compose Stack

| Container | Image | Port |
|---|---|---|
| `omysha-iam-db` | postgres:16-alpine | Internal only (5432) |
| `omysha-iam-redis` | redis:7-alpine | Internal only (6379) |
| `omysha-iam-server` | ghcr.io/goauthentik/server:2024.12.3 | `127.0.0.1:9010→9000` |
| `omysha-iam-worker` | ghcr.io/goauthentik/server:2024.12.3 | Internal only |

> Port 9010 used (not 9000) because port 9000 was already occupied by an existing Node app on the server.

### 3.3 Secrets Generated (server-side, openssl rand)
- `PG_PASS`: 48-char hex, stored in `/opt/omysha-iam/.env`
- `AUTHENTIK_SECRET_KEY`: 64-char hex, stored in `/opt/omysha-iam/.env`

### 3.4 All containers healthy
```
omysha-iam-db      Up (healthy)
omysha-iam-redis   Up (healthy)
omysha-iam-server  Up (healthy) — 127.0.0.1:9010->9000/tcp
omysha-iam-worker  Up (health: starting → healthy)
```

---

## 4. Nginx & TLS

### 4.1 Nginx Config
- **File**: `/etc/nginx/sites-available/omysha-iam`
- **Symlinked**: `/etc/nginx/sites-enabled/omysha-iam`
- **Proxies**: `upanel.omysha.org` → `127.0.0.1:9010`
- **Nginx test**: PASSED

### 4.2 SSL Certificate (Let's Encrypt)
- **Domain**: `upanel.omysha.org`
- **Certificate path**: `/etc/letsencrypt/live/upanel.omysha.org/fullchain.pem`
- **Key path**: `/etc/letsencrypt/live/upanel.omysha.org/privkey.pem`
- **Expiry**: 2026-05-31
- **Auto-renewal**: Enabled (certbot systemd timer)
- **HTTP → HTTPS redirect**: Configured by certbot

---

## 5. Validation

| Check | Result |
|---|---|
| `GET https://upanel.omysha.org/if/flow/initial-setup/` | **HTTP 200** |
| Authentik serving assets (JS, CSS, images) | Confirmed in logs |
| Django migrations completed | Confirmed in logs |
| TLS cert valid | Confirmed (Let's Encrypt) |

---

## 6. Next Steps Required (Manual)

### 6.1 Complete Initial Admin Setup
Navigate to: **https://upanel.omysha.org/if/flow/initial-setup/**
- Set admin username and password
- This can only be done once — do it before the server is exposed to others

### 6.2 Configure Google OAuth Source
In Authentik Admin → Directory → Federation & Social Login → Add Google Source:
- **Client ID**: From Google Cloud Console OAuth 2.0 credentials
- **Client Secret**: From Google Cloud Console
- **Redirect URI to register in Google**: `https://upanel.omysha.org/source/oauth/callback/google/`
- Enable "Allow users to enroll" → OFF (use allowlist instead)

### 6.3 Create Authentik Groups
Create the following groups in Admin → Directory → Groups:
```
internal:sankle
external:advisor
external:collaborator
team:Growth
team:MarketingPR
team:CommunityBuilding
team:TechProducts
team:Enablers
team:ResearchAnalysisBureau
team:ContentResearch
council:Governance
council:Management
council:Operational
sys:secretariat:admin
sys:secretariat:member
sys:frappe:admin
sys:frappe:user
```

### 6.4 Create OIDC Provider for Secretariat App
Admin → Applications → Providers → Create OIDC Provider:
- Name: `secretariat-oidc`
- Enable `groups` scope mapping
- Note the Client ID and Secret for use in the Secretariat app

### 6.5 Server Reboot (Recommended)
The kernel update (5.15.0-171) is pending. Reboot when convenient:
```bash
reboot
```
Containers will restart automatically (`restart: unless-stopped`).

---

## 7. Files Created Locally

| File | Location |
|---|---|
| PRD | `/Users/nitindhawan/coderepository/directory/omysha_iam_prd.md` |
| This deployment log | `/Users/nitindhawan/coderepository/directory/omysha_iam_deployment_log.md` |

---

## 8. Port Map — Server 139.84.133.1

| Port | Service | Notes |
|---|---|---|
| 22 | SSH | — |
| 80 / 443 | Nginx | Serves multiple vhosts |
| 9000 | Node (ytz app) | Pre-existing |
| 9002 | Next.js (ytz app) | Pre-existing |
| 9010 | Authentik (internal) | Docker, localhost only |
| 8000 / 8001 | Gunicorn / Python | Pre-existing ytz apps |
| 3306 | MariaDB | localhost only |
| 6379 | Redis | localhost only |
