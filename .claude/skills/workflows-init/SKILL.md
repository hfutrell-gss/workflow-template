---
name: workflows-init
description: >-
  Initialize (or verify) this machine for the workflows monorepo: ensure yq, Obsidian,
  and codegraph are installed, then record the init version in init.lock at the repo
  root. Use when the root AGENTS.md init check fails (init.lock missing or stale), when
  asked to run /workflows-init, or when setting up a fresh machine.
---

# workflows-init

The constitution's first mandate: `init.lock` (repo root, per-machine, gitignored) must
match `.claude/skills/workflows-init/VERSION`. This skill makes that true.

## Run
```sh
.claude/skills/workflows-init/init.sh --check   # verify only (what the mandate requires)
.claude/skills/workflows-init/init.sh           # install anything missing + write init.lock
```
Run from the repo root (or use the absolute path). The script is idempotent.

## What it ensures
- **yq** (mikefarah v4) — required by `bin/wf` and stewardship's `sync.sh`. Installs from
  GitHub releases into `~/.local/bin` if missing.
- **Obsidian** — the vault lens over this repo. Installs the AppImage into
  `~/.local/opt/obsidian` with the WSLg `--disable-gpu` wrapper at `~/.local/bin/obsidian`.
- **codegraph** — defaults to the official install method from
  https://github.com/colbymchenry/codegraph's own README (its `install.sh`, user-scoped,
  no sudo, symlinks into `~/.local/bin`). Several unrelated public packages share the
  bare name `codegraph`; this default is scoped to that repo specifically. Override with
  `CODEGRAPH_INSTALL="<command>" .claude/skills/workflows-init/init.sh` if a different
  install method is ever needed.

## Versioning
`VERSION` is bumped when the init procedure changes (new tool, changed install). Bumping
it invalidates every machine's `init.lock`, so each re-runs init on next session. After
changing this skill or its script, bump `VERSION` in the same commit.
