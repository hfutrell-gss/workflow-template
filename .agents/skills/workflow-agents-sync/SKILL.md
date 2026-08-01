---
name: workflow-agents-sync
description: >-
  Enforce the canonical file-format invariant: AGENTS.md (and .agents/ rules) are the
  canonical sources; every CLAUDE.md is at most a header bridge importing @AGENTS.md
  (root also imports @AGENTS.CORE.md and @VOICE.md). Also enforces the proxy rule for
  skills —
  .claude/skills/<name>/SKILL.md must be a stub pointing at its canonical
  .agents/skills/<name>/SKILL.md. Scans this workflow's root and every standing bind
  from binds.yaml. Use when asked to run /workflow-agents-sync, after adding a standing
  bind, when a CLAUDE.md has accumulated content, or as part of routine drift-watch.
---

# workflow-agents-sync

## Run
```sh
.agents/skills/workflow-agents-sync/agents-sync.sh          # --check: report drift
.agents/skills/workflow-agents-sync/agents-sync.sh --fix    # create missing bridges + stubs
```

## The invariant
- `AGENTS.md` is the canonical law of any directory that has one; `.agents/` dirs hold
  canonical shared rules.
- At this repo's root specifically, `AGENTS.CORE.md` (the managed constitution) is
  canonical too, alongside `AGENTS.md` (this workflow's own doctrine).
- `CLAUDE.md` is a **header at most**: the managed comment + import(s), ≤8 lines, no
  content of its own. At root: `@AGENTS.CORE.md`, `@VOICE.md`, then `@AGENTS.md`.
  Everywhere else: `@AGENTS.md` alone.
- **The proxy rule for skills** (AGENTS.CORE.md): `.claude` is a proxy for `.agents`.
  Every `.claude/skills/<name>/SKILL.md` must be a thin stub — discovery frontmatter
  (verbatim from the canonical file) plus a short pointer body (≤6 non-blank lines,
  naming `.agents/skills/<name>/SKILL.md`) — and nothing executable may sit under
  `.claude/skills/**`. The canonical body and any scripts live at
  `.agents/skills/<name>/SKILL.md` (+ scripts).

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
- `MISSING ... SKILL.md stub missing` — run with `--fix` (duplicates the canonical
  file's frontmatter and writes the pointer body).
- `DRIFT ... has no canonical counterpart` — either the `.agents/skills/<name>/`
  directory was deleted/never created (restore it — never hand-author a canonical body
  from scratch outside the template) or the stub is stale (the skill was retired —
  remove the stub too).
- `DRIFT ... non-stub file under .claude/skills` — a script or other file landed on the
  proxy side. Move it into the matching `.agents/skills/<name>/` directory (`git mv` to
  keep history), fix any path references, then re-run.
- `DRIFT ... body is N non-blank lines` or `does not point at its canonical` — someone
  hand-authored doctrine into the stub, or the pointer got corrupted. Move any real
  content into the canonical `.agents/skills/<name>/SKILL.md`, replace the stub with a
  fresh pointer body, then re-run to confirm.
- `WARN cannot scan standing binds` — yq or `binds.yaml` is unavailable; run
  `/workflow-init`.

## Scope
1. This repo's own root (`AGENTS.CORE.md` + `VOICE.md` + `AGENTS.md` + the three-import
   `CLAUDE.md`, plus every `.claude/skills/*/SKILL.md` stub found here).
2. Every standing bind declared in `binds.yaml` that is present on disk under `base`
   (absent repos are `/workflow-manage`'s `sync-binds.sh` concern, not format drift).
   An empty or example-only `binds.yaml` (no `standing:` entries) is a clean no-op here.
   The skill-stub check runs here too, in case a standing bind is itself a
   template derivation.
