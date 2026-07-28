---
name: workflow-agents-sync
description: >-
  Enforce the canonical file-format invariant: AGENTS.md (and .agents/ rules) are the
  canonical sources; every CLAUDE.md is at most a header bridge importing @AGENTS.md
  (root also imports @AGENTS.CORE.md). Scans this workflow's root and every standing
  bind from binds.yaml. Use when asked to run /workflow-agents-sync, after adding a
  standing bind, when a CLAUDE.md has accumulated content, or as part of routine
  drift-watch.
---

# workflow-agents-sync

## Run
```sh
.claude/skills/workflow-agents-sync/agents-sync.sh          # --check: report drift
.claude/skills/workflow-agents-sync/agents-sync.sh --fix    # create missing bridges
```

## The invariant
- `AGENTS.md` is the canonical law of any directory that has one; `.agents/` dirs hold
  canonical shared rules.
- At this repo's root specifically, `AGENTS.CORE.md` (the managed constitution) is
  canonical too, alongside `AGENTS.md` (this workflow's own doctrine).
- `CLAUDE.md` is a **header at most**: the managed comment + import(s), ≤8 lines, no
  content of its own. At root: `@AGENTS.CORE.md` then `@AGENTS.md`. Everywhere else:
  `@AGENTS.md` alone.

## Handling each report line
- `MISSING ... AGENTS.CORE.md not found at repo root` — the template link is broken
  (deleted or never derived). Run `/workflow-template-sync --check`; if this is a
  genuine derivation, re-derive or restore the file from upstream — never hand-author it.
- `MISSING` (CLAUDE.md bridge) — run with `--fix` (creates the standard bridge). In a
  standing-bind repo the new file follows that repo's own law for committing (read its
  `AGENTS.md`; branch/PR per its conventions).
- `DRIFT` (content in a CLAUDE.md) — **judgment work, not script work**: move the
  CLAUDE-only content into the sibling AGENTS.md (merge carefully — AGENTS.md is
  canonical, don't duplicate), replace the CLAUDE.md with the standard bridge, then
  re-run to confirm. Never delete content; relocate it.
- `WARN cannot scan standing binds` — yq or `binds.yaml` is unavailable; run
  `/workflow-init`.

## Scope
1. This repo's own root (`AGENTS.CORE.md` + `AGENTS.md` + the two-import `CLAUDE.md`).
2. Every standing bind declared in `binds.yaml` that is present on disk under `base`
   (absent repos are `/workflow-manage`'s clone-if-absent concern, not format drift).
   An empty or example-only `binds.yaml` (no `standing:` entries) is a clean no-op here.
