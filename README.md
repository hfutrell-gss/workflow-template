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
doctrine, its `binds.yaml`, its own procedure skills, its `journal/`, anything it adds later.
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
purpose) and start filling in `binds.yaml`, its procedure skills, and `journal/`.

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
| `CLAUDE.md` | Bridge importing `@AGENTS.CORE.md`, `@VOICE.md`, then `@AGENTS.md` |
| `binds.yaml` | Standing binds: repos related to this workflow (kind + why); `base` (default `./workspace`) says where they live on disk |
| `workspace/` | This workflow's own substrate workspace — gitignored, per-machine; where standing binds get cloned and cross-repo work happens. Never committed, never the user's personal checkouts. |
| `template-manifest.yaml` | The CORE pack's manifest — the exact path list it owns in every workflow repo |
| `packs.yaml` / `packs.lock` | The additional packs a workflow repo composes in, and what each one installed. Derivation-owned; edited through `/workflow-template-sync add`/`remove` (absent in this repo — the core is not composed into itself) |
| `VERSION` | This template's own version (absent in a derivation — see `.template.lock` there instead) |
| `journal/` | One dated file per run/decision — never a single growing file |
| `workflows/` | Workflows and their state, four levels: `<workflow>/SKILL.md` is TIMELESS (the TTPs, never pruned), `<app>/profile.md` is that application's DURABLE particulars, `<app>/tasks.md` is CARRIED work crossing sessions, `<app>/<session>/` is one SESSION, deleted after harvest. **Committed**, so a session resumes after a cold tick or on another machine. See `/workflow-orchestrate` |
| `.workflow/` | Legacy (pre-stratification) run state — `<slug>/tasklist.md`. Resolved for one version only; new runs never use it |
| `.agents/skills/` | Canonical skill bodies + scripts. The core ships `workflow-*` machinery only; `code-craft-*` engineering doctrine arrives from the optional `code-craft` pack |
| `.agents/code-craft/` | Optional, derivation-owned overlays (`<skill>.local.md`) that override `code-craft-*` defaults — unmanaged, never touched by `update` |
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
| `/workflow-check` | Every organizational constraint in one pass — tooling, file format, layout, task grammar, template drift — with stable rule IDs. Owns none of them; each skill owns the constraints for its own shapes |
| `/workflow-agents-sync` | Enforce the AGENTS-canonical format here and across standing-bind repos present on disk |
| `/workflow-template-sync` | Composition: `derive` a new workflow repo, `add`/`remove` a pack, `update` the core and every pack, `list`, `--audit` composition integrity, `--check` version drift |
| `/workflow-manage` | Administer this workflow: add/remove/edit standing binds, assemble/refresh the substrate (`sync-binds.sh`) |
| `/workflow-bind` | Bind a session: attach default standing binds (and anything else asked for) via `/add-dir` |
| `/workflow-gateway` | Manage the local opencodex model gateway (start/stop/status) and print the strictly opt-in, per-session `ANTHROPIC_BASE_URL` override |
| `/workflow-orchestrate` | Task-based orchestration: directive → committed task list (`workflows/<workflow>/<app>/<session>/tasks.md`) → dispatch per model **tier** (`flagship` · `workhorse` · `fleet`, resolved from a lane roster, never a hardcoded model name) → loop until the list is exhausted AND its durable output harvested out of the session directory |
One prefix is reserved by the core: **`workflow-*`** (machinery that operates on the
shapes). A pack owns whatever prefix it ships — `code-craft-*` for the `code-craft` pack.
Name local skills outside every installed prefix, or an `update` may clobber them;
`new-workflow` reads `.agents/skills/` and refuses a collision rather than trusting a list.

## Packs

The core defines the shapes. Everything else is a **pack**: a repo with a `pack.yaml`
declaring the exact paths it owns, installed with

```sh
.agents/skills/workflow-template-sync/template-sync.sh add <url-or-path>
```

**Composition, not more inheritance.** The core cannot know your area of work, so
anything it ships beyond the shapes is a guess — and guesses belong in things you can
decline. `craft-*` was 40% of the core by size and none of it was mechanism, so it is now
the `code-craft` pack. A workflow repo with no packs is complete, not degraded.

| Pack | What it carries |
|---|---|
| `code-craft` | `/code-craft-tdd`, `/code-craft-quality`, `/code-craft-event-naming`, `/code-craft-ubiquitous-language` — engineering doctrine for work done *on* substrate |

Three invariants, enforced rather than advised: **one owner per path** (a collision is an
error, refused before any write), **a dropped path is removed** (retiring a skill
upstream retires it everywhere), and **no inter-pack dependencies** (no resolver, no
ordering, no version solving). `--audit` re-checks all three offline as `PACK-001..003`.

### Overlay slots

A pack ships opinion into repos whose area of work it cannot know, so every one declares
a precedence ladder: **a bound repo's own law wins inside its boundaries → then this
workflow's overlay → then the pack's defaults.** To change a default, write the overlay:
`.agents/code-craft/<skill-name>.local.md` — the skill's full name, prefix included, so
`/code-craft-quality` overlays at `.agents/code-craft/code-craft-quality.local.md`. Unmanaged,
so `update` never touches it, and where it conflicts with the skill it wins. No pinning,
no ejecting, no drift.

The same mechanism serves the core's `/workflow-orchestrate` outside `.agents/code-craft/`: put tier→lane
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
