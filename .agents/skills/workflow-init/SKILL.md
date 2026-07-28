---
name: workflow-init
description: >-
  Initialize (or verify) this machine for this workflow repo: ensure yq, Obsidian, and
  codegraph are installed, then record the init version in init.lock at the repo root.
  Use when the root AGENTS.CORE.md init check fails (init.lock missing or stale), when
  asked to run /workflow-init, or when setting up a fresh machine.
---

# workflow-init

The constitution's first mandate: `init.lock` (repo root, per-machine, gitignored) must
match `.agents/skills/workflow-init/VERSION`. This skill makes that true.

## Run
```sh
.agents/skills/workflow-init/init.sh --check   # verify only (what the mandate requires)
.agents/skills/workflow-init/init.sh           # install anything missing + write init.lock
```
Run from the repo root (or use the absolute path). The script is idempotent.

**Prerequisite:** Linux x86_64 (including WSL2) only — `init.sh` exits early with a clear
message on any other platform (macOS/arm64, native Windows, etc.).

## What it ensures
- **git** — must resolve to a native Linux binary, not a Windows one (e.g.
  `/mnt/c/.../Git/bin/git.exe` via a WSL PATH/alias trap). `AGENTS.CORE.md` mandates
  native git (`/usr/bin/git` explicitly) for every git operation in this repo and its
  derivations. If PATH resolves to Windows git but a native `/usr/bin/git` exists, this
  is a human-fixable shell misconfiguration — init.sh fails loudly with remediation
  instead of trying to "install" anything (an explicit `GIT_BIN=/path/to/git` escape
  hatch is honored). If `core.symlinks` is merely `false` with a native git otherwise
  fine, init.sh fixes it directly.
- **yq** (mikefarah v4) — required by this skills package (`workflow-agents-sync`,
  `workflow-template-sync`, `workflow-manage`, `workflow-bind` all read/write YAML).
  Installs from GitHub releases into `~/.local/bin` if missing.
- **Obsidian** — the vault lens over this repo's `journal/` and `playbooks/`. Installs
  the AppImage into `~/.local/opt/obsidian` with the WSLg `--disable-gpu` wrapper at
  `~/.local/bin/obsidian`.
- **codegraph** — defaults to the official install method from
  https://github.com/colbymchenry/codegraph's own README (its `install.sh`, user-scoped,
  no sudo, symlinks into `~/.local/bin`), pinned to vetted v1.5.0 (both the installer
  source and the `CODEGRAPH_VERSION` release it fetches). Several unrelated public
  packages share the bare name `codegraph`; this default is scoped to that repo
  specifically. Override with `CODEGRAPH_INSTALL="<command>" .agents/skills/workflow-init/init.sh`
  if a different install method is ever needed.

## Versioning
`VERSION` is bumped when the init procedure changes (new tool, changed install). Bumping
it invalidates every machine's `init.lock`, so each re-runs init on next session. After
changing this skill or its script, bump `VERSION` in the same commit.

`workflow-init` itself is part of the managed skills package (see `template-manifest.yaml`)
— a derivation's copy is kept current by `workflow-template-sync update` unless pinned.
