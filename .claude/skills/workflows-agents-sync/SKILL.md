---
name: workflows-agents-sync
description: >-
  Enforce the canonical file-format invariant: AGENTS.md (and .agents/ rules) are the
  canonical sources; every CLAUDE.md is at most a header bridge importing @AGENTS.md.
  Scans this monorepo and all substrate repos from the manifest. Use when asked to run
  /workflows-agents-sync, after adding a workflow or substrate repo, when a CLAUDE.md
  has accumulated content, or as part of stewardship drift-watch.
---

# workflows-agents-sync

## Run
```sh
.claude/skills/workflows-agents-sync/agents-sync.sh          # --check: report drift
.claude/skills/workflows-agents-sync/agents-sync.sh --fix    # create missing bridges
```

## The invariant
- `AGENTS.md` is the canonical law of any directory that has one; `.agents/` dirs hold
  canonical shared rules.
- `CLAUDE.md` is a **header at most**: the managed comment + `@AGENTS.md` import, ≤8
  lines, no content of its own.
- Workflow directories (root's immediate children, e.g. `stewardship/`) additionally carry
  a `.constitution.md` symlink to `../AGENTS.md` and import it as `@.constitution.md`
  *before* `@AGENTS.md`. An ancestor-relative import (`@../AGENTS.md`) does not expand in
  headless sessions; the same-directory symlink does. Don't remove or hand-edit it —
  `--fix` recreates it.

## Handling each report line
- `MISSING` — run with `--fix` (creates the standard bridge). In substrate repos the new
  file follows that repo's law for committing (read its AGENTS.md; branch/PR per its
  conventions).
- `DRIFT` (content in a CLAUDE.md) — **judgment work, not script work**: move the
  CLAUDE-only content into the sibling AGENTS.md (merge carefully — AGENTS.md is
  canonical, don't duplicate), replace the CLAUDE.md with the standard bridge, then
  re-run to confirm. Never delete content; relocate it.
- `WARN cannot scan substrate` — yq or the manifest is unavailable; run `/workflows-init`.

## Scope
1. This monorepo: root + every workflow directory.
2. Every manifest repo present on disk under `base` (absent repos are stewardship's
   sync concern, not format drift).
