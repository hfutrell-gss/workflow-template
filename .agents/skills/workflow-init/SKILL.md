---
name: workflow-init
description: >-
  Initialize (or verify) this machine for this workflow repo: ensure required tools
  (git, yq) and record per-machine decisions about recommended tools (Obsidian,
  codegraph), then write init.lock at the repo root. Also the home of MCP
  server registration doctrine (.mcp.json, tools.local.d wrapper rules). Use when the
  root AGENTS.CORE.md init check fails (init.lock missing or stale), when asked to run
  /workflow-init, when opting a recommended tool in or out, when setting up a fresh
  machine, or when registering/wiring an MCP server.
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

## Tool tiers

- **REQUIRED** — `git`, `yq`. Every procedure in this repo assumes these. Missing on a
  plain run → installed automatically. Missing on `--check` → hard failure.
- **RECOMMENDED** — `obsidian`, `codegraph`. Useful, but opt-in **per
  machine**, one tool at a time, via a recorded decision (below). A recommended tool
  with no decision, or a recorded `skip`, is **never** installed automatically and
  **never** fails anything — a plain run and `--check` both just print an informational
  `NOTE` explaining how to opt in. A recommended tool decided `install` but not actually
  present on this machine **is** a failure: the decision was made and this machine isn't
  honoring it (both a plain run's own install attempt and `--check` treat this as an
  error, not a note).

## Derivation-owned tools (`.agents/init/tools.local.d/`)

A derivation needs tools the template cannot know about — its area of work decides them.
The categorical rule says tool installation is a *template shape* (tiers, per-machine
decisions, `init.lock`), so a derivation must not fork `init.sh` (an `update` overwrites
it) and must not hand-roll a parallel installer (the same violation with extra steps).

Instead it drops `.agents/init/tools.local.d/<tool>.sh`, unmanaged and never touched by
`update` — the same overlay bargain as `.agents/code-craft/<skill>.local.md` and
`.agents/orchestrate/roster.local.yaml`. `init.sh` sources every `*.sh` there at startup.
The contract, in full:

| Function | | Contract |
| --- | --- | --- |
| `check_<tool>()` | define — required | print a version or `present` and return 0 when installed; non-zero/empty when not |
| `install_<tool>()` | define — required | install it; non-zero on failure |
| `unsupported_reason_<tool>()` | define — optional | print why *this machine* can't host it and return 0; return 1 when it can |
| `register_tool <tool>` | **call** — required | `init.sh` defines it; the overlay calls it once, at the end, to append the tool to the RECOMMENDED tier. Redefining it breaks registration |

Overlay tools are **always RECOMMENDED** — opt-in per machine, never automatic. A
derivation cannot make its own tool mandatory: `--check` failing on a tool the template
never heard of would make the constitution's init mandate unsatisfiable for anyone
lacking it. A registered tool missing its `check_`/`install_` function is a hard error at
startup, so a half-written overlay fails loudly instead of mysteriously mid-install.

### Platform-limited tools

Some tools are viable only on a subset of the platforms that clear the Linux-x86_64 gate
(needing WSL/Windows interop, say). Because `init.lock` decisions are shared across
machines, one `decide <tool> install` would otherwise make `--check` fail *forever* on
every machine that cannot run it. So a tool decided `install` on a machine that cannot
host it is **not drift**: the decision is honored as far as the machine allows, and the
shortfall prints as a `NOTE` in both a plain run and `--check`. Opt in by defining
`unsupported_reason_<tool>()`. Surface, don't suppress — but don't manufacture failures
either.

## Recording a decision
```sh
.agents/skills/workflow-init/init.sh decide <tool> install   # or: skip
```
`<tool>` must be one of the RECOMMENDED tools — `obsidian`, `codegraph`, plus
anything a derivation registered in `.agents/init/tools.local.d/` (see above). Required
tools aren't decided, they're mandatory. This only records the decision into
`init.lock`'s `decisions:` section (creating the file if it doesn't exist yet); it does
not itself install or remove anything. Follow it with a plain `init.sh` run to apply.

Typical opt-in flow for a recommended tool:
```sh
.agents/skills/workflow-init/init.sh decide codegraph install
.agents/skills/workflow-init/init.sh
```

## What it ensures

**Required:**
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
  Installs from GitHub releases into `~/.local/bin` if missing. `init.lock` itself is
  parsed with plain grep/awk (never `yq`) precisely because init.sh may still be
  bootstrapping yq when it reads its own lock.

**Recommended (decision-gated):**
- **Obsidian** — the vault lens over this repo's `journal/` and doctrine. Installs
  the AppImage into `~/.local/opt/obsidian` with the WSLg `--disable-gpu` wrapper at
  `~/.local/bin/obsidian`.
- **codegraph** — defaults to the official install method from
  https://github.com/colbymchenry/codegraph's own README (its `install.sh`, user-scoped,
  no sudo, symlinks into `~/.local/bin`), pinned to vetted v1.5.0 (both the installer
  source and the `CODEGRAPH_VERSION` release it fetches). Several unrelated public
  packages share the bare name `codegraph`; this default is scoped to that repo
  specifically. Override with `CODEGRAPH_INSTALL="<command>" .agents/skills/workflow-init/init.sh`
  if a different install method is ever needed.

## MCP servers

A workflow that needs an MCP server registers it in a committed, project-scoped
`.mcp.json` at its root — derivation-owned and unmanaged, like `binds.yaml`. Two rules
keep a committed registration shareable across machines:

- **No machine-specific paths in `.mcp.json`.** Point `command` at a fixed
  `${HOME}/.local/bin/<name>` wrapper that the tool's `tools.local.d` installer
  generates (see "Derivation-owned tools" above), and let the wrapper hold every
  variable part — install location, interop paths, and any working directory the
  server requires. A server launched with a working directory it can't use may fail
  *silently*, never answering `initialize`, so the wrapper is the right place to pin
  one.
- **A skipped tool is not a broken config.** A server whose backing tool was never
  opted into (see "Recording a decision" above) simply shows as unconnected in `/mcp`.
  That is the intended resting state on a machine with no use for it, not an error to
  chase.

## Grandfathering

An `init.lock` that exists but carries no `decisions:` section records `install` for any
recommended tool already present on that machine, annotated `grandfathered`; anything
absent starts undecided. A machine with no `init.lock` at all is never grandfathered —
everything recommended starts undecided there.

## Versioning
`VERSION` is bumped when the init procedure changes (new tool, changed install, tiering
changes). Bumping it invalidates every machine's `init.lock`, so each re-runs init on
next session. After changing this skill or its script, bump `VERSION` in the same
commit.

`workflow-init` itself is part of the managed skills package (see `template-manifest.yaml`)
— a derivation's copy is kept current by `workflow-template-sync update` unless pinned.
