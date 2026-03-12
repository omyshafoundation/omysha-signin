#!/usr/bin/env bash
# Apply Omysha branding to Authentik
#
# Usage: ./apply-branding.sh <authentik-url> <api-token>
# Example (local):  ./apply-branding.sh http://localhost:3008 $(cat ../../.env | grep AUTHENTIK_BOOTSTRAP_TOKEN | cut -d= -f2)
# Example (prod):   ./apply-branding.sh https://signin.omysha.org <token>
#
# Prerequisites:
#   - Authentik server must be running
#   - branding/omysha-logo.png must be mounted at /media/custom/omysha-logo.png in the container
#     (docker-compose.yml mounts ./product/code/branding → /media/custom:ro)

set -euo pipefail

AUTHENTIK_URL="${1:?Usage: $0 <authentik-url> <api-token>}"
API_TOKEN="${2:?Usage: $0 <authentik-url> <api-token>}"

echo "Applying Omysha branding to ${AUTHENTIK_URL}..."

# Get the default brand UUID
BRAND_UUID=$(curl -sf "${AUTHENTIK_URL}/api/v3/core/brands/" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['results'][0]['brand_uuid'])")

echo "Found brand: ${BRAND_UUID}"

# Update branding
curl -sf -X PATCH "${AUTHENTIK_URL}/api/v3/core/brands/${BRAND_UUID}/" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "branding_title": "Omysha SignIn",
    "branding_logo": "/media/custom/omysha-logo.png",
    "branding_favicon": "/media/custom/omysha-logo.png"
  }' | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"  Title:   {d['branding_title']}\")
print(f\"  Logo:    {d['branding_logo']}\")
print(f\"  Favicon: {d['branding_favicon']}\")
"

echo "Branding applied successfully."
