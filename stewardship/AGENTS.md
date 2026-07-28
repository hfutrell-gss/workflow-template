---
tier: dev
---

# Stewardship — doctrine

Area of work: **the working environment itself.** Keeping the substrate healthy — repos
present and fresh, agent law distributed, drift surfaced. This is the workflow other
workflows assume has been done.

## Responsibilities
- **Substrate assembly** — every repo in `../manifest.yaml` present under `base`, tracking
  its manifest branch. Procedure: [playbooks/sync-substrate.md](playbooks/sync-substrate.md),
  tool: `bin/sync.sh`.
- **Manifest custody** — `../manifest.yaml` is the substrate registry (repo → url, branch,
  description). New repo in the org → add it here. Branch policy changes → update here.
- **Agent-law distribution** — every substrate repo carries `AGENTS.md` (its law, canonical)
  and a `CLAUDE.md` header-bridge so Claude honors it. Enforced by `/workflows-agents-sync`;
  the shared rules live in `<base>/.agents/`.
- **Drift watch** — repos on unexpected branches, dirty long-lived checkouts, bridges
  missing, manifest out of date with the org. Surface in `journal/`, don't silently fix.

## Conditions
- Never clobber local state: `sync.sh` fast-forwards clean checkouts only and fetch-skips
  everything else. Diverged/dirty repos are *reported*, not repaired unilaterally.
- Changes to a substrate repo's own files (e.g. adding a bridge) follow that repo's law:
  read its `AGENTS.md`, branch/PR per its conventions.

## Typical checkouts
```sh
wf stewardship                    # doctrine session: sync, audit, manifest work
wf stewardship identity gitops    # stewardship attention on specific repos
```
