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
small managed set (`AGENTS.CORE.md`, `CLAUDE.md`, `template-manifest.yaml`, and the
`workflow-*` skills — see `template-manifest.yaml` for the exact list): its own
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
| `AGENTS.md` | This workflow's own doctrine — entirely yours, a skeleton until you write it |
| `CLAUDE.md` | Bridge importing `@AGENTS.CORE.md` then `@AGENTS.md` |
| `binds.yaml` | Standing binds: repos related to this workflow (kind + why) |
| `template-manifest.yaml` | The exact managed-set path list `workflow-template-sync` owns |
| `VERSION` | This template's own version (absent in a derivation — see `.template.lock` there instead) |
| `playbooks/` | Step-by-step procedures for this workflow's area of work |
| `journal/` | One dated file per run/decision — never a single growing file |
| `.agents/skills/` | Canonical skill bodies + scripts (the six `workflow-*` skills) |
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

### Required vs recommended tools

`/workflow-init` ensures two tiers: **required** tools (`git`, `yq`) that every
procedure here assumes, and **recommended** tools (Obsidian, codegraph, opencodex) that
are opt-in per machine — nothing recommended is installed until you explicitly decide so
(`init.sh decide <tool> install`). An undecided or skipped recommended tool is never a
failure, only an informational note pointing at how to opt in.

## Standing binds vs session binds

- **Standing binds** (`binds.yaml`) — repos related to this workflow, declared with the
  relationship (`kind` + `why`). A registry; doesn't attach anything by itself.
- **Session binds** — repos actually attached to the *current* session, via `/add-dir`
  once running, or `claude --add-dir <path>` (repeatable) at launch. `/workflow-bind`
  attaches every `default: true` standing bind plus anything else asked for.

## Prerequisite

Linux x86_64 (including WSL2) — `/workflow-init` supports no other platform yet.

## Git discipline

Use `/usr/bin/git` explicitly for every git operation in this repo — a bare `git` can
resolve to a Windows binary under WSL if a shell alias shadows it. See
`AGENTS.CORE.md` for the full rationale and `/workflow-init --check`'s detection.
