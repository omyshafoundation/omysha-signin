---
doc_id: VAULT-TMPL-README
title: Vault Templates — Index
sequence: 00
version: 4.1.0
status: active
created: 2026-03-04
created_by: Nitin Dhawan (gtalk.nitin@gmail.com)
---

# Vault Templates — Index

All vault artifacts must be created from these templates.
Every template includes a metadata header, structured content, and changelog footer.

---

## Templates (10 files)

| Template | Use for | Written by |
|----------|---------|------------|
| [epic-template.yaml](epic-template.yaml) | New EPICs in `vault/epics/EPIC-NNN/` | Human (Pre-G1) |
| [feature-template.yaml](feature-template.yaml) | New Features in `vault/epics/EPIC-NNN/features/FEAT-NNN/` | Human (Pre-G1) |
| [story-template.yaml](story-template.yaml) | New Stories in `vault/epics/.../stories/STORY-NNN/` | Human (Pre-G1) |
| [cursor-template.yaml](cursor-template.yaml) | `cursor.yaml` at story and release level | Agent + Orchestrator |
| [progress-template.md](progress-template.md) | `progress.md` session log per story | Agent (append-only) |
| [release-scope-template.yaml](release-scope-template.yaml) | `vault/releases/vX.Y/release-scope.yaml` | Human (Pre-G1) |
| [gate-template.yaml](gate-template.yaml) | `vault/releases/vX.Y/GN-review.yaml` — release-level gate review + decision. Includes standard Definition of Done checklist items (documentation, UI review). | Reviewer + Human |
| [governance-log-template.yaml](governance-log-template.yaml) | `vault/releases/vX.Y/governance-log.yaml` | Human (G3 + retrospective) |
| [job-request-template.yaml](job-request-template.yaml) | Job requests in `vault/queue/pending/` — execution queue schema | Submitter (human or CLI) |
| [adr-template.md](adr-template.md) | Architecture Decision Records in `vault/ADRs/` | Human |

---

## Role Brief (1 file)

| File | Use for |
|------|---------|
| [role-briefs/coding-agent-brief.md](role-briefs/coding-agent-brief.md) | Agent prompt template — covers implementation, testing, and documentation |

---

## Coding Standards (1 file)

| File | Use for |
|------|---------|
| [role-briefs/coding-standards.md](role-briefs/coding-standards.md) | Shared coding standards included in agent context |

---

## Metadata Fields

Every vault artifact carries these fields in its header comment or front matter:

| Field | Description | Required |
|-------|-------------|----------|
| `doc_id` | Unique identifier — e.g. `VAULT-EPIC-001`, `VAULT-ADR-003` | Yes |
| `title` | Human-readable title | Yes |
| `version` | Semantic version — increment on every substantive change | Yes |
| `status` | Lifecycle status (see per-template values) | Yes |
| `created` | ISO date of first creation | Yes |
| `created_by` | Full name + git email of creator | Yes |

---

## Write Ownership

| Artifact | Written by | Never written by |
|----------|------------|------------------|
| EPIC, Feature, Story (spec fields) | Human at Pre-G1 | Agents |
| story cursor.yaml | Assigned agent + orchestrator | Other agents |
| release cursor.yaml | Orchestrator | Any agent |
| progress.md | Assigned agent (append only) | Any other agent |
| GN-review.yaml | Reviewer + Human | Agents (unreviewed) |
| governance-log.yaml | Human at G3 + retrospective | Agents |
| ADR.md | Human | Agents |
| job-request YAML | Submitter (human or CLI) | — |

---

## Changelog Convention

When updating any vault artifact:
1. Increment version (patch for minor edits, minor for significant changes)
2. Add a changelog row: `version | date | author (git email) | what changed`
3. Commit with standard UPDSS format: `[VAULT][STORY-NNN] Brief description`

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 4.1.0 | 2026-03-08 | Daemon Engineer (STORY-011-01-01) | Added job-request-template.yaml for git-based execution queue; updated write ownership table |
| 4.0.0 | 2026-03-06 | Nitin Dhawan (gtalk.nitin@gmail.com) | v4.0.0: removed 5 templates (g-review-packet, g-decision, session, decisions, release); added gate-template.yaml; simplified story, cursor, progress templates; merged QA/docs briefs into coding-agent-brief; updated all versions to 4.0.0 |
| 2.0.0 | 2026-03-05 | Nitin Dhawan (gtalk.nitin@gmail.com) | Added cursor, progress, release-scope, governance-log, g-review-packet, g-decision templates; write ownership table |
| 1.0.0 | 2026-03-04 | Nitin Dhawan (gtalk.nitin@gmail.com) | Initial templates: EPIC, Feature, Story, ADR, Release |
