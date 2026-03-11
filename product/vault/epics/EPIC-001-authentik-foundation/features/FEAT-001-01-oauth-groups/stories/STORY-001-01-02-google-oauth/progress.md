<!-- progress.md — APPEND-ONLY session log
     story_id:   STORY-001-01-02
     created:    2026-03-10
     created_by: Nitin Dhawan (gtalk.nitin@gmail.com)
-->

# Progress Log — STORY-001-01-02: Google OAuth Source Configuration

## Session 1 — 2026-03-10T22:30Z

**Model**: claude-opus-4-6
**Tasks completed**: T-1, T-2

### What was done

- T-1: Human provided Google Cloud Console OAuth credentials (Client ID + Secret)
- T-2: Created Google OAuth Source in Authentik via API:
  - Name: Google, Slug: google, Provider type: google
  - Authentication flow: default-source-authentication
  - Enrollment flow: default-source-enrollment
  - Callback URL: http://localhost:3008/source/oauth/callback/google/
  - Source confirmed enabled and visible in Authentik

### What's next

Start at T-3: Validate login flow. Human needs to add callback URI
(http://localhost:3008/source/oauth/callback/google/) to Google Cloud Console
OAuth redirect URIs. Then test Login with Google in browser.

## Session 2 — 2026-03-11T08:00Z

**Model**: claude-opus-4-6
**Tasks completed**: T-3, T-4

### What was done

- T-3: Validated full Google OAuth login flow:
  - Fixed: Google source was not linked to identification stage (`sources: []`).
    Added Google source PK to `default-authentication-identification` stage.
  - Fixed: API token had `expiring: true` and expired. Regenerated with `expiring: false`.
  - Fixed: Google source `user_path_template` was `goauthentik.io/sources/%(slug)s`
    (creates external users). Changed to `users` (creates internal users).
  - Fixed: Zoom1 user created as external — patched to `type: internal`, `path: users`.
  - Result: Login with Google button appears on login page, full flow works:
    Google auth → Authentik callback → user enrolled → session established.
  - Tested with: zoom1@omysha.org (enrolled as new user "Zoom1")
- T-4: Configuration documented in this progress entry.

### AC verification

- AC-1: Google OAuth source visible in Authentik ✓ (slug: google, enabled)
- AC-2: Login with Google button appears on login page ✓ (via identification stage sources)
- AC-3: Full login flow works end-to-end ✓ (tested with zoom1@omysha.org)

---
<!-- Add new session entries above this line. Never edit entries above. -->
