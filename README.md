# workflow-template

The core that every **workflow repo** derives itself from and stays linked to for the
life of its project.

A workflow repo captures the techniques, tactics, procedures, and doctrine for one area
of work (stewardship, schema management, incident response, …). Code repos are
**substrate** — things a workflow operates *on*, not *in*. This template repo provides
what every derivation gets on day one: managed law (`AGENTS.CORE.md`), a package of
skills, and a live link back upstream so improvements to the core can flow forward.

## The covenant

**The template facilitates, never constrains.** A derivation owns everything outside a
small managed set (`AGENTS.CORE.md`, `VOICE.md`, `CLAUDE.md`, `template-manifest.yaml`,
and the `workflow-*` skills — see `template-manifest.yaml` for the exact list): its own
doctrine, its `binds.yaml`, its `playbooks/`, its `journal/`, anything it adds later.
It can pin its core (`pinned: true` in `.template.lock`) to freeze it forever, or eject
from the template relationship entirely (delete `.template.lock`) — either way, it's
supported for the full lifetime of the project it belongs to.

## Deriving a new workflow

```sh
cp -r workflow-template my-new-workflow   # or: git clone workflow-template my-new-workflow
cd my-new-workflow
.agents/skills/workflow-template-sync/template-sync.sh derive
```
`derive` asks nothing: it clears template-only example content, drops the root
`VERSION` file (that describes the *template's* version, not a derivation's), and
writes `.template.lock` recording the template version and upstream path. Then write
this workflow's actual doctrine into `AGENTS.md` (the skeleton is left untouched on
purpose) and start filling in `binds.yaml`, `playbooks/`, and `journal/`.

To pull forward later improvements to the managed set:
```sh
.agents/skills/workflow-template-sync/template-sync.sh update    # or --check to preview
```

## What's in the box

| Path | What it is |
|------|------------|
| `AGENTS.CORE.md` | The constitution — TEMPLATE-MANAGED, never hand-edited in a derivation |
| `VOICE.md` | The reduced-voice contract for agent output — TEMPLATE-MANAGED |
| `AGENTS.md` | This workflow's own doctrine — entirely yours, a skeleton until you write it |
| `CLAUDE.md` | Bridge importing `@AGENTS.CORE.md` then `@AGENTS.md` |
| `binds.yaml` | Standing binds: repos related to this workflow (kind + why); `base` (default `./workspace`) says where they live on disk |
| `workspace/` | This workflow's own substrate workspace — gitignored, per-machine; where standing binds get cloned and cross-repo work happens. Never committed, never the user's personal checkouts. |
| `template-manifest.yaml` | The exact managed-set path list `workflow-template-sync` owns |
| `VERSION` | This template's own version (absent in a derivation — see `.template.lock` there instead) |
| `playbooks/` | Step-by-step procedures for this workflow's area of work |
| `journal/` | One dated file per run/decision — never a single growing file |
| `.workflow/` | Orchestration session state (`<session-slug>/tasklist.md` + `roster.md`) — **committed**, so a run resumes after a cold tick or on another machine. See `/workflow-orchestrate` |
| `.agents/skills/` | Canonical skill bodies + scripts (`workflow-*` machinery, `craft-*` engineering doctrine) |
| `.agents/craft/` | Optional, derivation-owned overlays (`<skill>.local.md`) that override `craft-*` defaults — unmanaged, never touched by `update` |
| `.agents/orchestrate/` | Optional, derivation-owned overlays for `/workflow-orchestrate`: `roster.local.yaml` (tier→lane preference, role→tier overrides) and `orchestrate.local.md` — unmanaged |
| `.agents/init/tools.local.d/` | Optional, derivation-owned tool definitions (`<tool>.sh`) that `/workflow-init` sources, so a workflow's own tooling gets the full decide/install/`--check` mechanism — unmanaged. See `example-tool.sh.example` |
| `.mcp.json` | Optional, derivation-owned MCP server registrations — unmanaged. Point `command` at a `${HOME}/.local/bin/<name>` wrapper so the committed file holds no machine-specific path |
| `.claude/skills/` | Proxy stubs only — discovery frontmatter + a pointer to the canonical file in `.agents/skills/`. Nothing executable lives here. |

## Skills package

**`.claude` is a proxy for `.agents`**: each skill's full doctrine and scripts live at
`.agents/skills/<name>/SKILL.md` (+ scripts); `.claude/skills/<name>/SKILL.md` is a
thin stub Claude Code needs for discovery.

| Skill | Purpose |
|-------|---------|
| `/workflow-init` | Install/verify required tooling (git, yq); record per-machine decisions on recommended, opt-in tools (Obsidian, codegraph, opencodex); writes per-machine `init.lock` |
| `/workflow-agents-sync` | Enforce the AGENTS-canonical format here and across standing-bind repos present on disk |
| `/workflow-template-sync` | The upstream link: `derive` a new workflow, `update` a derivation's managed set, `--check` report drift |
| `/workflow-manage` | Administer this workflow: add/remove/edit standing binds, assemble/refresh the substrate (`sync-binds.sh`) |
| `/workflow-bind` | Bind a session: attach default standing binds (and anything else asked for) via `/add-dir` |
| `/workflow-gateway` | Manage the local opencodex model gateway (start/stop/status) and print the strictly opt-in, per-session `ANTHROPIC_BASE_URL` override |
| `/workflow-orchestrate` | Task-based orchestration: directive → committed task list (`.workflow/<session-slug>/tasklist.md`) → dispatch per model **tier** (`flagship` · `workhorse` · `fleet`, resolved from a lane roster, never a hardcoded model name) → loop until the list is exhausted |
| `/craft-tdd` | Test-first protocol: failing test before production code, integration focus, seams at every EUD, never mock business logic |
| `/craft-code-quality` | Module size budgets, mandatory lint/static analysis, ports and adapters, pragmatic SOLID/DDD, no implicit fallbacks, required observability — plus a ratcheting path for repos that start nowhere near any of it |

Two prefixes are reserved for the template: **`workflow-*`** (machinery that operates on
template shapes) and **`craft-*`** (engineering doctrine for work done *on* substrate).
Name derivation-local skills outside both, or a future `update` may clobber them.

### Craft overlays

`craft-*` skills ship opinion — size budgets, architecture defaults, a test protocol —
into derivations whose area of work the template cannot know. Each one declares a
precedence ladder: **a bound repo's own law wins inside its boundaries → then this
workflow's overlay → then the skill's defaults.** To change a default, write
`.agents/craft/<skill-name>.local.md` (e.g. `.agents/craft/code-quality.local.md`); it is
unmanaged, so `update` never touches it, and where it conflicts with the skill it wins.
No pinning, no ejecting, no drift.

The same mechanism serves `/workflow-orchestrate` outside `.agents/craft/`: put tier→lane
preference and role→tier overrides in `.agents/orchestrate/roster.local.yaml`, further
doctrine overrides in `.agents/orchestrate/orchestrate.local.md`. Both unmanaged, both win
over the skill.

### Required vs recommended tools

`/workflow-init` ensures two tiers: **required** tools (`git`, `yq`) that every
procedure here assumes, and **recommended** tools (Obsidian, codegraph, opencodex) that
are opt-in per machine — nothing recommended is installed until you explicitly decide so
(`init.sh decide <tool> install`). An undecided or skipped recommended tool is never a
failure, only an informational note pointing at how to opt in.

A derivation adds **its own** tools by dropping `.agents/init/tools.local.d/<tool>.sh`
(`check_`/`install_`/optional `unsupported_reason_` + `register_tool`), which `init.sh`
sources — so the workflow's tooling inherits the whole mechanism without forking the
script. Overlay tools are always recommended-tier, and a platform-limited one declaring
`unsupported_reason_<tool>()` degrades to a note rather than drift on machines that can't
host it. Never fork `init.sh` or hand-roll a parallel installer: the first is overwritten
by `update`, the second is the same violation with extra steps.

## Standing binds vs session binds

- **Standing binds** (`binds.yaml`) — repos related to this workflow, declared with the
  relationship (`kind` + `why`). A registry; doesn't attach anything by itself.
- **Session binds** — repos actually attached to the *current* session, via `/add-dir`
  once running, or `claude --add-dir <path>` (repeatable) at launch. `/workflow-bind`
  attaches every `default: true` standing bind plus anything else asked for.

Standing binds live on disk in this workflow's own **workspace** (`workspace/` at the
repo root, gitignored, per-machine) — `binds.yaml`'s `base` (default `./workspace`)
resolves relative to the repo root unless given as an absolute or `~`-prefixed path.
`/workflow-manage`'s `sync-binds.sh` populates it. A workflow manages its own repos
there; it never resolves standing binds into checkouts it doesn't own, including the
user's personal working copies.

## Prerequisite

Linux x86_64 (including WSL2) — `/workflow-init` supports no other platform yet.

## Git discipline

Use `/usr/bin/git` explicitly for every git operation in this repo — a bare `git` can
resolve to a Windows binary under WSL if a shell alias shadows it. See
`AGENTS.CORE.md` for the full rationale and `/workflow-init --check`'s detection.
